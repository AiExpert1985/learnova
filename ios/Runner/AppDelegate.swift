import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(
      name: "com.learnova.app/audio_device",
      binaryMessenger: controller.binaryMessenger
    )

    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "areHeadphonesConnected":
        let isConnected = self?.checkHeadphonesConnected() ?? false
        result(isConnected)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Register for audio route changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(audioRouteChanged),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func checkHeadphonesConnected() -> Bool {
    let audioSession = AVAudioSession.sharedInstance()
    let currentRoute = audioSession.currentRoute

    for output in currentRoute.outputs {
      switch output.portType {
      case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
        return true
      default:
        continue
      }
    }

    return false
  }

  @objc private func audioRouteChanged(notification: Notification) {
    let isConnected = checkHeadphonesConnected()
    methodChannel?.invokeMethod("onHeadphoneConnectionChanged", arguments: isConnected)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
