package com.dayround.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import org.json.JSONObject
import java.util.Calendar
import kotlin.math.max

/** Pixel-art variants composed for a single 4×1 launcher row. */
object RoutineWidgetVariantBitmap {
    private const val WIDTH = 768
    private const val HEIGHT = 240
    private val navy = Color.rgb(25, 19, 68)
    private val purple = Color.rgb(100, 58, 246)
    private val muted = Color.rgb(107, 100, 146)

    fun create(
        context: Context,
        style: String,
        garden: Boolean,
        stargazer: Boolean,
        rabbit: Boolean,
        state: JSONObject,
        status: String,
        title: String,
        hint: String,
        nextLabel: String,
        nextTitle: String,
        nextTime: String,
        clock: Calendar = Calendar.getInstance(),
    ): Bitmap {
        val result = Bitmap.createBitmap(WIDTH, HEIGHT, Bitmap.Config.RGB_565)
        val canvas = Canvas(result)
        if (stargazer) {
            drawStargazer(canvas, context, style, state, status, title, hint,
                nextLabel, nextTitle, nextTime, clock)
            return result
        }
        if (rabbit) {
            drawRabbit(canvas, context, style, state, status, title, hint,
                nextLabel, nextTitle, nextTime, clock)
            return result
        }
        drawBackground(canvas, context, garden)
        if (style == "timeline") {
            drawTimeline(canvas, context, garden, state, status, title, hint,
                nextLabel, nextTitle, nextTime, clock)
        } else {
            drawCards(canvas, context, garden, status, title, hint,
                nextLabel, nextTitle, nextTime)
        }
        return result
    }

    private fun drawRabbit(
        canvas: Canvas, context: Context, style: String, state: JSONObject,
        status: String, title: String, hint: String, nextLabel: String,
        nextTitle: String, nextTime: String, clock: Calendar,
    ) {
        val ink = Color.rgb(73, 51, 48)
        val coral = Color.rgb(197, 81, 74)
        val muted = Color.rgb(128, 100, 92)
        canvas.drawColor(Color.rgb(255, 232, 208))
        canvas.drawRect(0f, 190f, 768f, 240f,
            Paint().apply { color = Color.rgb(180, 221, 185) })
        canvas.drawCircle(640f, 91f, 45f,
            Paint().apply { color = Color.rgb(255, 247, 219) })
        if (style == "timeline") {
            drawBadge(canvas, status, 48f, 31f, false, rabbit = true)
            drawFitted(canvas, title, 48f, 122f, 407f, 60f, 30f, ink)
            drawFitted(canvas, hint, 48f, 177f, 410f, 40f, 23f, coral)
            drawResource(canvas, context, R.drawable.widget_variant_rabbit,
                RectF(464f, 20f, 633f, 188f))
            if (nextTitle.isNotBlank()) {
                val next = listOf(nextLabel, nextTitle, nextTime)
                    .filter { it.isNotBlank() }.joinToString(" ")
                drawFitted(canvas, next, 482f, 216f, 240f, 20f, 14f, ink)
            }
            drawRuler(canvas, state, clock)
        } else {
            drawPixelPanel(canvas, RectF(31f, 51f, 550f, 211f),
                Color.rgb(255, 251, 239), Color.rgb(255, 227, 207))
            drawPixelPanel(canvas, RectF(558f, 51f, 738f, 211f),
                Color.rgb(246, 255, 236), Color.rgb(207, 234, 200))
            drawResource(canvas, context, R.drawable.widget_variant_rabbit,
                RectF(49f, 49f, 207f, 205f))
            drawBadge(canvas, status, 214f, 65f, false, rabbit = true)
            drawFitted(canvas, title, 212f, 140f, 325f, 50f, 27f, ink)
            drawFitted(canvas, hint, 212f, 191f, 325f, 37f, 20f, coral)
            drawFitted(canvas, nextLabel, 648f, 102f, 160f, 25f, 17f, muted,
                Paint.Align.CENTER)
            drawFitted(canvas, nextTitle, 648f, 153f, 160f, 39f, 20f, ink,
                Paint.Align.CENTER)
            drawFitted(canvas, nextTime, 648f, 200f, 160f, 32f, 19f, coral,
                Paint.Align.CENTER, Typeface.MONOSPACE)
        }
    }

    private fun drawStargazer(
        canvas: Canvas, context: Context, style: String, state: JSONObject,
        status: String, title: String, hint: String, nextLabel: String,
        nextTitle: String, nextTime: String, clock: Calendar,
    ) {
        val cream = Color.rgb(255, 249, 234)
        val pale = Color.rgb(214, 230, 237)
        val gold = Color.rgb(244, 196, 48)
        canvas.drawColor(Color.rgb(11, 61, 74))
        val star = Paint().apply { color = gold; isAntiAlias = false }
        for ((x, y) in listOf(94f to 26f, 308f to 18f, 573f to 31f,
            704f to 85f, 421f to 197f)) {
            canvas.drawRect(x, y, x + 4f, y + 4f, star)
        }
        if (style == "timeline") {
            drawBadge(canvas, status, 48f, 31f, false, true)
            drawFitted(canvas, title, 48f, 122f, 407f, 60f, 30f, cream)
            drawFitted(canvas, hint, 48f, 177f, 410f, 40f, 23f, gold)
            drawResource(canvas, context, R.drawable.widget_stargazer,
                RectF(464f, 45f, 633f, 187f))
            if (nextTitle.isNotBlank()) {
                val next = listOf(nextLabel, nextTitle, nextTime)
                    .filter { it.isNotBlank() }.joinToString(" ")
                drawFitted(canvas, next, 482f, 199f, 240f, 20f, 14f, pale)
            }
            drawRuler(canvas, state, clock, true)
        } else {
            drawStargazerPanel(canvas, RectF(31f, 51f, 550f, 211f))
            drawStargazerPanel(canvas, RectF(558f, 51f, 738f, 211f))
            drawResource(canvas, context, R.drawable.widget_stargazer,
                RectF(49f, 76f, 207f, 205f))
            drawBadge(canvas, status, 214f, 65f, false, true)
            drawFitted(canvas, title, 212f, 140f, 325f, 50f, 27f, cream)
            drawFitted(canvas, hint, 212f, 191f, 325f, 37f, 20f, gold)
            drawFitted(canvas, nextLabel, 648f, 102f, 160f, 25f, 17f, pale,
                Paint.Align.CENTER)
            drawFitted(canvas, nextTitle, 648f, 153f, 160f, 39f, 20f, cream,
                Paint.Align.CENTER)
            drawFitted(canvas, nextTime, 648f, 200f, 160f, 32f, 19f, gold,
                Paint.Align.CENTER, Typeface.MONOSPACE)
        }
    }

    private fun drawStargazerPanel(canvas: Canvas, bounds: RectF) {
        canvas.drawRect(bounds, Paint().apply { color = Color.rgb(102, 137, 149) })
        canvas.drawRect(RectF(bounds.left + 3, bounds.top + 3,
            bounds.right - 3, bounds.bottom - 3),
            Paint().apply { color = Color.rgb(20, 72, 85) })
    }

    private fun drawBackground(canvas: Canvas, context: Context, garden: Boolean) {
        val resource = if (garden) R.drawable.widget_bg_timeline_poodle
            else R.drawable.widget_bg_timeline_cat
        val background = BitmapFactory.decodeResource(context.resources, resource) ?: return
        val paint = Paint().apply { isFilterBitmap = false; isAntiAlias = false }
        // The original art stays pixel sharp: keep its upper scene and lower border at 1:1.
        canvas.drawBitmap(background, Rect(0, 0, WIDTH, 209),
            RectF(0f, 0f, WIDTH.toFloat(), 209f), paint)
        canvas.drawBitmap(background, Rect(0, 470, WIDTH, 512),
            RectF(0f, 209f, WIDTH.toFloat(), HEIGHT.toFloat()), paint)
        background.recycle()
    }

    private fun drawTimeline(
        canvas: Canvas,
        context: Context,
        garden: Boolean,
        state: JSONObject,
        status: String,
        title: String,
        hint: String,
        nextLabel: String,
        nextTitle: String,
        nextTime: String,
        clock: Calendar,
    ) {
        drawBadge(canvas, status, 48f, 31f, garden)
        drawFitted(canvas, title, 48f, 122f, 407f, 60f, 30f, navy)
        drawHint(canvas, hint, 48f, 177f, 410f, 49f)

        val pet = if (garden) R.drawable.widget_variant_poodle else R.drawable.widget_variant_cat
        val bounds = if (garden) RectF(485f, 39f, 618f, 186f)
            else RectF(464f, 45f, 633f, 187f)
        drawResource(canvas, context, pet, bounds)
        if (nextTitle.isNotBlank()) {
            drawClockIcon(canvas, 466f, 194f, 9f)
            val next = listOf(nextLabel, nextTitle, nextTime)
                .filter { it.isNotBlank() }.joinToString(" ")
            drawFitted(canvas, next, 482f, 199f, 240f, 20f, 14f, navy)
        }
        drawRuler(canvas, state, clock)
    }

    private fun drawCards(
        canvas: Canvas,
        context: Context,
        garden: Boolean,
        status: String,
        title: String,
        hint: String,
        nextLabel: String,
        nextTitle: String,
        nextTime: String,
    ) {
        drawPixelPanel(canvas, RectF(31f, 51f, 550f, 211f),
            Color.rgb(255, 249, 234), Color.rgb(255, 229, 196))
        drawPixelPanel(canvas, RectF(558f, 51f, 738f, 211f),
            if (garden) Color.rgb(218, 250, 235) else Color.rgb(237, 227, 255),
            if (garden) Color.rgb(176, 227, 207) else Color.rgb(212, 194, 246))

        val pet = if (garden) R.drawable.widget_variant_poodle else R.drawable.widget_variant_cat
        val bounds = if (garden) RectF(61f, 73f, 195f, 205f)
            else RectF(49f, 76f, 207f, 205f)
        drawResource(canvas, context, pet, bounds)
        drawBadge(canvas, status, 214f, 65f, garden)
        drawFitted(canvas, title, 212f, 140f, 325f, 50f, 27f, navy)
        drawHint(canvas, hint, 212f, 191f, 325f, 47f)

        if (nextTitle.isNotBlank()) {
            val icon = if (garden) R.drawable.widget_daisy else R.drawable.widget_moon
            drawResource(canvas, context, icon, RectF(585f, 68f, 632f, 113f))
            drawFitted(canvas, nextLabel, 674f, 102f, 110f, 25f, 17f, muted,
                Paint.Align.CENTER)
            drawFitted(canvas, nextTitle, 648f, 153f, 160f, 39f, 20f, navy,
                Paint.Align.CENTER)
            val divider = Paint().apply {
                color = if (garden) Color.rgb(161, 207, 188) else Color.rgb(200, 189, 238)
                strokeWidth = 3f
                isAntiAlias = false
            }
            canvas.drawLine(590f, 164f, 708f, 164f, divider)
            drawFitted(canvas, nextTime, 648f, 200f, 160f, 32f, 19f, navy,
                Paint.Align.CENTER, Typeface.MONOSPACE)
        }
    }

    private fun drawPixelPanel(canvas: Canvas, bounds: RectF, fillColor: Int, innerColor: Int) {
        fun shape(inset: Float): Path {
            val left = bounds.left + inset
            val top = bounds.top + inset
            val right = bounds.right - inset
            val bottom = bounds.bottom - inset
            return Path().apply {
                moveTo(left + 16f, top)
                lineTo(right - 16f, top)
                lineTo(right - 16f, top + 6f)
                lineTo(right - 7f, top + 6f)
                lineTo(right - 7f, top + 15f)
                lineTo(right, top + 15f)
                lineTo(right, bottom - 15f)
                lineTo(right - 7f, bottom - 15f)
                lineTo(right - 7f, bottom - 6f)
                lineTo(right - 16f, bottom - 6f)
                lineTo(right - 16f, bottom)
                lineTo(left + 16f, bottom)
                lineTo(left + 16f, bottom - 6f)
                lineTo(left + 7f, bottom - 6f)
                lineTo(left + 7f, bottom - 15f)
                lineTo(left, bottom - 15f)
                lineTo(left, top + 15f)
                lineTo(left + 7f, top + 15f)
                lineTo(left + 7f, top + 6f)
                lineTo(left + 16f, top + 6f)
                close()
            }
        }
        canvas.drawPath(shape(0f), Paint().apply { color = navy; isAntiAlias = false })
        canvas.drawPath(shape(5f), Paint().apply { color = innerColor; isAntiAlias = false })
        canvas.drawPath(shape(8f), Paint().apply { color = fillColor; isAntiAlias = false })
    }

    private fun drawBadge(canvas: Canvas, status: String, x: Float, y: Float,
        garden: Boolean, stargazer: Boolean = false, rabbit: Boolean = false) {
        if (status.isBlank()) return
        val text = textPaint(if (stargazer) Color.rgb(18, 48, 65) else Color.WHITE, 24f)
        val width = (text.measureText(status) + 31f).coerceIn(78f, 175f)
        while (text.measureText(status) > width - 24f && text.textSize > 17f) {
            text.textSize -= 1f
        }
        val border = Paint().apply { color = navy; isAntiAlias = false }
        val fill = Paint().apply {
            color = if (stargazer) Color.rgb(244, 196, 48)
                else if (rabbit) Color.rgb(219, 102, 94)
                else if (garden) Color.rgb(4, 145, 152) else purple
            isAntiAlias = false
        }
        canvas.drawRect(x + 6f, y, x + width - 6f, y + 36f, border)
        canvas.drawRect(x, y + 6f, x + width, y + 30f, border)
        canvas.drawRect(x + 8f, y + 3f, x + width - 8f, y + 33f, fill)
        canvas.drawRect(x + 3f, y + 8f, x + width - 3f, y + 28f, fill)
        canvas.drawText(status, x + width / 2f - text.measureText(status) / 2f,
            y + 27f, text)
    }

    private fun drawHint(canvas: Canvas, fullHint: String, x: Float, baseline: Float,
        maxWidth: Float, maxSize: Float) {
        if (fullHint.isBlank()) return
        val firstDigit = fullHint.indexOfFirst { it.isDigit() }
        val hint = if (firstDigit < 0) fullHint else fullHint.substring(firstDigit)
        val lastSpace = hint.lastIndexOf(' ')
        val separateSuffix = lastSpace > 0 && hint.substring(0, lastSpace).any { it.isDigit() }
        val duration = if (separateSuffix) hint.substring(0, lastSpace) else hint
        val suffix = if (separateSuffix) hint.substring(lastSpace + 1) else ""
        val main = textPaint(purple, maxSize)
        val secondary = textPaint(muted, maxSize * 0.61f)
        while (main.measureText(duration) +
            (if (suffix.isBlank()) 0f else 8f + secondary.measureText(suffix)) > maxWidth &&
            main.textSize > 23f) {
            main.textSize -= 1f
            secondary.textSize = main.textSize * 0.61f
        }
        var shown = duration
        while (shown.length > 1 && main.measureText(shown) +
            (if (suffix.isBlank()) 0f else 8f + secondary.measureText(suffix)) > maxWidth) {
            shown = shown.dropLast(1)
        }
        if (shown != duration) shown += "…"
        canvas.drawText(shown, x, baseline, main)
        if (suffix.isNotBlank()) {
            canvas.drawText(suffix, x + main.measureText(shown) + 8f, baseline, secondary)
        }
    }

    private fun drawRuler(canvas: Canvas, state: JSONObject, clock: Calendar,
        stargazer: Boolean = false) {
        val left = 44f
        val right = 724f
        val top = 209f
        val bottom = 220f
        canvas.drawRect(left, top, right, bottom,
            Paint().apply { color = Color.rgb(224, 215, 251); isAntiAlias = false })
        val segments = state.optJSONArray("ringSegments")
        if (segments != null) for (i in 0 until segments.length()) {
            val item = segments.optJSONObject(i) ?: continue
            val start = item.optInt("startMinutesFromMidnight").coerceIn(0, 1440)
            val end = (start + item.optInt("sweepMinutes")).coerceIn(0, 1440)
            if (end <= start) continue
            var color = item.optInt("colorArgb")
            if (Color.alpha(color) == 0) color = color or (0xFF shl 24)
            val x1 = left + (right - left) * start / 1440f
            val x2 = max(x1 + 2f, left + (right - left) * end / 1440f)
            canvas.drawRect(x1, top + 1f, x2, bottom - 1f,
                Paint().apply { this.color = color; isAntiAlias = false })
        }
        canvas.drawRect(left, top, right, bottom, Paint().apply {
            color = if (stargazer) Color.rgb(214, 230, 237) else muted
            style = Paint.Style.STROKE; strokeWidth = 2f; isAntiAlias = false
        })
        val labels = textPaint(if (stargazer) Color.rgb(214, 230, 237) else muted,
            13f, Typeface.MONOSPACE)
        for (hour in 0..24 step 6) {
            val x = left + (right - left) * hour / 24f
            labels.textAlign = when (hour) {
                0 -> Paint.Align.LEFT
                24 -> Paint.Align.RIGHT
                else -> Paint.Align.CENTER
            }
            canvas.drawText("%02d".format(hour), x, 235f, labels)
        }
        val minute = clock.get(Calendar.HOUR_OF_DAY) * 60 + clock.get(Calendar.MINUTE)
        val markerX = left + (right - left) * minute / 1440f
        canvas.drawRect(markerX - 5f, top - 4f, markerX + 5f, bottom + 4f,
            Paint().apply { color = Color.WHITE; isAntiAlias = false })
        canvas.drawRect(markerX - 3f, top - 2f, markerX + 3f, bottom + 2f,
            Paint().apply { color = if (stargazer) Color.rgb(244, 196, 48) else purple
                isAntiAlias = false })
    }

    private fun drawClockIcon(canvas: Canvas, x: Float, y: Float, radius: Float) {
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = muted; style = Paint.Style.STROKE; strokeWidth = 3f
        }
        canvas.drawCircle(x, y, radius, paint)
        canvas.drawLine(x, y, x, y - 5f, paint)
        canvas.drawLine(x, y, x + 5f, y + 2f, paint)
    }

    private fun drawFitted(canvas: Canvas, value: String, x: Float, baseline: Float,
        maxWidth: Float, maxSize: Float, minSize: Float, color: Int,
        align: Paint.Align = Paint.Align.LEFT,
        typeface: Typeface = Typeface.DEFAULT_BOLD) {
        if (value.isBlank()) return
        val paint = textPaint(color, maxSize, typeface)
        paint.textAlign = align
        while (paint.measureText(value) > maxWidth && paint.textSize > minSize) {
            paint.textSize -= 1f
        }
        var fitted = value
        if (paint.measureText(fitted) > maxWidth) {
            while (fitted.length > 1 && paint.measureText("$fitted…") > maxWidth) {
                fitted = fitted.dropLast(1)
            }
            fitted += "…"
        }
        canvas.drawText(fitted, x, baseline, paint)
    }

    private fun textPaint(color: Int, size: Float, typeface: Typeface = Typeface.DEFAULT_BOLD) =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            this.color = color
            textSize = size
            this.typeface = typeface
            isSubpixelText = true
        }

    private fun drawResource(canvas: Canvas, context: Context, resId: Int, destination: RectF) {
        val bitmap = BitmapFactory.decodeResource(context.resources, resId) ?: return
        canvas.drawBitmap(bitmap, Rect(0, 0, bitmap.width, bitmap.height), destination,
            Paint().apply { isFilterBitmap = false; isAntiAlias = false })
        bitmap.recycle()
    }
}
