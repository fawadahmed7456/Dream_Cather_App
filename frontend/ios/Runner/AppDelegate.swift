import Flutter
import UIKit
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // CRITICAL: Handle reCAPTCHA callback URL for Firebase Phone Auth.
  // supabase_flutter's app_links dependency intercepts ALL URLs — we must
  // let Firebase claim its own callback BEFORE super (app_links) processes it.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if Auth.auth().canHandle(url) {
      return true  // Firebase consumed it — do NOT forward to app_links/Flutter router
    }
    return super.application(app, open: url, options: options)
  }

  // Handle Firebase auth callbacks that arrive as universal links
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if let url = userActivity.webpageURL, Auth.auth().canHandle(url) {
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}

