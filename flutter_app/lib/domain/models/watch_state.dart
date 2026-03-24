/// 웨어러블/기기 연동 상태 — 폰 단독 앱이면 기본값 유지
class WatchState {
  const WatchState({
    this.isPaired = false,
    this.isReachable = false,
    this.lastSyncAt,
    this.platformDeviceId,
    this.lastErrorCode,
  });

  final bool isPaired;
  final bool isReachable;
  final DateTime? lastSyncAt;

  /// OS별 기기 식별자 (동기화 키로 사용 가능)
  final String? platformDeviceId;
  final String? lastErrorCode;

  WatchState copyWith({
    bool? isPaired,
    bool? isReachable,
    DateTime? lastSyncAt,
    String? platformDeviceId,
    String? lastErrorCode,
  }) {
    return WatchState(
      isPaired: isPaired ?? this.isPaired,
      isReachable: isReachable ?? this.isReachable,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      platformDeviceId: platformDeviceId ?? this.platformDeviceId,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
    );
  }

  Map<String, dynamic> toJson() => {
        'isPaired': isPaired,
        'isReachable': isReachable,
        'lastSyncAt': lastSyncAt?.millisecondsSinceEpoch,
        'platformDeviceId': platformDeviceId,
        'lastErrorCode': lastErrorCode,
      };

  factory WatchState.fromJson(Map<String, dynamic> json) {
    return WatchState(
      isPaired: json['isPaired'] as bool? ?? false,
      isReachable: json['isReachable'] as bool? ?? false,
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSyncAt'] as int)
          : null,
      platformDeviceId: json['platformDeviceId'] as String?,
      lastErrorCode: json['lastErrorCode'] as String?,
    );
  }
}
