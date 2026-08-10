import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // 암시적 엔진 사용 시 didFinishLaunching 시점에는 rootViewController가 아직 없다.
    // 엔진 초기화 콜백에서 등록해야 Dart 쪽 MethodChannel 호출이 도달한다.
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "RoutineTimerDeviceTimezone"
    ) else { return }

    let channel = FlutterMethodChannel(
      name: "routine_timer/device_timezone",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "getLocalTimezone" {
        result(TimeZone.current.identifier)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
