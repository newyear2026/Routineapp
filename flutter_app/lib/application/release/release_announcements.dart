import 'package:flutter/foundation.dart';

import '../../data/local/release_notes_storage.dart';
import '../../data/seed/release_notes.dart';
import '../services/app_version_service.dart';

/// 무엇이 바뀌었는지 한 번 말한다 — 기기가 그것을 **설치한 뒤에**.
///
/// 업데이트 이야기의 나머지 절반이고, 반대쪽 끝이다. `AppUpdates`는 업데이트
/// 전에 말하고 무언가를 요청한다. 이것은 업데이트 뒤에 말하고 아무것도
/// 요청하지 않는다. 둘이 같은 빌드를 두고 말하는 일은 없다.
///
/// 규칙:
///
/// * 한 버전은 자기를 한 번만 알린다. 기억하는 것은 **버전 이름**이므로
///   `1.1.0`의 두 빌드는 한 릴리스이고 한 번만 끼어든다.
/// * [releaseNotes]에 항목이 없는 버전은 아무 말도 하지 않는다. 노트 없이 나간
///   핫픽스가 빈 카드를 여는 일은 없어야 한다.
/// * **맨 처음 실행은 아무것도 알리지 않는다.** 방금 설치한 사람에게는 전부가
///   새것이고, 온보딩 위에 «무엇이 바뀌었나» 카드를 얹는 것은 말이 안 된다.
/// * 알려진 것과 읽은 것은 다르다. 카드를 닫으면 설정 행의 점은 남고, 노트를
///   열 때만 지워진다.
class ReleaseAnnouncements extends ChangeNotifier {
  ReleaseAnnouncements({
    Future<ReleaseNotesRecord> Function()? recordLoader,
    Future<void> Function(ReleaseNotesRecord)? recordSaver,
    AppVersionLoader versionLoader = loadAppVersion,
    List<ReleaseNote>? notes,
  })  : _recordLoader = recordLoader ?? ReleaseNotesStorage.load,
        _recordSaver = recordSaver ?? ReleaseNotesStorage.save,
        _versionLoader = versionLoader,
        _notes = notes ?? releaseNotes;

  final Future<ReleaseNotesRecord> Function() _recordLoader;
  final Future<void> Function(ReleaseNotesRecord) _recordSaver;
  final AppVersionLoader _versionLoader;
  final List<ReleaseNote> _notes;

  AppVersion? _version;
  String? _announcedVersion;
  String? _readVersion;
  bool _started = false;

  /// 돌고 있는 빌드. 노트 화면이 자기 카드를 «현재»로 표시할 때 다시 읽지 않게
  /// 통째로 들고 있는다.
  AppVersion? get version => _version;

  List<ReleaseNote> get notes => List<ReleaseNote>.unmodifiable(_notes);

  String? get _runningVersion => _version?.version;

  /// 손에 든 빌드의 노트, 또는 이 버전이 노트 없이 나갔다면 null. 플랫폼이
  /// 어느 빌드인지 말해 주지 않을 때도 null이다.
  ReleaseNote? get currentNote {
    final version = _runningVersion;
    if (version == null) return null;
    for (final note in _notes) {
      if (note.version == version) return note;
    }
    return null;
  }

  bool get shouldAnnounce =>
      currentNote != null && _runningVersion != _announcedVersion;

  /// 설정 행이 점을 달고 있어야 하는가.
  bool get hasUnreadNotes =>
      currentNote != null && _runningVersion != _readVersion;

  /// 돌고 있는 빌드를 읽고, 이 실행이 사용자에게 무엇을 빚졌는지 정한다.
  ///
  /// 여러 번 불러도 안전하다 — 첫 번만 일하므로 화면이 `didChangeDependencies`
  /// 에서 세지 않고 불러도 된다.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final version = await _versionLoader();
    // 버전이 없으면 비교할 것이 없다. 앱이 이름 붙일 수 없는 빌드를 두고 카드를
    // 띄울 수는 없고, 가장 새 노트를 찍어 보는 것은 릴리스를 건너뛴 기기에
    // 엉뚱한 소식을 알리는 일이다.
    if (version == null) return;
    _version = version;

    final record = await _recordLoader();
    _announcedVersion = record.announcedVersion;
    _readVersion = record.readVersion;

    if (_announcedVersion == null && _readVersion == null) {
      // 이것이 돌아간 맨 처음 실행이다. 지금 위치만 적고 아무 말도 하지 않는다.
      // 새로 설치한 기기에는 «무엇이 바뀌었나»가 없고, 이 항목이 없던 빌드에서
      // 올라온 경우에도 정직한 답이 없다 — 손에 든 버전뿐이고, 그건 이미 보고
      // 있는 것이다.
      _announcedVersion = _runningVersion;
      _readVersion = _runningVersion;
      await _persist();
    }
    notifyListeners();
  }

  Future<void> _persist() => _recordSaver(
        (announcedVersion: _announcedVersion, readVersion: _readVersion),
      );

  /// 카드가 떴다. 점은 노트를 열 때까지 남는다.
  Future<void> markAnnounced() async {
    if (_announcedVersion == _runningVersion) return;
    _announcedVersion = _runningVersion;
    await _persist();
    notifyListeners();
  }

  /// 노트 화면이 열렸다 — 알린 것까지 여기서 함께 덮는다.
  Future<void> markRead() async {
    if (_readVersion == _runningVersion &&
        _announcedVersion == _runningVersion) {
      return;
    }
    _announcedVersion = _runningVersion;
    _readVersion = _runningVersion;
    await _persist();
    notifyListeners();
  }
}
