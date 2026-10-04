package com.dayround.notifications

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONArray
import org.json.JSONObject
import java.time.ZoneId

/** Registered in both the foreground engine and the notification action engine. */
class RoutineNotificationPlatformPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    ActivityAware, PluginRegistry.NewIntentListener {
    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var activityBinding: ActivityPluginBinding? = null
    private var tappedNotification: Pair<Int, Long>? = null
    private val startupNotifications = mutableMapOf<Int, Long>()

    // Android can restore an existing task, then send its notification intent.
    // Snapshot before Dart starts synchronizing/cancelling weekly notifications.
    private fun captureTap(intent: Intent?) {
        if (intent == null || intent.action != "SELECT_NOTIFICATION" ||
            intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return
        val id = intent.getIntExtra("notificationId", -1)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val postedAt = manager.activeNotifications.firstOrNull { it.id == id }?.postTime
            ?: startupNotifications.remove(id)
        tappedNotification = postedAt?.let { id to it }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        startupNotifications.clear()
        manager.activeNotifications.forEach { startupNotifications[it.id] = it.postTime }
        captureTap(binding.activity.intent)
        binding.addOnNewIntentListener(this)
    }

    override fun onNewIntent(intent: Intent): Boolean {
        captureTap(intent)
        return false
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activityBinding = null
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "routine_timer/notification_platform")
        channel.setMethodCallHandler(this)
        channels.add(channel)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        channels.remove(channel)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            when (call.method) {
                "timezone" -> result.success(ZoneId.systemDefault().id)
                "exactAlarmsAllowed" -> result.success(Build.VERSION.SDK_INT < 31 ||
                    (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).canScheduleExactAlarms())
                "notificationInfo" -> {
                    val id = call.argument<Int>("id")
                    val postedAt = tappedNotification?.takeIf { it.first == id }?.second
                        ?: manager.activeNotifications.firstOrNull { it.id == id }?.postTime
                    result.success(postedAt?.let { mapOf("postedAt" to it) })
                }
                "dismiss" -> {
                    val id = call.argument<Int>("id")!!
                    val postedAt = call.argument<Number>("postedAt")?.toLong()
                    val item = manager.activeNotifications.firstOrNull { it.id == id }
                    if (item != null && (postedAt == null || item.postTime == postedAt)) {
                        // Do not use the notification plugin's cancel(): it also cancels
                        // next week's alarm with the same ID.
                        manager.cancel(item.tag, id)
                    }
                    result.success(null)
                }
                "mutateLogs" -> {
                    val saved = mutateLogs(call)
                    result.success(saved)
                    if (saved && call.argument<String>("operation") == "snooze") {
                        channels.forEach { it.invokeMethod("logsChanged", null) }
                    }
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("notification_platform", e.message, null)
        }
    }

    // Every Android log writer uses this lock. A background snooze cannot overwrite
    // an app completion or lose another routine's record through a cached JSON list.
    private fun mutateLogs(call: MethodCall): Boolean = synchronized(logLock) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val all = JSONArray(prefs.getString(logKey, "[]"))
        val operation = call.argument<String>("operation")!!
        val incoming = call.argument<String>("log")?.let { JSONObject(it) }
        val routineId = incoming?.getString("routineId") ?: call.argument<String>("routineId")!!
        val date = incoming?.getString("dateYmd") ?: call.argument<String>("dateYmd")
        val result = JSONArray()
        for (i in 0 until all.length()) {
            val old = all.getJSONObject(i)
            val matches = old.getString("routineId") == routineId &&
                (date == null || old.getString("dateYmd") == date)
            if (!matches) {
                result.put(old)
            } else if (operation == "snooze" &&
                (old.getString("status") in listOf("completed", "skipped") ||
                 old.optLong("snoozedUntilMs", 0) >= incoming!!.getLong("snoozedUntilMs"))) {
                return@synchronized false
            }
        }
        if (incoming != null) result.put(incoming)
        check(prefs.edit().putString(logKey, result.toString()).commit()) { "Could not save routine log" }
        true
    }

    companion object {
        private val logLock = Any()
        private val channels = mutableSetOf<MethodChannel>()
        private const val logKey = "flutter.domain.routine_logs.v1"
    }
}
