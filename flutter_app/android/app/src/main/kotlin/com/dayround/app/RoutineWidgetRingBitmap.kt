package com.dayround.app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import org.json.JSONObject
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin
import kotlin.math.sqrt

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
    private const val REFERENCE_SIZE = 150f
    private const val RADIUS_FACTOR = 0.395f
    private const val GAP_RAD = 0.05

    private object Tokens {
        const val SURFACE = "#FFFFFF"
        const val TEXT_PRIMARY = "#221C42"
        const val TEXT_MUTED = "#6A6489"
        const val ACCENT = "#6744F4"
        const val RING_TRACK = "#E4DCFB"
        const val DIAL_SURFACE = "#F3EDF9"
        const val LABEL_SURFACE = "#F0E9D9"
    }

    fun create(json: JSONObject, sizePx: Int, drawCenter: Boolean = true,
        stargazer: Boolean = false, rabbit: Boolean = false): Bitmap {
        val bmp = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val cx = sizePx / 2f
        val cy = sizePx / 2f
        val scale = sizePx / REFERENCE_SIZE
        val orbitRadius = sizePx * RADIUS_FACTOR
        val segmentStroke = 11f * scale
        val trackStroke = 9f * scale

        val step = max(2f, sizePx / 46f)
        val plate = pixelDisk(cx, cy, sizePx * 0.48f, step)
        canvas.drawPath(
            plate,
            Paint().apply {
                color = Color.parseColor(if (stargazer) "#0A3446"
                    else if (rabbit) "#FFE3D0" else Tokens.DIAL_SURFACE)
                isAntiAlias = false
            },
        )
        canvas.drawPath(
            plate,
            Paint().apply {
                color = Color.parseColor(if (stargazer) "#081F36"
                    else if (rabbit) "#493330" else Tokens.TEXT_PRIMARY)
                style = Paint.Style.STROKE
                strokeWidth = max(2f, 1.5f * sizePx / 104f)
                isAntiAlias = false
            },
        )
        canvas.drawPath(
            pixelDisk(cx, cy, sizePx * 0.335f, step),
            Paint().apply { color = Color.parseColor(
                if (rabbit) "#FFFCF3" else Tokens.SURFACE); isAntiAlias = false },
        )

        val oval = RectF(cx - orbitRadius, cy - orbitRadius, cx + orbitRadius, cy + orbitRadius)
        canvas.drawArc(
            oval, -90f, 360f, false,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor(if (stargazer) "#1D6A7C"
                    else if (rabbit) "#C5E4CA" else Tokens.RING_TRACK)
                style = Paint.Style.STROKE
                strokeWidth = trackStroke
                strokeCap = Paint.Cap.ROUND
            },
        )

        drawHourTicks(canvas, cx, cy, orbitRadius, trackStroke, scale, stargazer)
        drawHourLabels(canvas, cx, cy, sizePx.toFloat(), stargazer)
        drawSegments(canvas, json, oval, segmentStroke)
        drawNowPointer(canvas, json, cx, cy, orbitRadius, scale, stargazer, rabbit)
        if (drawCenter) drawCenterTime(canvas, json, cx, cy, scale, stargazer)

        return bmp
    }

    private fun pixelDisk(cx: Float, cy: Float, radius: Float, step: Float): Path {
        val path = Path()
        val rows = (radius / step).toInt() + 1
        val right = mutableListOf<Pair<Float, Float>>()
        val left = mutableListOf<Pair<Float, Float>>()
        for (i in -rows until rows) {
            val y = i * step
            val middle = y + step / 2f
            val half = ((sqrt(max(0f, radius * radius - middle * middle)) / step) + 0.5f).toInt() * step
            if (half <= 0f) continue
            right.add((cx + half) to (cy + y))
            right.add((cx + half) to (cy + y + step))
            left.add((cx - half) to (cy + y))
            left.add((cx - half) to (cy + y + step))
        }
        if (right.isEmpty()) return path
        path.moveTo(right.first().first, right.first().second)
        for (point in right.drop(1) + left.reversed()) path.lineTo(point.first, point.second)
        path.close()
        return path
    }

    private fun drawHourTicks(
        canvas: Canvas,
        cx: Float,
        cy: Float,
        orbitRadius: Float,
        trackStroke: Float,
        scale: Float,
        stargazer: Boolean,
    ) {
        for (hour in 0 until 24 step 4) {
            val angle = minutesToRad(hour * 60.0)
            val isMajor = hour % 12 == 0
            val tickLength = (if (isMajor) 9f else 6f) * scale
            val base = orbitRadius - trackStroke / 2f - 7f * scale
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor(if (stargazer) "#BCE4E8" else Tokens.TEXT_MUTED)
                alpha = if (stargazer) (if (isMajor) 180 else 110)
                    else (if (isMajor) 87 else 46)
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

    private fun drawHourLabels(canvas: Canvas, cx: Float, cy: Float, size: Float,
        stargazer: Boolean) {
        val offset = size * 0.445f
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(if (stargazer) "#E0F2F0" else Tokens.TEXT_PRIMARY)
            textSize = size * 0.085f
            typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText("00", cx, cy - offset + paint.textSize * 0.35f, paint)
        canvas.drawText("06", cx + offset, cy + paint.textSize * 0.35f, paint)
        canvas.drawText("12", cx, cy + offset + paint.textSize * 0.35f, paint)
        canvas.drawText("18", cx - offset, cy + paint.textSize * 0.35f, paint)
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
        stargazer: Boolean,
        rabbit: Boolean,
    ) {
        val ptr = json.optDouble("pointerAngleRad", -PI / 2)
        val px = (cx + cos(ptr) * (orbitRadius + 4f * scale)).toFloat()
        val py = (cy + sin(ptr) * (orbitRadius + 4f * scale)).toFloat()

        canvas.drawLine(
            cx, cy, px, py,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor(if (stargazer) "#F4C430"
                    else if (rabbit) "#DB665E" else Tokens.ACCENT)
                alpha = 128
                strokeWidth = 1.5f * scale
            },
        )
        val outer = 12f * scale
        val inner = 8f * scale
        canvas.drawRect(px - outer / 2, py - outer / 2, px + outer / 2, py + outer / 2,
            Paint().apply { color = Color.parseColor(Tokens.SURFACE); isAntiAlias = false })
        canvas.drawRect(px - inner / 2, py - inner / 2, px + inner / 2, py + inner / 2,
            Paint().apply {
                color = Color.parseColor(if (stargazer) "#F4C430"
                    else if (rabbit) "#DB665E" else Tokens.ACCENT)
                isAntiAlias = false
            })
    }

    private fun drawCenterTime(
        canvas: Canvas,
        json: JSONObject,
        cx: Float,
        cy: Float,
        scale: Float,
        stargazer: Boolean,
    ) {
        val hour = json.optInt("currentTimeHour")
        val minute = json.optInt("currentTimeMinute")
        val timePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(Tokens.TEXT_PRIMARY)
            textSize = 30f * scale
            typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        canvas.drawText("%02d:%02d".format(hour, minute), cx, cy + 2f * scale, timePaint)

        val label = json.optString("centerTimeLabel", "지금")
        val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor(if (stargazer) "#476275" else Tokens.TEXT_MUTED)
            textSize = 12f * scale
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        val labelWidth = labelPaint.measureText(label) + 12f * scale
        val box = RectF(cx - labelWidth / 2, cy + 8f * scale,
            cx + labelWidth / 2, cy + 26f * scale)
        canvas.drawRect(box, Paint().apply {
            color = Color.parseColor(if (stargazer) "#FFE295" else Tokens.LABEL_SURFACE)
        })
        canvas.drawRect(box, Paint().apply {
            color = Color.parseColor(if (stargazer) "#476275" else Tokens.TEXT_MUTED)
            style = Paint.Style.STROKE
            strokeWidth = 0.7f * scale
        })
        canvas.drawText(label, cx, cy + 21f * scale, labelPaint)
    }

    private fun minutesToRad(minutes: Double): Double =
        minutes / MIN_PER_DAY * (2 * PI) - PI / 2
}
