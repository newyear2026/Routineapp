package com.example.routine_timer

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import org.json.JSONObject
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * JSON [docs/SYSTEM_HOME_WIDGET_SPEC.md] → 동심원 도넛 + 포인터 + 중앙 시각 비트맵.
 */
object RoutineWidgetRingBitmap {

    private const val MIN_PER_DAY = 24 * 60

    fun create(json: JSONObject, sizePx: Int): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val cx = sizePx / 2f
        val cy = sizePx / 2f
        val scale = sizePx / 200f
        val innerR = 52f * scale
        val outerR = 78f * scale
        val midR = (innerR + outerR) / 2f
        val strokeW = outerR - innerR

        val track = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(166, 240, 232, 224)
            style = Paint.Style.STROKE
            strokeWidth = strokeW
        }
        val oval = RectF(cx - midR, cy - midR, cx + midR, cy + midR)
        canvas.drawArc(oval, -90f, 360f, false, track)

        val segments = json.optJSONArray("ringSegments")
        val activeId =
            if (json.isNull("activeSegmentId")) null else json.getString("activeSegmentId")
        if (segments != null) {
            for (i in 0 until segments.length()) {
                val seg = segments.getJSONObject(i)
                val startMin = seg.getInt("startMinutesFromMidnight")
                val sweepMin = seg.getInt("sweepMinutes")
                var colorArgb = seg.getInt("colorArgb")
                if (Color.alpha(colorArgb) == 0) {
                    colorArgb = colorArgb or (0xFF shl 24)
                }
                val id = seg.getString("id")
                val startRad = startMin.toDouble() / MIN_PER_DAY * (2 * Math.PI) - Math.PI / 2
                val sweepRad = sweepMin.toDouble() / MIN_PER_DAY * (2 * Math.PI)
                val startDeg = Math.toDegrees(startRad).toFloat()
                val sweepDeg = Math.toDegrees(sweepRad).toFloat()
                val isActive = activeId != null && id == activeId
                val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = colorArgb
                    style = Paint.Style.STROKE
                    strokeWidth = strokeW
                    strokeCap = Paint.Cap.ROUND
                    alpha = if (isActive) 255 else min(255, (255 * 0.72f).toInt())
                }
                canvas.drawArc(oval, startDeg, sweepDeg, false, paint)
            }
        }

        val hole = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#FFF9F5")
        }
        canvas.drawCircle(cx, cy, innerR - 1f, hole)

        val ptr = json.getDouble("pointerAngleRad")
        val r0 = midR - strokeW * 0.42f
        val r1 = outerR + 3f * scale
        val line = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#E07A5F")
            strokeWidth = max(3f, 5f * scale)
            strokeCap = Paint.Cap.ROUND
        }
        canvas.drawLine(
            (cx + r0 * cos(ptr)).toFloat(),
            (cy + r0 * sin(ptr)).toFloat(),
            (cx + r1 * cos(ptr)).toFloat(),
            (cy + r1 * sin(ptr)).toFloat(),
            line,
        )
        val dot = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#E07A5F")
        }
        canvas.drawCircle(
            (cx + r1 * cos(ptr)).toFloat(),
            (cy + r1 * sin(ptr)).toFloat(),
            3.8f * scale,
            dot,
        )

        val hour = json.getInt("currentTimeHour")
        val minute = json.getInt("currentTimeMinute")
        val timeStr = "%02d:%02d".format(hour, minute)
        val tp = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#5C4033")
            textSize = 22f * scale
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(timeStr, cx, cy + 8f * scale, tp)
        val lp = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#9A8AAC")
            textSize = 9f * scale
            textAlign = Paint.Align.CENTER
        }
        val label = json.optString("centerTimeLabel", "현재 시간")
        canvas.drawText(label, cx, cy + 22f * scale, lp)

        return bmp
    }
}
