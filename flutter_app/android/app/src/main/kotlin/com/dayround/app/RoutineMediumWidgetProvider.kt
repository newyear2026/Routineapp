package com.dayround.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.text.Spannable
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import android.text.style.RelativeSizeSpan
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import kotlin.math.PI
import kotlin.math.max

/**
 * Medium 시스템 위젯 — [HomeWidgetPlugin]이 저장한 JSON을 읽어 갱신한다.
 *
 * 표시 항목·문구는 Dart(`home_medium_widget.dart`)·iOS와 같다.
 * 값이 비면 '—' 같은 자리표시자를 남기지 않고 그 줄을 숨긴다.
 */
class RoutineMediumWidgetProvider : HomeWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, RoutineMediumWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                context.sendBroadcast(Intent(context, RoutineMediumWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                })
            }
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val jsonStr = widgetData.getString(PAYLOAD_KEY, null)
        if (jsonStr.isNullOrBlank()) {
            showPlaceholder(context, appWidgetManager, appWidgetIds)
            return
        }
        val json = try {
            JSONObject(jsonStr)
        } catch (_: Exception) {
            showPlaceholder(context, appWidgetManager, appWidgetIds)
            return
        }

        val nowMs = System.currentTimeMillis()
        val validUntilMs = json.optLong("validUntilEpochMs", Long.MAX_VALUE)
        val expired = nowMs >= validUntilMs
        val state = stateAt(json, nowMs)
        val display = if (expired) JSONObject().apply {
            put("currentRoutineTitle", json.optString("refreshHint", context.getString(R.string.widget_sync_prompt)))
            put("nextRoutineTitle", "")
            put("ringSegments", JSONArray())
        } else state ?: json
        val clock = Calendar.getInstance()
        val minuteOfDay = clock.get(Calendar.HOUR_OF_DAY) * 60 + clock.get(Calendar.MINUTE)
        val ringJson = JSONObject(display.toString()).apply {
            put("currentTimeHour", clock.get(Calendar.HOUR_OF_DAY))
            put("currentTimeMinute", clock.get(Calendar.MINUTE))
            put("pointerAngleRad", minuteOfDay / 1440.0 * 2 * PI - PI / 2)
            put("centerTimeLabel", display.optString("centerTimeLabel", json.optString("centerTimeLabel", "")))
        }
        val ringPx = ringSizePx(context)
        val ring = RoutineWidgetRingBitmap.create(ringJson, ringPx, drawCenter = false)
        val garden = json.optString("characterPackId") == "poodle_garden"

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_routine_medium)
            bindPackArtwork(views, garden)
            bindText(views, R.id.widget_status_badge, display.optString("currentRoutineStatus", ""))
            bindText(views, R.id.widget_current_title, display.optString("currentRoutineTitle", ""))
            bindTimingHint(views, if (expired) "" else timingHint(json, display, nowMs))
            bindText(views, R.id.widget_next_label,
                json.optString("nextLabel").ifBlank { context.getString(R.string.widget_next_label) })
            bindText(views, R.id.widget_next_title, display.optString("nextRoutineTitle", ""))
            bindText(views, R.id.widget_next_time, display.optString("nextRoutineTime", ""))
            bindText(views, R.id.widget_now_label,
                display.optString("centerTimeLabel", json.optString("centerTimeLabel"))
                    .ifBlank { context.getString(R.string.widget_now_label) })

            views.setImageViewBitmap(R.id.widget_ring, ring)
            appWidgetManager.updateAppWidget(id, views)
        }
        scheduleNextUpdate(context, appWidgetIds, json, nowMs)
    }

    private fun stateAt(payload: JSONObject, nowMs: Long): JSONObject? {
        val states = payload.optJSONArray("timelineStates") ?: return null
        var selected: JSONObject? = null
        for (i in 0 until states.length()) {
            val state = states.optJSONObject(i) ?: continue
            if (state.optLong("effectiveAtEpochMs") > nowMs) break
            selected = state
        }
        return selected
    }

    private fun timingHint(payload: JSONObject, state: JSONObject, nowMs: Long): String {
        val target = state.optLong("timingTargetEpochMs", 0)
        val mode = state.optString("timingMode")
        if (target <= nowMs || mode.isBlank()) {
            return state.optString("currentRoutineTimingHint", "")
        }
        val minutes = ((target - nowMs + 59999) / 60000).toInt()
        val hours = minutes / 60
        val remainder = minutes % 60
        val duration = when {
            hours > 0 && remainder > 0 -> payload.optString("durationHoursMinutesTemplate")
                .replace("{hours}", hours.toString()).replace("{minutes}", remainder.toString())
            hours > 0 -> payload.optString("durationHoursTemplate")
                .replace("{hours}", hours.toString())
            else -> payload.optString("durationMinutesTemplate")
                .replace("{minutes}", minutes.toString())
        }
        val template = payload.optString(
            if (mode == "start") "timingStartTemplate" else "timingEndTemplate"
        )
        return if (template.contains("{duration}") && duration.isNotBlank())
            template.replace("{duration}", duration)
        else state.optString("currentRoutineTimingHint", "")
    }

    private fun scheduleNextUpdate(context: Context, ids: IntArray, payload: JSONObject, nowMs: Long) {
        if (ids.isEmpty()) return
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, RoutineMediumWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        val pending = PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val nextFiveMinutes = (nowMs / 300000 + 1) * 300000
        var nextBoundary = Long.MAX_VALUE
        val states = payload.optJSONArray("timelineStates")
        if (states != null) for (i in 0 until states.length()) {
            val at = states.optJSONObject(i)?.optLong("effectiveAtEpochMs") ?: continue
            if (at > nowMs) {
                nextBoundary = at
                break
            }
        }
        val expiry = payload.optLong("validUntilEpochMs", 0)
        if (expiry > nowMs) nextBoundary = minOf(nextBoundary, expiry)
        if (expiry > 0 && expiry <= nowMs) return
        val next = minOf(nextFiveMinutes, nextBoundary)
        val exactBoundary = next == nextBoundary
        try {
            if (!exactBoundary && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pending)
            } else if (!exactBoundary) {
                manager.set(AlarmManager.RTC_WAKEUP, next, pending)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !manager.canScheduleExactAlarms()) {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pending)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pending)
            } else {
                manager.setExact(AlarmManager.RTC_WAKEUP, next, pending)
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pending)
            } else {
                manager.set(AlarmManager.RTC_WAKEUP, next, pending)
            }
        }
    }

    override fun onDisabled(context: Context) {
        val intent = Intent(context, RoutineMediumWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
        }
        PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )?.let { pending ->
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pending)
            pending.cancel()
        }
        super.onDisabled(context)
    }

    /** 빈 문자열이면 줄을 숨긴다. */
    private fun bindText(views: RemoteViews, viewId: Int, text: String) {
        views.setTextViewText(viewId, text)
        views.setViewVisibility(viewId, if (text.isBlank()) View.GONE else View.VISIBLE)
    }

    private fun bindTimingHint(views: RemoteViews, text: String) {
        val styled = SpannableString(text)
        val suffix = if (text.endsWith(" 남음")) text.length - 3 else text.length
        if (suffix < text.length) {
            styled.setSpan(ForegroundColorSpan(Color.parseColor("#6A6489")),
                suffix, text.length, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        val duration = Regex("\\d+(?:시간\\s*\\d+)?분|\\d+시간").find(text)
        if (duration != null) {
            styled.setSpan(RelativeSizeSpan(1.12f), duration.range.first,
                duration.range.last + 1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        views.setTextViewText(R.id.widget_timing_hint, styled)
        views.setViewVisibility(R.id.widget_timing_hint, if (text.isBlank()) View.GONE else View.VISIBLE)
    }

    private fun ringSizePx(context: Context): Int {
        val density = context.resources.displayMetrics.density
        return max((101 * density).toInt(), 101)
    }

    private fun bindPackArtwork(views: RemoteViews, garden: Boolean) {
        views.setInt(R.id.widget_root, "setBackgroundResource",
            if (garden) R.drawable.widget_medium_bg_poodle else R.drawable.widget_medium_bg_cat)
        views.setInt(R.id.widget_status_badge, "setBackgroundResource",
            if (garden) R.drawable.widget_badge_bg_poodle else R.drawable.widget_badge_bg)
        views.setImageViewResource(R.id.widget_mascot,
            if (garden) R.drawable.widget_poodle else R.drawable.widget_cat)
        views.setViewVisibility(R.id.widget_decor, if (garden) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.widget_leaf, if (garden) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.widget_daisy, if (garden) View.VISIBLE else View.GONE)
    }

    private fun showPlaceholder(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val placeholder = JSONObject().apply {
            put("currentTimeHour", 0)
            put("currentTimeMinute", 0)
            put("pointerAngleRad", -Math.PI / 2)
            put("centerTimeLabel", "지금")
            put("ringSegments", JSONArray())
        }
        val bmp = RoutineWidgetRingBitmap.create(placeholder, ringSizePx(context), drawCenter = false)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_routine_medium)
            bindPackArtwork(views, false)
            bindText(views, R.id.widget_status_badge, "")
            bindText(views, R.id.widget_current_title, context.getString(R.string.widget_sync_prompt))
            bindText(views, R.id.widget_next_label, context.getString(R.string.widget_next_label))
            bindText(views, R.id.widget_timing_hint, "")
            bindText(views, R.id.widget_next_title, "없음")
            bindText(views, R.id.widget_next_time, "")
            bindText(views, R.id.widget_now_label, context.getString(R.string.widget_now_label))
            views.setImageViewBitmap(R.id.widget_ring, bmp)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    companion object {
        private const val PAYLOAD_KEY = "routine_widget_payload"
    }
}
