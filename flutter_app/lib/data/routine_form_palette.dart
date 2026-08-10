import 'package:flutter/material.dart';

import '../theme/routine_palette.dart';

/// 루틴 색상 선택 — Home 세그먼트와 동일 팔레트
const routineFormPaletteColors = RoutinePalette.colors;

/// JSON·저장소에서 온 부호 있는 int와 팔레트 [Color] 비교를 맞춘다.
int routineColorArgbNormalize(int value) =>
    RoutinePalette.normalizeValue(value);
