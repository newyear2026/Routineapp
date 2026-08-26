import 'package:flutter/material.dart';

import '../../application/services/exact_alarm_service.dart';
import '../../l10n/app_localizations.dart';
import '../ds/ds.dart';
import 'settings_list_items.dart';

/// 정확 알람 권한 진입점.
///
/// 이 권한은 앱이 켤 수 없고 시스템 설정에서만 바뀐다. 그래서 토글이 아니라
/// «상태 배지 + 화살표»로 두어 «다른 화면으로 간다»는 걸 드러낸다.
/// 사용자가 설정을 다녀오면 [didChangeAppLifecycleState]에서 상태를 다시 읽고,
/// 값이 바뀌었으면 [onChanged]로 알려 알림을 다시 예약하게 한다.
class ExactAlarmTile extends StatefulWidget {
  const ExactAlarmTile({
    super.key,
    this.service,
    this.onChanged,
  });

  final ExactAlarmService? service;

  /// 권한 상태가 실제로 달라졌을 때만 호출된다.
  final ValueChanged<bool>? onChanged;

  @override
  State<ExactAlarmTile> createState() => _ExactAlarmTileState();
}

class _ExactAlarmTileState extends State<ExactAlarmTile>
    with WidgetsBindingObserver {
  late final ExactAlarmService _service =
      widget.service ?? ExactAlarmService.instance;

  bool? _allowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final allowed = await _service.canScheduleExactAlarms();
    if (!mounted || allowed == _allowed) return;
    final isFirstRead = _allowed == null;
    setState(() => _allowed = allowed);
    if (!isFirstRead) widget.onChanged?.call(allowed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 첫 조회가 끝나기 전에는 상태를 단정하지 않는다.
    final allowed = _allowed;

    return SettingsNavigationTile(
      key: const Key('exact-alarm-tile'),
      icon: Icons.alarm_on_rounded,
      label: l10n.settingsExactAlarm,
      description: allowed == false
          ? l10n.settingsExactAlarmOff
          : l10n.settingsExactAlarmOn,
      statusLabel: allowed == null
          ? null
          : (allowed
              ? l10n.settingsExactAlarmStatusOn
              : l10n.settingsExactAlarmStatusOff),
      statusTone: allowed == true
          ? AppStatusBadgeTone.success
          : AppStatusBadgeTone.warning,
      onTap: _service.openSettings,
    );
  }
}
