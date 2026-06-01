import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var shareMethodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    shareMethodChannel = FlutterMethodChannel(
      name: "com.ahsmobilelabs.finzo/share",
      binaryMessenger: messenger
    )
    shareMethodChannel?.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "shareLinktreeQr":
        self?.shareLinktreeQr(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func shareLinktreeQr(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(
        code: "missing_args",
        message: "Share details were not provided.",
        details: nil
      ))
      return
    }

    let text = args["text"] as? String ?? ""
    guard
      let imagePath = args["imagePath"] as? String,
      FileManager.default.fileExists(atPath: imagePath)
    else {
      result(FlutterError(
        code: "missing_image",
        message: "QR image file was not found.",
        details: nil
      ))
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard let presenter = self?.topViewController() else {
        result(FlutterError(
          code: "no_presenter",
          message: "Unable to open the share sheet.",
          details: nil
        ))
        return
      }

      let controller = UIActivityViewController(
        activityItems: [text, URL(fileURLWithPath: imagePath)],
        applicationActivities: nil
      )
      if let popover = controller.popoverPresentationController {
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(
          x: presenter.view.bounds.midX,
          y: presenter.view.bounds.midY,
          width: 0,
          height: 0
        )
        popover.permittedArrowDirections = []
      }

      presenter.present(controller, animated: true)
      result(nil)
    }
  }

  private func topViewController() -> UIViewController? {
    guard var top = activeRootViewController() else {
      return nil
    }

    while let presented = top.presentedViewController {
      top = presented
    }

    return top
  }

  private func activeRootViewController() -> UIViewController? {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController
    }

    return UIApplication.shared.windows
      .first { $0.isKeyWindow }?
      .rootViewController
  }
}
