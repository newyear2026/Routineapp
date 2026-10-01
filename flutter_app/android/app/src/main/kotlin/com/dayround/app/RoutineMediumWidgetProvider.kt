package com.dayround.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
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
open class RoutineMediumWidgetProvider : HomeWidgetProvider() {

    protected open val widgetStyle: WidgetStyle = WidgetStyle.RING

    protected enum class WidgetStyle { RING, TIMELINE, CARDS }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, javaClass)
            )
            if (ids.isNotEmpty()) {
                context.sendBroadcast(Intent(context, javaClass).apply {
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
        val skin = RoutineWidgetSkin.forPack(json.optString("characterPackId"))
        val ringPx = ringSizePx(context)
        val ring = RoutineWidgetRingBitmap.create(ringJson, ringPx,
            drawCenter = false, colors = skin.ring)

        for (id in appWidgetIds) {
            val views = renderWidget(context, json, display, nowMs, ring,
                skin, expired)
            appWidgetManager.updateAppWidget(id, views)
        }
        scheduleNextUpdate(context, appWidgetIds, json, nowMs)
    }

    private fun renderWidget(
        context: Context,
        payload: JSONObject,
        display: JSONObject,
        nowMs: Long,
        ring: Bitmap,
        skin: RoutineWidgetSkin,
        expired: Boolean,
    ): RemoteViews {
        val nextTitle = display.optString("nextRoutineTitle", "")
        val nextLabel = if (nextTitle.isBlank()) "" else
            payload.optString("nextLabel").ifBlank { context.getString(R.string.widget_next_label) }
        val hint = if (expired) "" else timingHint(payload, display, nowMs)
        val layout = when (widgetStyle) {
            WidgetStyle.RING -> R.layout.widget_routine_medium
            WidgetStyle.TIMELINE -> R.layout.widget_routine_timeline
            WidgetStyle.CARDS -> R.layout.widget_routine_cards
        }
        val views = RemoteViews(context.packageName, layout)
        when (widgetStyle) {
            WidgetStyle.RING -> {
                bindPackArtwork(views, skin.medium)
                bindText(views, R.id.widget_status_badge, display.optString("currentRoutineStatus", ""))
                bindText(views, R.id.widget_current_title, display.optString("currentRoutineTitle", ""))
                bindTimingHint(views, R.id.widget_timing_hint, hint, REGULAR_HINT_SUFFIX)
                bindText(views, R.id.widget_next_label, nextLabel)
                bindText(views, R.id.widget_next_title, nextTitle)
                bindText(views, R.id.widget_next_time, display.optString("nextRoutineTime", ""))
                if (skin.medium.nightSky) {
                    bindText(views, R.id.widget_stargazer_status,
                        display.optString("currentRoutineStatus", ""))
                    bindText(views, R.id.widget_stargazer_title,
                        display.optString("currentRoutineTitle", ""))
                    bindTimingHint(views, R.id.widget_stargazer_hint, hint, skin.medium.muted)
                    bindText(views, R.id.widget_stargazer_next_label, nextLabel)
                    bindText(views, R.id.widget_stargazer_next_title, nextTitle)
                    bindText(views, R.id.widget_stargazer_next_time,
                        display.optString("nextRoutineTime", ""))
                }
                bindText(views, R.id.widget_now_label,
                    display.optString("centerTimeLabel", payload.optString("centerTimeLabel"))
                        .ifBlank { context.getString(R.string.widget_now_label) })
                views.setImageViewBitmap(R.id.widget_ring, ring)
            }
            WidgetStyle.TIMELINE -> {
                views.setImageViewBitmap(R.id.widget_variant_art,
                    RoutineWidgetVariantBitmap.create(context, "timeline", skin.variant, display,
                        display.optString("currentRoutineStatus", ""),
                        display.optString("currentRoutineTitle", ""), hint, nextLabel,
                        nextTitle, display.optString("nextRoutineTime", "")))
            }
            WidgetStyle.CARDS -> {
                views.setImageViewBitmap(R.id.widget_variant_art,
                    RoutineWidgetVariantBitmap.create(context, "cards", skin.variant, display,
                        display.optString("currentRoutineStatus", ""),
                        display.optString("currentRoutineTitle", ""), hint, nextLabel,
                        nextTitle, display.optString("nextRoutineTime", "")))
            }
        }
        return views
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
        val intent = Intent(context, javaClass).apply {
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
        val intent = Intent(context, javaClass).apply {
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

    private fun bindTimingHint(views: RemoteViews, viewId: Int, text: String,
        suffixColor: Int) {
        val styled = SpannableString(text)
        val suffix = if (text.endsWith(" 남음")) text.length - 3 else text.length
        if (suffix < text.length) {
            styled.setSpan(ForegroundColorSpan(suffixColor),
                suffix, text.length, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        val duration = Regex("\\d+(?:시간\\s*\\d+)?분|\\d+시간").find(text)
        if (duration != null) {
            styled.setSpan(RelativeSizeSpan(1.12f), duration.range.first,
                duration.range.last + 1, Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
        }
        views.setTextViewText(viewId, styled)
        views.setViewVisibility(viewId, if (text.isBlank()) View.GONE else View.VISIBLE)
    }

    private fun ringSizePx(context: Context): Int {
        val density = context.resources.displayMetrics.density
        return max((63 * density).toInt(), 63)
    }

    private fun bindPackArtwork(views: RemoteViews, skin: RoutineWidgetSkin.MediumSkin) {
        fun shown(visible: Boolean) = if (visible) View.VISIBLE else View.GONE
        views.setInt(R.id.widget_root, "setBackgroundResource", skin.background)
        views.setInt(R.id.widget_status_badge, "setBackgroundResource", skin.badgeBackground)
        views.setImageViewResource(
            if (skin.featuredMascot) R.id.widget_featured_mascot_art else R.id.widget_mascot,
            skin.mascot)
        views.setViewVisibility(R.id.widget_mascot, shown(!skin.featuredMascot))
        views.setViewVisibility(R.id.widget_stargazer_mascot, shown(skin.featuredMascot))
        views.setViewVisibility(R.id.widget_regular_column, shown(!skin.nightSky))
        views.setViewVisibility(R.id.widget_stargazer_column, shown(skin.nightSky))
        views.setViewVisibility(R.id.widget_stargazer_scene, shown(skin.nightSky))
        views.setImageViewResource(R.id.widget_decor,
            when (skin.decor) {
                RoutineWidgetSkin.MediumDecor.FOREST -> R.drawable.widget_forest
                RoutineWidgetSkin.MediumDecor.MOONCLOUD -> R.drawable.widget_sheep_sky
                RoutineWidgetSkin.MediumDecor.DAWN -> R.drawable.widget_rabbit_dawn
                else -> R.drawable.widget_stars
            })
        views.setViewVisibility(R.id.widget_decor,
            shown(skin.decor == RoutineWidgetSkin.MediumDecor.SKY ||
                skin.decor == RoutineWidgetSkin.MediumDecor.FOREST ||
                skin.decor == RoutineWidgetSkin.MediumDecor.MOONCLOUD ||
                skin.decor == RoutineWidgetSkin.MediumDecor.DAWN))
        views.setViewVisibility(R.id.widget_leaf,
            shown(skin.decor == RoutineWidgetSkin.MediumDecor.GARDEN))
        views.setViewVisibility(R.id.widget_daisy,
            shown(skin.decor == RoutineWidgetSkin.MediumDecor.GARDEN))
        views.setTextColor(R.id.widget_current_title, skin.title)
        views.setTextColor(R.id.widget_timing_hint, skin.accent)
        views.setTextColor(R.id.widget_next_label, skin.muted)
        views.setTextColor(R.id.widget_next_title, skin.title)
        views.setTextColor(R.id.widget_next_time, skin.muted)
        views.setTextColor(R.id.widget_status_badge, skin.badgeText)
        views.setInt(R.id.widget_now_label, "setBackgroundResource", skin.nowLabelBackground)
        views.setTextColor(R.id.widget_now_label, skin.nowLabelText)
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
        val display = JSONObject().apply {
            put("currentRoutineTitle", context.getString(R.string.widget_sync_prompt))
            put("ringSegments", JSONArray())
        }
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id,
                renderWidget(context, placeholder, display, System.currentTimeMillis(),
                    bmp, RoutineWidgetSkin.default, expired = true))
        }
    }

    companion object {
        private const val PAYLOAD_KEY = "routine_widget_payload"

        /** 기본 글자 열의 «남음» 꼬리 색. 팩과 무관하다. */
        private val REGULAR_HINT_SUFFIX = Color.parseColor("#6A6489")
    }
}

class RoutineTimelineWidgetProvider : RoutineMediumWidgetProvider() {
    override val widgetStyle = WidgetStyle.TIMELINE
}

class RoutineCardsWidgetProvider : RoutineMediumWidgetProvider() {
    override val widgetStyle = WidgetStyle.CARDS
}
