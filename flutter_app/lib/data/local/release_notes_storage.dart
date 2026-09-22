import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 릴리스 노트가 기억해야 하는 두 값.
///
/// 둘을 나눈 이유는 «알렸다»와 «읽었다»가 다른 일이기 때문이다. 카드를 닫으면
/// 알린 것이고, 설정 행의 점은 노트를 실제로 열 때까지 남는다.
typedef ReleaseNotesRecord = ({String? announcedVersion, String? readVersion});

/// [ReleaseNotesRecord]의 로컬 보관소.
///
/// [AppUpdateStorage]와 같은 이유로 루틴 저장소가 아니라 기기 장부를 쓴다 —
/// 백업을 다른 기기에 복원했을 때 «이미 봤음»이 따라가면 안 된다.
class ReleaseNotesStorage {
  ReleaseNotesStorage._();

  static const _kAnnounced = 'device.notes.announced_version';
  static const _kRead = 'device.notes.read_version';

  static const ReleaseNotesRecord empty =
      (announcedVersion: null, readVersion: null);

  static Future<ReleaseNotesRecord> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (
        announcedVersion: p.getString(_kAnnounced),
        readVersion: p.getString(_kRead),
      );
    } on Object catch (error) {
      // 반복되는 카드 한 번 값이지, 오류 경로를 만들 일은 아니다.
      debugPrint('LOOPET: 릴리스 노트 기록을 읽지 못했다: $error');
      return empty;
    }
  }

  static Future<void> save(ReleaseNotesRecord record) async {
    try {
      final p = await SharedPreferences.getInstance();
      final announced = record.announcedVersion;
      final read = record.readVersion;
      if (announced != null) await p.setString(_kAnnounced, announced);
      if (read != null) await p.setString(_kRead, read);
    } on Object catch (error) {
      debugPrint('LOOPET: 릴리스 노트 기록을 저장하지 못했다: $error');
    }
  }
}
