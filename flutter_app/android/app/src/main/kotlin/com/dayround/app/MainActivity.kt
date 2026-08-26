package com.example.routine_timer

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
    }
}
