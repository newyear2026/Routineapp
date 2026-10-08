package com.dayround.app

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path

/** Data visualization only; the adjacent time/title labels remain native TextViews. */
object RoutineWidgetTimelineTrack {
    fun create(starts: List<Long>, now: Long, width: Int, height: Int,
        accent: Int, muted: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        if (starts.isEmpty()) return bitmap
        val canvas = Canvas(bitmap)
        val scale = height / 16f
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { strokeWidth = 3f * scale }
        fun x(i: Int) = width * (if (starts.size == 3) 0.1f + 0.4f * i else (i + 0.5f) / starts.size)
        val y = height / 2f
        for (i in 0 until starts.lastIndex) {
            paint.color = (muted and 0x00FFFFFF) or (0x40 shl 24)
            canvas.drawLine(x(i), y, x(i + 1), y, paint)
            val span = starts[i + 1] - starts[i]
            val progress = if (span <= 0) { if (now >= starts[i]) 1f else 0f }
                else ((now - starts[i]).toFloat() / span).coerceIn(0f, 1f)
            if (progress > 0) {
                paint.color = accent
                canvas.drawLine(x(i), y, x(i) + (x(i + 1) - x(i)) * progress, y, paint)
            }
        }
        fun marker(cx: Float, radius: Float, color: Int) {
            val step = radius * 2 / 7f
            val p = Path().apply {
                moveTo(cx - radius + 2 * step, y - radius)
                lineTo(cx + radius - 2 * step, y - radius)
                lineTo(cx + radius - 2 * step, y - radius + step)
                lineTo(cx + radius - step, y - radius + step)
                lineTo(cx + radius - step, y - radius + 2 * step)
                lineTo(cx + radius, y - radius + 2 * step)
                lineTo(cx + radius, y + radius - 2 * step)
                lineTo(cx + radius - step, y + radius - 2 * step)
                lineTo(cx + radius - step, y + radius - step)
                lineTo(cx + radius - 2 * step, y + radius - step)
                lineTo(cx + radius - 2 * step, y + radius)
                lineTo(cx - radius + 2 * step, y + radius)
                lineTo(cx - radius + 2 * step, y + radius - step)
                lineTo(cx - radius + step, y + radius - step)
                lineTo(cx - radius + step, y + radius - 2 * step)
                lineTo(cx - radius, y + radius - 2 * step)
                lineTo(cx - radius, y - radius + 2 * step)
                lineTo(cx - radius + step, y - radius + 2 * step)
                lineTo(cx - radius + step, y - radius + step)
                lineTo(cx - radius + 2 * step, y - radius + step)
                close()
            }
            paint.color = color
            canvas.drawPath(p, paint)
        }
        val future = Color.rgb(
            (Color.red(accent) * 0.32 + 255 * 0.68).toInt(),
            (Color.green(accent) * 0.32 + 255 * 0.68).toInt(),
            (Color.blue(accent) * 0.32 + 255 * 0.68).toInt())
        for (i in starts.indices) {
            marker(x(i), 7f * scale, Color.WHITE)
            marker(x(i), 5.5f * scale, if (now >= starts[i]) accent else future)
        }
        return bitmap
    }
}
