import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Privacy Shield for App Switcher
    NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc func applicationWillResignActive() {
    // Add a blur effect or a splash screen over the window
    let blurEffect = UIBlurEffect(style: .light)
    let blurEffectView = UIVisualEffectView(effect: blurEffect)
    blurEffectView.frame = window?.frame ?? UIScreen.main.bounds
    blurEffectView.tag = 12345
    window?.addSubview(blurEffectView)
  }

  @objc func applicationDidBecomeActive() {
    // Remove the blur effect
    window?.viewWithTag(12345)?.removeFromSuperview()
  }
}
