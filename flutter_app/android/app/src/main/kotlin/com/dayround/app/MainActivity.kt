package com.dayround.app

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
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

        // 정확 알람은 앱이 스스로 켤 수 없다. 상태만 읽고, 켜려면 시스템 설정으로 보낸다.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "routine_timer/exact_alarm"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canScheduleExactAlarms" -> result.success(canScheduleExactAlarms())
                "openSettings" -> {
                    openExactAlarmSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /// Android 12 미만에는 이 개념이 없다 — 항상 정확하게 울리므로 true 로 본다.
    private fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return alarmManager.canScheduleExactAlarms()
    }

    private fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        // NEW_TASK 를 주면 설정 화면이 별도 태스크로 떠서, 뒤로 가기가 앱이 아니라
        // 홈으로 나간다. 같은 태스크에 쌓아야 사용자가 온보딩으로 돌아온다.
        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
            data = android.net.Uri.parse("package:$packageName")
        }
        startActivity(intent)
    }
}
