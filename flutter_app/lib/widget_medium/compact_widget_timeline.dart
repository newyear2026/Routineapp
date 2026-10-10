import 'package:flutter/material.dart';

import '../theme/app_pixel_style.dart';
import 'widget_timeline_item.dart';

/// Three equally spaced milestones. The connecting line represents elapsed time.
class CompactWidgetTimeline extends StatelessWidget {
  const CompactWidgetTimeline(
      {super.key,
      required this.items,
      required this.nowEpochMs,
      required this.accent,
      required this.ink,
      required this.muted});

  final List<WidgetTimelineItem> items;
  final int nowEpochMs;
  final Color accent;
  final Color ink;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final visible = items.take(3).toList();
    return SizedBox(
        height: 56,
        child: Column(children: [
          SizedBox(
              height: 16,
              width: double.infinity,
              child: CustomPaint(
                  painter: _TimelineTrack(visible, nowEpochMs, accent, muted))),
          const SizedBox(height: 4),
          Row(children: [
            for (final (index, item) in visible.indexed)
              Expanded(
                  flex: visible.length == 3 && index == 1 ? 3 : 1,
                  child: Column(children: [
                    Text(item.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: ink)),
                    const SizedBox(height: 2),
                    Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            color: nowEpochMs >= item.startEpochMs
                                ? accent
                                : muted)),
                  ]))
          ]),
        ]));
  }
}

class _TimelineTrack extends CustomPainter {
  const _TimelineTrack(this.items, this.now, this.accent, this.muted);
  final List<WidgetTimelineItem> items;
  final int now;
  final Color accent;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 3;
    double x(int i) =>
        size.width *
        (items.length == 3 ? 0.1 + 0.4 * i : (i + 0.5) / items.length);
    for (var i = 0; i < items.length - 1; i++) {
      canvas.drawLine(Offset(x(i), 8), Offset(x(i + 1), 8),
          paint..color = muted.withValues(alpha: 0.25));
      final span = items[i + 1].startEpochMs - items[i].startEpochMs;
      final progress = span <= 0
          ? (now >= items[i].startEpochMs ? 1.0 : 0.0)
          : ((now - items[i].startEpochMs) / span).clamp(0.0, 1.0);
      if (progress > 0) {
        canvas.drawLine(
            Offset(x(i), 8),
            Offset(x(i) + (x(i + 1) - x(i)) * progress, 8),
            paint..color = accent);
      }
    }
    for (var i = 0; i < items.length; i++) {
      final rect =
          Rect.fromCenter(center: Offset(x(i), 8), width: 14, height: 14);
      final shape = AppPixelStyle.shape(
          color: Colors.white, width: 1.5, step: 2, steps: 2);
      canvas.drawPath(
          shape.getOuterPath(rect),
          paint
            ..style = PaintingStyle.fill
            ..color = now >= items[i].startEpochMs
                ? accent
                : Color.lerp(accent, Colors.white, 0.68)!);
      shape.paint(canvas, rect);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineTrack old) =>
      old.items != items ||
      old.now != now ||
      old.accent != accent ||
      old.muted != muted;
}
