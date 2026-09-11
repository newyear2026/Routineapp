/// 루틴 목록·폼에서 쓰는 픽셀 아이콘 식별자.
///
/// 예전에 쓰던 [Routine.iconEmoji]는 저장 호환만 유지하고 화면에 그리지 않는다.
enum RoutineIconId {
  sun,
  dumbbell,
  breakfast,
  book,
  bowl,
  coffee,
  utensils,
  moon,
  music,
  plant,
  bag,
  paw,
  laptop;

  static const pickerOrder = <RoutineIconId>[
    coffee,
    dumbbell,
    book,
    music,
    plant,
    bag,
    sun,
    breakfast,
    utensils,
    moon,
    laptop,
    paw,
    bowl,
  ];

  static RoutineIconId parse(String? raw) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return RoutineIconId.coffee;
  }

  static RoutineIconId fromCatalogId(String catalogId) => switch (catalogId) {
        'wake' => RoutineIconId.sun,
        'exercise' => RoutineIconId.dumbbell,
        'breakfast' => RoutineIconId.breakfast,
        'study' => RoutineIconId.book,
        'lunch' => RoutineIconId.bowl,
        'rest' => RoutineIconId.coffee,
        'dinner' => RoutineIconId.utensils,
        'sleep' => RoutineIconId.moon,
        _ => RoutineIconId.coffee,
      };

  /// 저장된 데이터에 [Routine.iconId]가 없을 때 id·제목으로 고른다.
  static RoutineIconId guess({String id = '', String title = ''}) {
    final s = '${id.toLowerCase()} ${title.toLowerCase()}';
    if (RegExp(r'wake|기상|sunrise').hasMatch(s)) return RoutineIconId.sun;
    if (RegExp(r'exercise|gym|운동|dumbbell').hasMatch(s)) {
      return RoutineIconId.dumbbell;
    }
    if (RegExp(r'breakfast|아침 식사|아침식사|toast').hasMatch(s)) {
      return RoutineIconId.breakfast;
    }
    if (RegExp(r'lunch|점심').hasMatch(s)) return RoutineIconId.bowl;
    if (RegExp(r'dinner|저녁').hasMatch(s)) return RoutineIconId.utensils;
    if (RegExp(r'sleep|취침|bed').hasMatch(s)) return RoutineIconId.moon;
    if (RegExp(r'study|read|독서|공부|book').hasMatch(s)) {
      return RoutineIconId.book;
    }
    if (RegExp(r'focus|work|집중|laptop').hasMatch(s)) {
      return RoutineIconId.laptop;
    }
    if (RegExp(r'rest|break|휴식|coffee').hasMatch(s)) {
      return RoutineIconId.coffee;
    }
    if (RegExp(r'music|음악').hasMatch(s)) return RoutineIconId.music;
    if (RegExp(r'plant|산책').hasMatch(s)) return RoutineIconId.plant;
    if (RegExp(r'bag|출퇴근').hasMatch(s)) return RoutineIconId.bag;
    if (RegExp(r'paw|pet|산책').hasMatch(s)) return RoutineIconId.paw;
    return RoutineIconId.coffee;
  }
}
