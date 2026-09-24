import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 정적인 장식은 터치와 스크린리더 대상에서 제외한다.
class PixelDecoration extends StatelessWidget {
  const PixelDecoration({super.key, required this.asset, required this.size});
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Image.asset(
          'assets/decorations/$asset.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          cacheWidth: 256,
          filterQuality: FilterQuality.none,
          excludeFromSemantics: true,
        ),
      );
}

/// 푸들 정원 팩의 단독 잎. 같은 자산을 돌리고 뒤집어 반복감만 줄인다.
class GardenLeaf extends StatelessWidget {
  const GardenLeaf({
    super.key,
    this.size = 24,
    this.angle = 0,
    this.mirror = false,
  });

  final double size;
  final double angle;
  final bool mirror;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Transform.flip(
          flipX: mirror,
          child: PixelDecoration(asset: 'garden-leaf', size: size),
        ),
      );
}

/// 원판 바깥 네 모서리만 사용해 시간·눈금·루틴 구간을 가리지 않는다.
class DecoratedTimetable extends StatelessWidget {
  const DecoratedTimetable({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          child,
          const Positioned(
              left: 0,
              bottom: 0,
              child: PixelDecoration(asset: 'plant', size: 54)),
          const Positioned(
              right: 0,
              bottom: 0,
              child: PixelDecoration(asset: 'sleeping-cat', size: 64)),
          const Positioned(
              left: 0,
              top: 22,
              child: IgnorePointer(
                  child: ExcludeSemantics(
                      child: CustomPaint(
                          size: Size(32, 20), painter: _CloudPainter())))),
          const Positioned(
              right: 6,
              top: 34,
              child: IgnorePointer(
                  child: ExcludeSemantics(
                      child: CustomPaint(
                          size: Size(12, 12),
                          painter: _SparkPainter(AppColors.decorationSpark))))),
        ],
      );
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(2, 18)
      ..lineTo(2, 10)
      ..lineTo(8, 10)
      ..lineTo(8, 4)
      ..lineTo(18, 4)
      ..lineTo(18, 8)
      ..lineTo(24, 8)
      ..lineTo(24, 12)
      ..lineTo(30, 12)
      ..lineTo(30, 18)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.decorationCream);
    canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.decorationOutline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..isAntiAlias = false);
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) => false;
}

/// 온보딩·알림 화면의 구름 장식.
class PixelCloud extends StatelessWidget {
  const PixelCloud({super.key, this.width = 32});

  final double width;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: CustomPaint(
            size: Size(width, width * 0.62),
            painter: const _CloudPainter(),
          ),
        ),
      );
}

/// 십자 반짝임.
class PixelSpark extends StatelessWidget {
  const PixelSpark({
    super.key,
    this.size = 12,
    this.color = AppColors.decorationSpark,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: CustomPaint(
            size: Size.square(size),
            painter: _SparkPainter(color),
          ),
        ),
      );
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.color);

  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    canvas.drawRect(const Rect.fromLTWH(5, 0, 2, 12), paint);
    canvas.drawRect(const Rect.fromLTWH(0, 5, 12, 2), paint);
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) => oldDelegate.color != color;
}
