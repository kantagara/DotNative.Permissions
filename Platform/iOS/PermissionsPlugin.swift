import AVFoundation
import CoreLocation
import Foundation
import UserNotifications

@MainActor final class PermissionsPlugin: NSObject, CLLocationManagerDelegate {
  private static var instance: PermissionsPlugin?
  private var locationManager: CLLocationManager?
  private var locationReply: PluginReply?
  static func register() { if instance == nil { instance = PermissionsPlugin() } }

  private override init() {
    super.init()
    let channel = NativeChannels.channel(PermissionsChannel)
    channel.handle("check") { [weak self] args, reply in
      self?.check(args, reply) ?? reply.failure("unavailable", "Permission plugin is unavailable")
    }
    channel.handle("request") { [weak self] args, reply in
      self?.request(args, reply) ?? reply.failure("unavailable", "Permission plugin is unavailable")
    }
  }

  private func permission(_ arguments: PluginValue) throws -> String {
    guard let value = arguments.fields["permission"]?.string,
      ["camera", "microphone", "location", "notifications"].contains(value)
    else { throw CocoaError(.coderInvalidValue) }
    return value
  }

  private func check(_ arguments: PluginValue, _ reply: PluginReply) {
    do {
      switch try permission(arguments) {
      case "camera": reply.success(.string(Self.status(AVCaptureDevice.authorizationStatus(for: .video))))
      case "microphone": reply.success(.string(Self.status(AVCaptureDevice.authorizationStatus(for: .audio))))
      case "location": reply.success(.string(locationStatus(CLLocationManager.authorizationStatus())))
      case "notifications":
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          let result = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            ? "granted" : settings.authorizationStatus == .notDetermined ? "notDetermined" : "denied"
          Task { @MainActor in reply.success(.string(result)) }
        }
      default: reply.failure("unsupported", "Permission is not supported")
      }
    } catch { reply.failure("invalid_permission", "Unknown permission name") }
  }

  private func request(_ arguments: PluginValue, _ reply: PluginReply) {
    do {
      switch try permission(arguments) {
      case "camera": AVCaptureDevice.requestAccess(for: .video) { granted in Task { @MainActor in reply.success(.string(granted ? "granted" : "denied")) } }
      case "microphone": AVCaptureDevice.requestAccess(for: .audio) { granted in Task { @MainActor in reply.success(.string(granted ? "granted" : "denied")) } }
      case "location":
        let current = CLLocationManager.authorizationStatus()
        if current != .notDetermined { reply.success(.string(locationStatus(current))); return }
        guard locationReply == nil else { reply.failure("busy", "A location permission request is already pending"); return }
        let manager = CLLocationManager()
        locationManager = manager
        locationReply = reply
        manager.delegate = self
        reply.onCancel = { [weak self] in
          Task { @MainActor in self?.locationReply = nil; self?.locationManager?.delegate = nil; self?.locationManager = nil }
        }
        manager.requestWhenInUseAuthorization()
      case "notifications":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
          Task { @MainActor in
            if let error { reply.failure("permission_failed", error.localizedDescription) }
            else { reply.success(.string(granted ? "granted" : "denied")) }
          }
        }
      default: reply.failure("unsupported", "Permission is not supported")
      }
    } catch { reply.failure("invalid_permission", "Unknown permission name") }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = CLLocationManager.authorizationStatus()
    guard status != .notDetermined, let reply = locationReply else { return }
    locationReply = nil
    locationManager?.delegate = nil
    locationManager = nil
    reply.success(.string(locationStatus(status)))
  }

  private func locationStatus(_ status: CLAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .authorizedAlways, .authorizedWhenInUse: return "granted"
    case .restricted: return "restricted"
    case .denied: return "denied"
    @unknown default: return "restricted"
    }
  }
  private static func status(_ status: AVAuthorizationStatus) -> String {
    switch status {
    case .notDetermined: return "notDetermined"
    case .authorized: return "granted"
    case .restricted: return "restricted"
    case .denied: return "denied"
    @unknown default: return "restricted"
    }
  }
}
