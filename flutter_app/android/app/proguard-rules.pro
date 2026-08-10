# 릴리즈 빌드는 R8로 축소·난독화된다. 아래 규칙이 없으면 debug에서는 멀쩡하고
# release에서만 터지는 문제가 생긴다 — 실제로 그랬다:
#
#   PlatformException(error, Missing type parameter., ...)
#     at com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin
#          .loadScheduledNotifications
#
# flutter_local_notifications는 예약된 알림을 Gson으로 직렬화하고
# TypeToken<ArrayList<NotificationDetails>>으로 되읽는다. R8이 제네릭
# 시그니처를 지우면 TypeToken이 타입 인자를 잃어 위 예외가 난다.

# --- Gson: 제네릭 시그니처와 애노테이션을 남긴다 ---
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses, EnclosingMethod

-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# --- flutter_local_notifications ---
# Gson이 리플렉션으로 읽는 모델이라 필드명이 바뀌면 안 된다.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**
