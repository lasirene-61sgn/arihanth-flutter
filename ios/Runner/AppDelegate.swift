import Flutter
import UIKit
import flutter_callkit_incoming
import Intents

@main
@objc class AppDelegate: FlutterAppDelegate {
  var pendingCallIntent: [String: Any]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    if let controller = window?.rootViewController as? FlutterViewController {
      let intentChannel = FlutterMethodChannel(name: "com.arihanth.app/call_intent", binaryMessenger: controller.binaryMessenger)
      intentChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "getPendingCallIntent" {
          result(self?.pendingCallIntent)
          self?.pendingCallIntent = nil
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }

    // Privacy Shield for App Switcher
    NotificationCenter.default.addObserver(self, selector: #selector(handleAppResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleAppBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == "INStartAudioCallIntent" || userActivity.activityType == "INStartVideoCallIntent" {
      if let handle = userActivity.handle {
        let isVideo = userActivity.isVideo ?? false
        let decryptedMap = handle.getDecryptHandle()
        let resolvedHandle = decryptedMap["handle"] as? String ?? handle
        var nameCaller = decryptedMap["nameCaller"] as? String ?? handle
        
        if nameCaller == handle || nameCaller == resolvedHandle {
          let defaults = UserDefaults.standard
          if let savedName = defaults.string(forKey: "flutter.caller_name_\(resolvedHandle)") {
            nameCaller = savedName
          }
        }
        
        let args: [String: Any] = [
          "channel_name": resolvedHandle,
          "caller_name": nameCaller,
          "isVideo": isVideo
        ]
        
        self.pendingCallIntent = args
        
        if let controller = window?.rootViewController as? FlutterViewController {
          let intentChannel = FlutterMethodChannel(name: "com.arihanth.app/call_intent", binaryMessenger: controller.binaryMessenger)
          intentChannel.invokeMethod("handleStartCallIntent", arguments: args)
        }
      }
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  @objc func handleAppResignActive() {
    // Add a blur effect or a splash screen over the window
    let blurEffect = UIBlurEffect(style: .light)
    let blurEffectView = UIVisualEffectView(effect: blurEffect)
    blurEffectView.frame = window?.frame ?? UIScreen.main.bounds
    blurEffectView.tag = 12345
    window?.addSubview(blurEffectView)
  }

  @objc func handleAppBecomeActive() {
    // Remove the blur effect
    window?.viewWithTag(12345)?.removeFromSuperview()
  }
}
