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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "InstagramSharePlugin") {
      InstagramSharePlugin.register(with: registrar)
    }
  }
}

/// Native plugin to handle Instagram Stories sharing and clipboard operations.
class InstagramSharePlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.glyphapp.glyph/instagram",
      binaryMessenger: registrar.messenger()
    )
    let instance = InstagramSharePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "shareToInstagramStories":
      shareToInstagramStories(call: call, result: result)
    case "copyImageToClipboard":
      copyImageToClipboard(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Share a sticker PNG to Instagram Stories via documented Sharing to Stories API.
  private func shareToInstagramStories(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let stickerData = args["stickerImage"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing stickerImage", details: nil))
      return
    }

    let facebookAppId = Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String ?? "YOUR_FACEBOOK_APP_ID"

    guard let url = URL(string: "instagram-stories://share?source_application=\(facebookAppId)") else {
      result(false)
      return
    }

    guard UIApplication.shared.canOpenURL(url) else {
      result(false)
      return
    }

    let pasteboardItems: [[String: Any]] = [[
      "com.instagram.sharedSticker.stickerImage": stickerData.data,
      "com.instagram.sharedSticker.backgroundTopColor": "#1A1A1A",
      "com.instagram.sharedSticker.backgroundBottomColor": "#1A1A1A"
    ]]

    let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
      .expirationDate: Date().addingTimeInterval(60 * 5)
    ]

    UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

    UIApplication.shared.open(url, options: [:]) { success in
      result(success)
    }
  }

  /// Copy image data to the system clipboard.
  private func copyImageToClipboard(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let imageData = args["imageData"] as? FlutterStandardTypedData,
          let image = UIImage(data: imageData.data) else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing imageData", details: nil))
      return
    }

    UIPasteboard.general.image = image
    result(nil)
  }
}
