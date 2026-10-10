import 'package:flutter/material.dart';

import 'squirrel_time_of_day.dart';

enum SquirrelForestMotion { full, subtle, none }

/// 다람쥐 팩의 숲을 화면 상단에 고정하고 본문으로 자연스럽게 흐리게 한다.
class SquirrelForestBackdrop extends StatelessWidget {
  const SquirrelForestBackdrop({
    super.key,
    required this.timeOfDay,
    this.motion = SquirrelForestMotion.full,
  });

  final SquirrelTimeOfDay timeOfDay;
  final SquirrelForestMotion motion;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, 0.53, 1],
          ).createShader(bounds),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: Image.asset(
                  timeOfDay.headerAsset,
                  key: ValueKey(timeOfDay),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.none,
                  excludeFromSemantics: true,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      if (timeOfDay == SquirrelTimeOfDay.night)
                        const Color(0x88101C43)
                      else
                        const Color(0xA6FCF7EB),
                      if (timeOfDay == SquirrelTimeOfDay.night)
                        const Color(0x33101C43)
                      else
                        const Color(0x4DFCF7EB),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.42, 0.75],
                  ),
                ),
              ),
              if (motion != SquirrelForestMotion.none)
                SquirrelAtmosphere(
                  timeOfDay: timeOfDay,
                  area: SquirrelAtmosphereArea.header,
                  subtle: motion == SquirrelForestMotion.subtle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
