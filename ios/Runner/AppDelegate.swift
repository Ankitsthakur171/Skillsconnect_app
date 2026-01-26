import Flutter
import UIKit
import AVFAudio
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      print("FirebaseApp-->configure")
      FirebaseApp.configure() //add this before the code below
      GeneratedPluginRegistrant.register(with: self)      // Get the Flutter view controller
      guard let controller = window?.rootViewController as? FlutterViewController else {
          fatalError("Invalid root view controller")
      }
      // Call your setup function
      setupAudioRouteChannel(controller: controller)
      
      application.registerForRemoteNotifications()
      if #available(iOS 10.0, *) {
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )
      } else {
        let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
      }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    override func application(_ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered for Apple Remote Notifications")
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown)
        Messaging.messaging().apnsToken = deviceToken
        print(deviceToken)
       super.application(application,didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
     }
}

let CHANNEL = "app.audio.route"

private func setupAudioRouteChannel(controller: FlutterViewController) {
  let channel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)
  channel.setMethodCallHandler { (call, result) in
    let session = AVAudioSession.sharedInstance()
    do {
      switch call.method {
      case "isBtAvailable":
        let route = session.currentRoute
        let hasBT = route.outputs.contains { $0.portType == .bluetoothA2DP || $0.portType == .bluetoothLE || $0.portType == .bluetoothHFP }
        result(hasBT)
      case "toBluetooth":
        try session.setCategory(.playAndRecord, options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker])
        try session.setActive(true)
        result(true)
      case "toSpeaker":
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
        try session.overrideOutputAudioPort(.speaker)
        try session.setActive(true)
        result(true)
      case "toEarpiece":
        try session.setCategory(.playAndRecord, options: [])
        try session.overrideOutputAudioPort(.none)
        try session.setActive(true)
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(FlutterError(code: "AUDIO_ROUTE_ERR", message: error.localizedDescription, details: nil))
    }
  }
}