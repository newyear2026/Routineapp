package com.dayround.app

import android.app.AlarmManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.ZoneId

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "routine_timer/device_timezone"
        ).setMethodCallHandler { call, result ->
            if (call.method == "getLocalTimezone") {
                result.success(ZoneId.systemDefault().id)
            } else {
                result.notImplemented()
            }
        }

        // USE_EXACT_ALARM 을 선언하므로 Android 13+ 에서는 늘 허용이다.
        // 이 조회는 사용자가 권한을 끌 수 있는 Android 12~12L 을 위해 남는다.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "routine_timer/exact_alarm"
        ).setMethodCallHandler { call, result ->
            if (call.method == "canScheduleExactAlarms") {
                result.success(canScheduleExactAlarms())
            } else {
                result.notImplemented()
            }
        }
    }

    /// Android 12 미만에는 이 개념이 없다 — 항상 정확하게 울리므로 true 로 본다.
    private fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarmManager.canScheduleExactAlarms()
    }
}
