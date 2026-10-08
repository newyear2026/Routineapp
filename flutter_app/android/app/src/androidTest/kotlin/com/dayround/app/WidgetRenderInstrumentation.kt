package com.dayround.app

import android.app.Activity
import android.app.Instrumentation
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.RemoteViews
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.Calendar

/** Render the real RemoteViews on a device without touching saved routines/logs. */
class WidgetRenderInstrumentation : Instrumentation() {
    override fun onCreate(arguments: Bundle?) { super.onCreate(arguments); start() }
    override fun onStart() {
        val result = Bundle()
        try {
            var failure: Throwable? = null
            runOnMainSync {
                try { verifyLayouts() } catch (error: Throwable) { failure = error }
            }
            failure?.let { throw it }
            result.putString("stream", "Widget native rendering and action binding passed\n")
            finish(Activity.RESULT_OK, result)
        } catch (error: Throwable) {
            result.putString("stream", error.stackTraceToString())
            finish(Activity.RESULT_CANCELED, result)
        }
    }

    private fun verifyLayouts() {
        val context = targetContext
        val now = Calendar.getInstance().apply {
            set(2026, Calendar.OCTOBER, 7, 21, 18, 0); set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val state = JSONObject().apply {
            put("currentRoutineTitle", "독서")
            put("currentRoutineStatus", "진행 중")
            put("currentRoutineTimeRange", "21:00–21:30")
            put("currentRoutineTimingHint", "종료까지 12분 남음")
            put("timingTargetEpochMs", now + 12 * 60000)
            put("timingMode", "end")
            put("nextRoutineTitle", "스트레칭"); put("nextRoutineTime", "21:30")
            put("completeLabel", "완료")
            put("completeActionUri", "loopet-widget://complete?id=render-only&date=2026-10-07&version=1&start=1260&end=1290")
            put("activeSegmentId", "reading")
            put("pointerAngleRad", 1278.0 / 1440 * 2 * Math.PI - Math.PI / 2)
            put("currentTimeHour", 21); put("currentTimeMinute", 18)
            put("ringSegments", JSONArray().apply {
                listOf(Triple("reading",1260,0xFF6744F4), Triple("stretch",1290,0xFFFFAD3D),
                    Triple("sleep",1320,0xFFFF746C)).forEach { (id, start, color) ->
                    put(JSONObject().put("id",id).put("startMinutesFromMidnight",start)
                        .put("sweepMinutes",30).put("colorArgb",color))
                }
            })
        }
        val payload = JSONObject().apply {
            put("nextLabel","다음"); put("centerTimeLabel","지금")
            put("durationMinutesTemplate","{minutes}분")
            put("durationHoursTemplate","{hours}시간")
            put("durationHoursMinutesTemplate","{hours}시간 {minutes}분")
            put("ringUntilEndLabel","남음"); put("ringUntilStartLabel","뒤 시작")
        }
        val method = RoutineMediumWidgetProvider::class.java.getDeclaredMethod("renderLarge",
            Context::class.java, JSONObject::class.java, JSONObject::class.java,
            java.lang.Long.TYPE, Bitmap::class.java, RoutineWidgetSkin::class.java,
            java.lang.Boolean.TYPE, java.lang.Boolean.TYPE).apply { isAccessible = true }
        val skin = RoutineWidgetSkin.default
        val ring = RoutineWidgetRingBitmap.create(state, 420, drawCenter = false,
            colors = skin.ring, labelsInside = true)
        for ((name, provider) in listOf("cards" to RoutineCardsWidgetProvider(),
            "ring" to RoutineMediumWidgetProvider())) {
            for (width in listOf(360, 250)) {
                val remote = method.invoke(provider, context, payload, state, now, ring, skin, false, width < 300) as RemoteViews
                val root = remote.apply(context, FrameLayout(context))
                check(root.findViewById<TextView>(R.id.widget_action_complete).hasOnClickListeners())
                render(root, "$name-$width", width, if (width < 300) 160 else 180)
            }
            val completed = JSONObject(state.toString()).apply {
                put("currentRoutineStatus","완료"); remove("completeActionUri")
                remove("timingTargetEpochMs"); put("currentRoutineTimingHint", "")
            }
            val remote = method.invoke(provider, context, payload, completed, now, ring, skin, false, false) as RemoteViews
            val root = remote.apply(context, FrameLayout(context))
            check(root.findViewById<TextView>(R.id.widget_action_complete).visibility == View.GONE)
            render(root, "$name-completed", 360, 180)
        }
        ring.recycle()
    }

    private fun render(root: View, name: String, widthDp: Int, heightDp: Int) {
        val density = targetContext.resources.displayMetrics.density
        val width = (widthDp * density).toInt(); val height = (heightDp * density).toInt()
        root.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
        root.layout(0,0,width,height)
        verifyTextBounds(root as ViewGroup, name)
        val image = Bitmap.createBitmap(width,height,Bitmap.Config.ARGB_8888)
        root.draw(Canvas(image))
        val dir = File(targetContext.filesDir, "widget-qa").apply { mkdirs() }
        File(dir,"$name.png").outputStream().use { image.compress(Bitmap.CompressFormat.PNG,100,it) }
        image.recycle()
    }

    private fun verifyTextBounds(parent: ViewGroup, name: String) {
        for (i in 0 until parent.childCount) {
            val child = parent.getChildAt(i)
            if (child.visibility != View.VISIBLE) continue
            check(child.top >= 0 && child.bottom <= parent.height) {
                "$name: child ${child.id} clipped by parent: ${child.top}..${child.bottom}/${parent.height}"
            }
            if (child is TextView && child.text.isNotBlank()) {
                val layout = child.layout ?: continue
                check(layout.getLineBottom(layout.lineCount - 1) <=
                    child.height - child.compoundPaddingTop - child.compoundPaddingBottom) {
                    "$name: clipped text '${child.text}': ${layout.height}/${child.height}"
                }
            }
            if (child is ViewGroup) verifyTextBounds(child, name)
        }
    }
}
