package com.dayround.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.max

/**
 * Medium 시스템 위젯 — [HomeWidgetPlugin]이 저장한 JSON을 읽어 갱신한다.
 *
 * 표시 항목·문구는 Dart(`home_medium_widget.dart`)·iOS와 같다.
 * 값이 비면 '—' 같은 자리표시자를 남기지 않고 그 줄을 숨긴다.
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

        val ringPx = ringSizePx(context)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_routine_medium)
            bindText(views, R.id.widget_status_badge, json.optString("currentRoutineStatus", ""))
            bindText(views, R.id.widget_current_title, json.optString("currentRoutineTitle", ""))
            bindText(views, R.id.widget_timing_hint, json.optString("currentRoutineTimingHint", ""))
            bindText(views, R.id.widget_next_title, json.optString("nextRoutineTitle", "없음"))
            bindText(views, R.id.widget_next_time, json.optString("nextRoutineTime", ""))

            views.setImageViewBitmap(R.id.widget_ring, RoutineWidgetRingBitmap.create(json, ringPx))
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    /** 빈 문자열이면 줄을 숨긴다. */
    private fun bindText(views: RemoteViews, viewId: Int, text: String) {
        views.setTextViewText(viewId, text)
        views.setViewVisibility(viewId, if (text.isBlank()) View.GONE else View.VISIBLE)
    }

    private fun ringSizePx(context: Context): Int {
        val density = context.resources.displayMetrics.density
        return max((96 * density).toInt(), 96)
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
        val bmp = RoutineWidgetRingBitmap.create(placeholder, ringSizePx(context))
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_routine_medium)
            bindText(views, R.id.widget_status_badge, "")
            bindText(views, R.id.widget_current_title, "앱을 열어 동기화해 주세요")
            bindText(views, R.id.widget_timing_hint, "")
            bindText(views, R.id.widget_next_title, "없음")
            bindText(views, R.id.widget_next_time, "")
            views.setImageViewBitmap(R.id.widget_ring, bmp)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    companion object {
        private const val PAYLOAD_KEY = "routine_widget_payload"
    }
}
