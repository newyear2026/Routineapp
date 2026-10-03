import 'package:flutter/foundation.dart';

import '../../data/local/app_update_storage.dart';
import '../../domain/update/app_update_port.dart';
import '../services/app_version_service.dart';

enum UpdateCheckStatus { notChecked, upToDate, available, failed }

/// 앱 시작·복귀 때만 조회한다. 정상 확인 후 1시간, 실패 후 5분을 기다리며
/// 시간이 지나도 스스로 실행하는 타이머는 없다. 수동 확인은 간격을 무시한다.
///
/// 자동 팝업은 버전마다 한 번이며 이후에는 배너로 남는다. 배너를 닫으면
/// 이번 실행 동안만 숨긴다. 강제 업데이트는 없다.
class AppUpdates extends ChangeNotifier {
  AppUpdates({
    required AppUpdatePort port,
    Future<AppUpdateRecord> Function()? recordLoader,
    Future<void> Function(AppUpdateRecord)? recordSaver,
    DateTime Function()? now,
    AppVersionLoader versionLoader = loadAppVersion,
  })  : _port = port,
        _recordLoader = recordLoader ?? AppUpdateStorage.load,
        _recordSaver = recordSaver ?? AppUpdateStorage.save,
        _now = now ?? DateTime.now,
        _versionLoader = versionLoader;

  static const checkInterval = Duration(hours: 1);
  static const retryInterval = Duration(minutes: 5);

  final AppUpdatePort _port;
  final Future<AppUpdateRecord> Function() _recordLoader;
  final Future<void> Function(AppUpdateRecord) _recordSaver;
  final DateTime Function() _now;
  final AppVersionLoader _versionLoader;

  PendingUpdate? _pending;
  DateTime? _checkedAt;
  DateTime? _failedAt;
  int? _promptedVersionCode;
  int? _dismissedVersionCode;
  int? _installedBuild;
  bool _promptVisible = false;
  bool _bannerHidden = false;
  bool _checking = false;
  bool _loaded = false;
  bool _disposed = false;
  Future<PendingUpdate?>? _refreshing;
  Future<void> _saveQueue = Future<void>.value();

  PendingUpdate? get pending => _pending;
  bool get isChecking => _checking;
  bool get canCheck => _port.canCheck;

  UpdateCheckStatus get status {
    if (_failedAt != null) return UpdateCheckStatus.failed;
    if (_pending != null) return UpdateCheckStatus.available;
    if (_checkedAt != null) return UpdateCheckStatus.upToDate;
    return UpdateCheckStatus.notChecked;
  }

  bool get shouldPrompt =>
      _pending != null &&
      !_promptVisible &&
      _pending!.versionCode != _promptedVersionCode &&
      _pending!.versionCode != _dismissedVersionCode;

  bool get showBanner =>
      _pending != null && !_bannerHidden && !shouldPrompt && !_promptVisible;

  /// 홈에서 첫 확인을 시작한 뒤에만 앱 복귀 시 재확인한다.
  /// 스플래시·온보딩 중에는 조회하지 않는다.
  Future<PendingUpdate?> refreshOnResume() =>
      _loaded || _refreshing != null ? refresh() : Future.value(_pending);

  /// 기록을 불러오는 동안에도 동시 요청은 한 번으로 합친다.
  Future<PendingUpdate?> refresh({bool force = false}) {
    if (!canCheck || _disposed) return Future.value(_pending);
    return _refreshing ??=
        _refresh(force: force).whenComplete(() => _refreshing = null);
  }

  Future<PendingUpdate?> _refresh({required bool force}) async {
    await _load();
    if (_disposed) return _pending;

    final previous = _failedAt ?? _checkedAt;
    final interval = _failedAt != null ? retryInterval : checkInterval;
    if (!force && previous != null) {
      final elapsed = _now().difference(previous);
      // 기기 시계를 되돌렸을 때 미래의 기록 때문에 계속 차단되지 않게 한다.
      if (!elapsed.isNegative && elapsed < interval) {
        _notifyChanged();
        return _pending;
      }
    }

    _checking = true;
    _notifyChanged();
    UpdateCheckResult result;
    try {
      result = await _port.check();
    } on Object catch (error) {
      debugPrint('LOOPET: 업데이트 확인에 실패했다: $error');
      result = const UpdateCheckResult.failed();
    }

    if (result.succeeded) {
      _checkedAt = _now();
      _failedAt = null;
      final found = result.pending;
      final next = found != null &&
              (_installedBuild == null || found.versionCode > _installedBuild!)
          ? found
          : null;
      if (next?.versionCode != _pending?.versionCode) _bannerHidden = false;
      _pending = next;
      if (force) {
        _promptedVersionCode = null;
        _dismissedVersionCode = null;
        _bannerHidden = false;
      }
    } else {
      // 성공 시각과 이미 찾은 업데이트를 유지하고 실패 시각만 갱신한다.
      _failedAt = _now();
    }
    await _persist();
    _checking = false;
    _notifyChanged();
    return _pending;
  }

  Future<void> _load() async {
    if (_loaded) return;
    final record = await _recordLoader();
    _checkedAt = record.checkedAt;
    _failedAt = record.failedAt;
    _promptedVersionCode = record.promptedVersionCode;
    _dismissedVersionCode = record.dismissedVersionCode;
    _installedBuild = int.tryParse((await _versionLoader())?.buildNumber ?? '');
    final code = record.pendingVersionCode;
    if (code != null && (_installedBuild == null || _installedBuild! < code)) {
      _pending = PendingUpdate(versionCode: code);
    } else if (code != null) {
      await _persist();
    }
    _loaded = true;
  }

  Future<void> _persist() {
    final AppUpdateRecord record = (
      checkedAt: _checkedAt,
      failedAt: _failedAt,
      promptedVersionCode: _promptedVersionCode,
      dismissedVersionCode: _dismissedVersionCode,
      pendingVersionCode: _pending?.versionCode,
    );
    // 조회 완료와 팝업 표시가 겹쳐도 오래된 기록이 새 기록을 덮지 않는다.
    return _saveQueue = _saveQueue.then((_) => _recordSaver(record)).catchError(
      (Object error) {
        debugPrint('LOOPET: 업데이트 확인 기록을 저장하지 못했다: $error');
      },
    );
  }

  Future<void> markPromptShown() async {
    if (_promptVisible) return;
    _promptedVersionCode = _pending?.versionCode;
    _promptVisible = true;
    _notifyChanged();
    await _persist();
  }

  void markPromptClosed() {
    if (!_promptVisible) return;
    _promptVisible = false;
    _notifyChanged();
  }

  Future<void> dismiss({int? versionCode}) async {
    _dismissedVersionCode = versionCode ?? _pending?.versionCode;
    await _persist();
    _notifyChanged();
  }

  void hideBanner() {
    if (_bannerHidden) return;
    _bannerHidden = true;
    _notifyChanged();
  }

  Future<bool> openStore() => _port.openStore();

  void _notifyChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
