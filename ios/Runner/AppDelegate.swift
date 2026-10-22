import Flutter
import UIKit
import flutter_callkit_incoming
import Intents
import UserNotifications
import PushKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  var pendingCallIntent: [String: Any]?
  var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Setup VoIP PushKit registry for incoming meeting calls
    voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    voipRegistry?.delegate = self
    voipRegistry?.desiredPushTypes = [.voIP]

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    application.registerForRemoteNotifications()
    
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

  // MARK: - PKPushRegistryDelegate for Meeting Calls

  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    if type == .voIP {
      let voipToken = credentials.token.map { String(format: "%02x", $0) }.joined()
      print("====================================")
      print("🚀 [PushKit] iOS VoIP Device Token: \(voipToken)")
      print("====================================")
      SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(voipToken)
    }
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    if type == .voIP {
      SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    }
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    if type == .voIP {
      print("==================================================")
      print("📞 [iOS NATIVE PushKit] Incoming VoIP Push received!")
      print("📞 [iOS NATIVE PushKit] Payload: \(payload.dictionaryPayload)")
      if var data = payload.dictionaryPayload as? [String: Any] {
        let callerName = data["caller_name"] as? String ?? data["host_name"] as? String ?? "Meeting Invitation"
        let handle = data["channel_name"] as? String ?? data["room_id"] as? String ?? "Join Meeting"
        let isVideo = (data["isVideo"] as? Bool == true) || (data["is_video"] as? Bool == true) || (data["call_type"] as? String == "video") || (data["type"] as? Int == 1)
        let uuid = data["id"] as? String ?? UUID().uuidString

        print("📞 [iOS NATIVE PushKit] Parsed Meeting -> Caller: \(callerName), Handle: \(handle), isVideo: \(isVideo), UUID: \(uuid)")

        var callArgs: [String: Any] = [
          "id": uuid,
          "nameCaller": callerName,
          "appName": "Arihanth",
          "handle": handle,
          "type": isVideo ? 1 : 0,
          "duration": 30000,
          "extra": data
        ]

        // Merge any other parameters so nothing is lost
        for (k, v) in data {
          if callArgs[k] == nil {
            callArgs[k] = v
          }
        }

        let callData = flutter_callkit_incoming.Data(args: callArgs)
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(callData, fromPushKit: true)
        print("📞 [iOS NATIVE PushKit] showCallkitIncoming called on CallKit Plugin successfully!")
      }
      print("==================================================")
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        completion()
      }
    } else {
      completion()
    }
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
