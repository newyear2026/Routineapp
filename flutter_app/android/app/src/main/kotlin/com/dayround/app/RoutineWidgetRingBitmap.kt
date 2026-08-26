package com.dayround.app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import org.json.JSONObject
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

/**
 * 24시간 원형 시간표 비트맵.
 *
 * Dart의 `OrbitRingPainter`와 **같은 형태**를 그린다 — 얇은 호, 24시간 틱,
 * 세그먼트 사이 간격, 중앙에서 뻗는 현재 시각 바늘. 예전에는 여기만 두꺼운
 * 동심원 도넛이라 앱 홈 화면과 다른 물건으로 보였다.
 *
 * 치수는 모두 [REFERENCE_SIZE] 292 기준 비례값이라 어느 크기에서도 같은 비율이 된다.
 * 색은 res/values/widget_colors.xml과 같은 값이며 기준은
 * `lib/widget_medium/widget_theme.dart`이다.
 */
object RoutineWidgetRingBitmap {

    private const val MIN_PER_DAY = 24 * 60
    private const val REFERENCE_SIZE = 292f
    private const val RADIUS_FACTOR = 0.40f
    private const val GAP_RAD = 0.04

    private object Tokens {
        const val SURFACE = "#FFFFFF"
        const val TEXT_PRIMARY = "#241F31"
        const val TEXT_MUTED = "#6B6478"
        const val ACCENT = "#6744F4"
        const val RING_TRACK = "#D9D1F2"
    }

    fun create(json: JSONObject, sizePx: Int): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val cx = sizePx / 2f
        val cy = sizePx / 2f
        val scale = sizePx / REFERENCE_SIZE
        val orbitRadius = sizePx * RADIUS_FACTOR
        val segmentStroke = 11f * scale
        val trackStroke = 9f * scale

        canvas.drawCircle(
            cx, cy, sizePx / 2f,
            Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor(Tokens.SURFACE) },
        )

        val oval = RectF(cx - orbitRadius, cy - orbitRadius, cx + orbitRadius, cy + orbitRadius)
        canvas.drawArc(
            oval, -90f, 360f, false,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor(Tokens.RING_TRACK)
                style = Paint.Style.STROKE
                strokeWidth = trackStroke
                strokeCap = Paint.Cap.ROUND
            },
        )

        drawHourTicks(canvas, cx, cy, orbitRadius, trackStroke, scale)
        drawSegments(canvas, json, oval, segmentStroke)
        drawNowPointer(canvas, json, cx, cy, orbitRadius, scale)
        drawCenterTime(canvas, json, cx, cy, scale)

        return bmp
    }

    private fun drawHourTicks(
        canvas: Canvas,
        cx: Float,
        cy: Float,
        orbitRadius: Float,
        trackStroke: Float,
        scale: Float,
    ) {
        for (hour in 0 until 24) {
            val angle = minutesToRad(hour * 60.0)
            val isMajor = hour % 6 == 0
            val tickLength = (if (isMajor) 11f else 6f) * scale
            val base = orbitRadius - trackStroke / 2f - 10f * scale
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor(Tokens.TEXT_MUTED)
                alpha = if (isMajor) 87 else 46
                strokeWidth = (if (isMajor) 2.4f else 1.3f) * scale
                strokeCap = Paint.Cap.ROUND
            }
            canvas.drawLine(
                (cx + cos(angle) * base).toFloat(),
                (cy + sin(angle) * base).toFloat(),
                (cx + cos(angle) * (base - tickLength)).toFloat(),
                (cy + sin(angle) * (base - tickLength)).toFloat(),
                paint,
            )
        }
    }

    private fun drawSegments(
        canvas: Canvas,
        json: JSONObject,
        oval: RectF,
        segmentStroke: Float,
    ) {
        val segments = json.optJSONArray("ringSegments") ?: return
        for (i in 0 until segments.length()) {
            val seg = segments.getJSONObject(i)
            val sweepMin = seg.optInt("sweepMinutes")
            if (sweepMin <= 0) continue

            var colorArgb = seg.optInt("colorArgb")
            if (Color.alpha(colorArgb) == 0) colorArgb = colorArgb or (0xFF shl 24)

            val startRad = minutesToRad(seg.optInt("startMinutesFromMidnight").toDouble()) + GAP_RAD
            val sweepRad = sweepMin.toDouble() / MIN_PER_DAY * (2 * PI)
            val safeSweep = max(0.02, sweepRad - GAP_RAD * 2)

            canvas.drawArc(
                oval,
                Math.toDegrees(startRad).toFloat(),
                Math.toDegrees(safeSweep).toFloat(),
                false,
                Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = colorArgb
                    style = Paint.Style.STROKE
                    strokeWidth = segmentStroke
                    strokeCap = Paint.Cap.ROUND
                },
            )
        }
    }

    private fun drawNowPointer(
        canvas: Canvas,
        json: JSONObject,
        cx: Float,
        cy: Float,
        orbitRadius: Float,
        scale: Float,
    ) {
        val ptr = json.optDouble("pointerAngleRad", -PI / 2)
        val px = (cx + cos(ptr) * (orbitRadius + 4f * scale)).toFloat()
        val py = (cy + sin(ptr) * (orbitRadius + 4f * scale)).toFloat()

        canvas.drawLine(
            cx, cy, px, py,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor(Tokens.ACCENT)
                alpha = 128
                strokeWidth = 1.5f * scale
            },
        )
        canvas.drawCircle(
            px, py, 7f * scale,
            Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor(Tokens.SURFACE) },
        )
        canvas.drawCircle(
            px, py, 4.5f * scale,
            Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor(Tokens.ACCENT) },
        )
    }

    private fun drawCenterTime(
        canvas: Canvas,
        json: JSONObject,
        cx: Float,
        cy: Float,
        scale: Float,
    ) {
        val hour = json.optInt("currentTimeHour")
        val minute = json.optInt("currentTimeMinute")
        val timePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(Tokens.TEXT_PRIMARY)
            textSize = 55f * scale
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText("%02d:%02d".format(hour, minute), cx, cy + 6f * scale, timePaint)

        val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(Tokens.TEXT_MUTED)
            textSize = 25f * scale
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText(
            json.optString("centerTimeLabel", "지금"),
            cx,
            cy + 32f * scale,
            labelPaint,
        )
    }

    private fun minutesToRad(minutes: Double): Double =
        minutes / MIN_PER_DAY * (2 * PI) - PI / 2
}
