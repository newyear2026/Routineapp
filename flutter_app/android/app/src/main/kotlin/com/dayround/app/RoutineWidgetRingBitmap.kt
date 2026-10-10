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
 * 색은 팩마다 [RoutineWidgetSkin.RingColors]가 정한다. 기본값은
 * res/values/widget_colors.xml과 같고 기준은 `lib/widget_medium/widget_theme.dart`이다.
 */
object RoutineWidgetRingBitmap {

    private const val MIN_PER_DAY = 24 * 60
    private const val REFERENCE_SIZE = 150f
    private const val RADIUS_FACTOR = 0.395f
    private const val GAP_RAD = 0.05

    private object Tokens {
        const val SURFACE = "#FFFFFF"
        const val TEXT_PRIMARY = "#221C42"
    }

    /**
     * [labelsInside]는 4×2 위젯용이다. 링이 커서 시간 숫자를 링 안쪽에 두고,
     * 숫자와 겹치는 00·12시 틱은 그리지 않는다.
     */
    fun create(json: JSONObject, sizePx: Int, drawCenter: Boolean = true,
        colors: RoutineWidgetSkin.RingColors = RoutineWidgetSkin.default.ring,
        labelsInside: Boolean = false): Bitmap {
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
                color = colors.dial
                isAntiAlias = false
            },
        )
        canvas.drawPath(
            plate,
            Paint().apply {
                color = colors.dialOutline
                style = Paint.Style.STROKE
                strokeWidth = max(2f, 1.5f * sizePx / 104f)
                isAntiAlias = false
            },
        )
        canvas.drawPath(
            pixelDisk(cx, cy, sizePx * 0.335f, step),
            Paint().apply { color = colors.surface; isAntiAlias = false },
        )

        val oval = RectF(cx - orbitRadius, cy - orbitRadius, cx + orbitRadius, cy + orbitRadius)
        canvas.drawArc(
            oval, -90f, 360f, false,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = colors.track
                style = Paint.Style.STROKE
                strokeWidth = trackStroke
                strokeCap = Paint.Cap.ROUND
            },
        )

        drawHourTicks(canvas, cx, cy, orbitRadius, trackStroke, scale, colors, labelsInside)
        drawSegments(canvas, json, oval, segmentStroke)
        // 구간 호보다 나중에 그린다. 먼저 그리면 18시·00시 숫자가 호에 가린다.
        drawHourLabels(canvas, cx, cy, sizePx.toFloat(), colors, labelsInside)
        drawNowPointer(canvas, json, cx, cy, orbitRadius, scale, colors,
            // 큰 링은 가운데에 남은 시간 글자가 있어 바늘을 링 가까이에서만 그린다.
            innerFraction = if (labelsInside) 0.62f else 0f)
        if (drawCenter) drawCenterTime(canvas, json, cx, cy, scale, colors)

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
        colors: RoutineWidgetSkin.RingColors,
        labelsInside: Boolean,
    ) {
        for (hour in 0 until 24 step 4) {
            val isMajor = hour % 12 == 0
            if (labelsInside && isMajor) continue
            val angle = minutesToRad(hour * 60.0)
            val tickLength = (if (isMajor) 9f else 6f) * scale
            val base = orbitRadius - trackStroke / 2f - 7f * scale
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = colors.tick
                alpha = if (isMajor) colors.tickAlphaMajor else colors.tickAlphaMinor
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
        colors: RoutineWidgetSkin.RingColors, labelsInside: Boolean) {
        val offset = size * if (labelsInside) 0.255f else 0.43f
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = colors.hourLabel
            textSize = size * if (labelsInside) 0.062f else 0.085f
            typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        // 테두리 위의 숫자는 판 색 바탕을 깔아 테두리 선이 글자를 가로지르지 않게 한다.
        val backing = if (labelsInside) null else Paint().apply { color = colors.dial }
        val halfW = paint.measureText("00") / 2f + size * 0.01f
        val halfH = paint.textSize * 0.5f
        for ((label, x, y) in listOf(
            Triple("00", cx, cy - offset), Triple("06", cx + offset, cy),
            Triple("12", cx, cy + offset), Triple("18", cx - offset, cy))) {
            if (backing != null) canvas.drawRect(x - halfW, y - halfH, x + halfW, y + halfH, backing)
            canvas.drawText(label, x, y + paint.textSize * 0.35f, paint)
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
        colors: RoutineWidgetSkin.RingColors,
        innerFraction: Float,
    ) {
        val ptr = json.optDouble("pointerAngleRad", -PI / 2)
        val px = (cx + cos(ptr) * (orbitRadius + 4f * scale)).toFloat()
        val py = (cy + sin(ptr) * (orbitRadius + 4f * scale)).toFloat()

        canvas.drawLine(
            (cx + cos(ptr) * orbitRadius * innerFraction).toFloat(),
            (cy + sin(ptr) * orbitRadius * innerFraction).toFloat(),
            px, py,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = colors.pointer
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
                color = colors.pointer
                isAntiAlias = false
            })
    }

    private fun drawCenterTime(
        canvas: Canvas,
        json: JSONObject,
        cx: Float,
        cy: Float,
        scale: Float,
        colors: RoutineWidgetSkin.RingColors,
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
            color = colors.centerLabelInk
            textSize = 12f * scale
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            textAlign = Paint.Align.CENTER
        }
        val labelWidth = labelPaint.measureText(label) + 12f * scale
        val box = RectF(cx - labelWidth / 2, cy + 8f * scale,
            cx + labelWidth / 2, cy + 26f * scale)
        canvas.drawRect(box, Paint().apply {
            color = colors.centerLabelSurface
        })
        canvas.drawRect(box, Paint().apply {
            color = colors.centerLabelInk
            style = Paint.Style.STROKE
            strokeWidth = 0.7f * scale
        })
        canvas.drawText(label, cx, cy + 21f * scale, labelPaint)
    }

    private fun minutesToRad(minutes: Double): Double =
        minutes / MIN_PER_DAY * (2 * PI) - PI / 2
}
