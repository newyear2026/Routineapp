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
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.text.Spannable
import android.text.SpannableString
import android.text.style.ForegroundColorSpan
import android.text.style.RelativeSizeSpan
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.min

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
        val ring by lazy {
            RoutineWidgetRingBitmap.create(ringJson, ringSizePx(context),
                drawCenter = false, colors = skin.ring)
        }
        val largeRing by lazy {
            RoutineWidgetRingBitmap.create(ringJson, largeRingSizePx(context),
                drawCenter = false, colors = skin.ring, labelsInside = true)
        }

        for (id in appWidgetIds) {
            val views = if (isLarge(appWidgetManager, id))
                renderLarge(context, json, display, nowMs, largeRing, skin, expired,
                    isCompact(appWidgetManager, id),
                    appWidgetManager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 360))
            else renderWidget(context, json, display, nowMs, ring, skin, expired)
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
            WidgetStyle.CARDS -> R.layout.widget_routine_cards_compact
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

    /** All three layouts share state, pack artwork and completion click targets. */
    private fun renderLarge(
        context: Context,
        payload: JSONObject,
        display: JSONObject,
        nowMs: Long,
        ring: Bitmap,
        skin: RoutineWidgetSkin,
        expired: Boolean,
        compact: Boolean,
        widthDp: Int = if (compact) 250 else 360,
    ): RemoteViews {
        val cards = widgetStyle == WidgetStyle.CARDS
        val timeline = widgetStyle == WidgetStyle.TIMELINE
        val m = skin.medium
        val views = RemoteViews(context.packageName, when {
            timeline && compact -> R.layout.widget_routine_timeline_narrow
            timeline -> R.layout.widget_routine_timeline_large
            cards && compact -> R.layout.widget_routine_cards_narrow
            cards -> R.layout.widget_routine_cards
            compact -> R.layout.widget_routine_ring_narrow
            else -> R.layout.widget_routine_ring_large
        })
        views.setInt(R.id.widget_action_root, "setBackgroundResource", m.background)
        val decor = if (m.nightSky) R.drawable.widget_stars else decorArt(m.decor)
        if (decor != null) views.setImageViewResource(R.id.widget_action_decor, decor)
        views.setViewVisibility(R.id.widget_action_decor, if (decor == null) View.GONE else View.VISIBLE)
        views.setImageViewResource(R.id.widget_action_pet, m.mascot)
        views.setInt(R.id.widget_action_status, "setBackgroundResource", m.badgeBackground)
        views.setTextColor(R.id.widget_action_status, m.badgeText)
        bindText(views, R.id.widget_action_status, display.optString("currentRoutineStatus"))
        bindText(views, R.id.widget_action_title, display.optString("currentRoutineTitle"))
        views.setTextColor(R.id.widget_action_title, m.title)
        if (!timeline) {
            bindText(views, R.id.widget_action_range,
                if (expired) "" else display.optString("currentRoutineTimeRange"))
            views.setTextColor(R.id.widget_action_range, m.muted)
        }

        val target = display.optLong("timingTargetEpochMs", 0)
        val mode = display.optString("timingMode")
        val counting = !expired && target > nowMs && mode in listOf("start", "end")
        val minutes = if (counting) ((target - nowMs + 59999) / 60000).toInt() else 0
        val duration = if (counting) durationText(payload, minutes) else ""
        val label = if (counting) payload.optString(
            if (mode == "start") "ringUntilStartLabel" else "ringUntilEndLabel") else ""
        if (cards || timeline) {
            val hint = if (counting) "$duration $label" else
                if (expired) "" else display.optString("currentRoutineTimingHint")
            val styled = SpannableString(hint)
            if (duration.isNotEmpty() && hint.length > duration.length) {
                styled.setSpan(RelativeSizeSpan(0.48f), duration.length, hint.length,
                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
                styled.setSpan(ForegroundColorSpan(m.muted), duration.length, hint.length,
                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
            views.setTextViewText(R.id.widget_action_duration, styled)
            views.setTextColor(R.id.widget_action_duration, m.accent)
            // Empty and completed states use explanatory copy, not a fake timer.
            views.setTextViewTextSize(R.id.widget_action_duration,
                android.util.TypedValue.COMPLEX_UNIT_SP, when {
                    !counting -> 13f
                    timeline -> if (compact) 20f else 26f
                    compact -> 24f
                    else -> 28f
                })
        } else {
            views.setImageViewBitmap(R.id.widget_action_ring, ring)
            val clock = Calendar.getInstance().apply { timeInMillis = nowMs }
            bindText(views, R.id.widget_action_duration, if (counting) duration else
                "%02d:%02d".format(clock.get(Calendar.HOUR_OF_DAY), clock.get(Calendar.MINUTE)))
            bindText(views, R.id.widget_action_duration_label, if (counting) label else
                payload.optString("centerTimeLabel"))
            views.setTextColor(R.id.widget_action_duration, skin.ring.hourLabel)
            views.setTextColor(R.id.widget_action_duration_label, skin.ring.tick)
            views.setTextViewTextSize(R.id.widget_action_duration,
                android.util.TypedValue.COMPLEX_UNIT_SP,
                if (!counting) 18f else if (duration.length > 5) 14f else if (compact) 19f else 23f)
        }
        if (timeline) {
            bindTimeline(context, views, display, nowMs, m, expired, compact, widthDp)
        } else {
            val nextTime = display.optString("nextRoutineTime")
            val nextLabel = "${payload.optString("nextLabel")} $nextTime".trim()
            val nextTitle = display.optString("nextRoutineTitle")
            bindText(views, R.id.widget_action_next_label, if (expired || !cards) "" else nextLabel)
            bindText(views, R.id.widget_action_next_title, when {
                expired -> ""
                cards -> nextTitle
                nextTime.isBlank() -> "$nextLabel $nextTitle".trim()
                else -> "$nextLabel $nextTitle"
            })
            views.setTextColor(R.id.widget_action_next_label, m.muted)
            views.setTextColor(R.id.widget_action_next_title, m.title)
        }
        views.setInt(R.id.widget_action_divider, "setBackgroundColor",
            (m.muted and 0x00FFFFFF) or (0x55 shl 24))
        val action = if (expired || display.isNull("completeActionUri")) "" else
            display.optString("completeActionUri")
        views.setViewVisibility(R.id.widget_action_complete,
            if (action.isBlank()) View.GONE else View.VISIBLE)
        if (timeline) views.setViewVisibility(R.id.widget_timeline_complete_container,
            if (action.isBlank()) View.GONE else View.VISIBLE)
        val completeLabel = display.optString("completeLabel")
        views.setTextViewText(R.id.widget_action_complete, "✓  $completeLabel")
        views.setContentDescription(R.id.widget_action_complete, completeLabel)
        if (action.isNotBlank()) {
            views.setOnClickPendingIntent(R.id.widget_action_complete,
                HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(action)))
        }
        views.setOnClickPendingIntent(R.id.widget_action_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
        return views
    }

    private fun bindTimeline(context: Context, views: RemoteViews, display: JSONObject,
        nowMs: Long, skin: RoutineWidgetSkin.MediumSkin, expired: Boolean, compact: Boolean, widthDp: Int) {
        val rows = display.optJSONArray("timelineItems")
        val items = if (expired || rows == null) emptyList() else
            (0 until rows.length()).mapNotNull { rows.optJSONObject(it) }
                .filter { it.optString("title").isNotBlank() && it.has("startEpochMs") }.take(3)
        val visible = if (items.isEmpty()) View.GONE else View.VISIBLE
        views.setViewVisibility(R.id.widget_timeline_schedule, visible)
        views.setViewVisibility(R.id.widget_action_divider, visible)
        val columns = intArrayOf(R.id.widget_timeline_item_0, R.id.widget_timeline_item_1, R.id.widget_timeline_item_2)
        val times = intArrayOf(R.id.widget_timeline_time_0, R.id.widget_timeline_time_1, R.id.widget_timeline_time_2)
        val titles = intArrayOf(R.id.widget_timeline_title_0, R.id.widget_timeline_title_1, R.id.widget_timeline_title_2)
        for (column in columns) views.setViewVisibility(column, View.GONE)
        val slots = when (items.size) { 1 -> listOf(1); 2 -> listOf(0, 2); else -> listOf(0, 1, 2) }
        for ((index, item) in items.withIndex()) {
            val slot = slots[index]
            views.setViewVisibility(columns[slot], View.VISIBLE)
            views.setTextViewText(times[slot], item.optString("time"))
            views.setTextViewText(titles[slot], item.optString("title"))
            views.setTextColor(times[slot], skin.title)
            views.setTextColor(titles[slot], if (nowMs >= item.optLong("startEpochMs")) skin.accent else skin.muted)
        }
        if (items.isNotEmpty()) {
            val density = context.resources.displayMetrics.density
            views.setImageViewBitmap(R.id.widget_timeline_track,
                RoutineWidgetTimelineTrack.create(items.map { it.optLong("startEpochMs") }, nowMs,
                    ((widthDp - if (compact) 20 else 24).coerceAtLeast(1) * density).toInt(),
                    (16 * density).toInt(), skin.accent, skin.muted))
        }
    }

    private fun durationText(payload: JSONObject, minutes: Int): String {
        val hours = minutes / 60
        val rest = minutes % 60
        return when {
            hours > 0 && rest > 0 -> payload.optString("durationHoursMinutesTemplate")
                .replace("{hours}", "$hours").replace("{minutes}", "$rest")
            hours > 0 -> payload.optString("durationHoursTemplate").replace("{hours}", "$hours")
            else -> payload.optString("durationMinutesTemplate").replace("{minutes}", "$rest")
        }
    }

    private fun isCompact(manager: AppWidgetManager, id: Int): Boolean {
        val options = manager.getAppWidgetOptions(id)
        return options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 360) < 300 ||
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 200) < 180
    }

    private fun isLarge(manager: AppWidgetManager, id: Int): Boolean =
        manager.getAppWidgetOptions(id)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT) >= LARGE_MIN_HEIGHT_DP

    /** 한 줄 ↔ 두 줄로 크기를 바꾸면 모양을 다시 고른다. */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        // 다음 갱신 알람이 이 위젯만 기억하지 않도록 같은 종류의 위젯을 모두 넘긴다.
        val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, javaClass))
        onUpdate(context, appWidgetManager, ids, HomeWidgetPlugin.getData(context))
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

    /** 4×2 링. 위젯 갱신 한 번에 실리는 비트맵이 너무 커지지 않도록 상한을 둔다. */
    private fun largeRingSizePx(context: Context): Int {
        val density = context.resources.displayMetrics.density
        return min(max((124 * density).toInt(), 124), LARGE_RING_MAX_PX)
    }

    private fun decorArt(decor: RoutineWidgetSkin.MediumDecor): Int? = when (decor) {
        RoutineWidgetSkin.MediumDecor.SKY -> R.drawable.widget_stars
        RoutineWidgetSkin.MediumDecor.FOREST -> R.drawable.widget_forest
        RoutineWidgetSkin.MediumDecor.MOONCLOUD -> R.drawable.widget_sheep_sky
        RoutineWidgetSkin.MediumDecor.DAWN -> R.drawable.widget_rabbit_dawn
        RoutineWidgetSkin.MediumDecor.TEASHOP -> R.drawable.widget_redpanda_teashop
        RoutineWidgetSkin.MediumDecor.SEASIDE -> R.drawable.widget_otter_seaside
        RoutineWidgetSkin.MediumDecor.SNOWWALK -> R.drawable.widget_penguin_snowpath
        RoutineWidgetSkin.MediumDecor.GARDEN, RoutineWidgetSkin.MediumDecor.NONE -> null
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
        val decor = decorArt(skin.decor)
        if (decor != null) views.setImageViewResource(R.id.widget_decor, decor)
        views.setViewVisibility(R.id.widget_decor, shown(decor != null))
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
        val bmp by lazy {
            RoutineWidgetRingBitmap.create(placeholder, ringSizePx(context), drawCenter = false)
        }
        val largeBmp by lazy {
            RoutineWidgetRingBitmap.create(placeholder, largeRingSizePx(context),
                drawCenter = false, labelsInside = true)
        }
        val display = JSONObject().apply {
            put("currentRoutineTitle", context.getString(R.string.widget_sync_prompt))
            put("ringSegments", JSONArray())
        }
        val nowMs = System.currentTimeMillis()
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id,
                if (isLarge(appWidgetManager, id))
                    renderLarge(context, placeholder, display, nowMs, largeBmp,
                        RoutineWidgetSkin.default, expired = true, compact = isCompact(appWidgetManager, id))
                else renderWidget(context, placeholder, display, nowMs,
                    bmp, RoutineWidgetSkin.default, expired = true))
        }
    }

    companion object {
        private const val PAYLOAD_KEY = "routine_widget_payload"
        private const val LARGE_MIN_HEIGHT_DP = 140
        private const val LARGE_RING_MAX_PX = 420

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
