package com.example.routine_timer

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max

/**
 * Medium 시스템 위젯 — [HomeWidgetPlugin]이 저장한 JSON을 읽어 갱신한다.
 */
class RoutineMediumWidgetProvider : HomeWidgetProvider() {

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

        val density = context.resources.displayMetrics.density
        val ringPx = max((120 * density).toInt(), 120)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_routine_medium)
            views.setTextViewText(R.id.widget_header_title, json.optString("headerTitle", ""))
            views.setTextViewText(R.id.widget_subtitle, json.optString("subtitle", ""))
            views.setTextViewText(R.id.widget_current_title, json.optString("currentRoutineTitle", ""))
            views.setTextViewText(R.id.widget_time_range, json.optString("currentRoutineTimeRange", ""))
            views.setTextViewText(R.id.widget_status_badge, json.optString("currentRoutineStatus", ""))
            views.setTextViewText(R.id.widget_next_line, json.optString("nextRoutineLine", ""))

            val bmp = RoutineWidgetRingBitmap.create(json, ringPx)
            views.setImageViewBitmap(R.id.widget_ring, bmp)

            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun showPlaceholder(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val density = context.resources.displayMetrics.density
        val ringPx = max((120 * density).toInt(), 120)
        val placeholder = JSONObject().apply {
            put("currentTimeHour", 0)
            put("currentTimeMinute", 0)
            put("pointerAngleRad", -Math.PI / 2)
            put("centerTimeLabel", "현재 시간")
            put("ringSegments", JSONArray())
        }
        val bmp = RoutineWidgetRingBitmap.create(placeholder, ringPx)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_routine_medium)
            views.setTextViewText(R.id.widget_header_title, "하루 루틴 시간표")
            views.setTextViewText(R.id.widget_subtitle, "앱을 열어 동기화해 주세요")
            views.setTextViewText(R.id.widget_current_title, "—")
            views.setTextViewText(R.id.widget_time_range, "")
            views.setTextViewText(R.id.widget_status_badge, "")
            views.setTextViewText(R.id.widget_next_line, "")
            views.setImageViewBitmap(R.id.widget_ring, bmp)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    companion object {
        private const val PAYLOAD_KEY = "routine_widget_payload"
    }
}
