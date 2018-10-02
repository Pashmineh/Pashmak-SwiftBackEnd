//
//  PushService.swift
//  App
//
//  Created by Mohammad Porooshani on 10/2/18.
//

import Vapor

private let kTopic = "com.pashmak.app"
private let kPushBaseURL = "178.62.20.28"
private let kPushBaseURLPort = 8088

protocol GORushConvertibale {
  func goRushMessage(for users: [User]) -> PushService.GORushMessage
}

class PushService {

  struct Message: GORushConvertibale {

    let title: String
    let body: String
    let subtitle: String?
    let action: String?
    let badge: Int?

    init(title: String, body: String, subtitle: String? = nil, action: String? = nil, badge: Int? = nil) {
      self.title = title
      self.body = body
      self.subtitle = subtitle
      self.badge = badge
      self.action = action
    }

    func goRushMessage(for users: [User]) -> GORushMessage {

      let iOSTokens: [String] = users.filter { $0.platform == "IOS" && !$0.pushToken.isEmpty }.compactMap { $0.pushToken }
      let androidTokens: [String] = users.filter { $0.platform == "ANDROID" && !$0.pushToken.isEmpty }.compactMap { $0.pushToken }

      var notifications: [GORushMessage.Notification] = []

      if !iOSTokens.isEmpty {
        let notif = GORushMessage.Notification(tokens: iOSTokens, platform: .iOS, message: self.body, title: self.title, priority: .high, topic: kTopic, data: nil, alert: PushService.GORushMessage.Notification.iOSNotification(message: self), notification: nil, content_available: false)
        notifications.append(notif)
      }

      if !androidTokens.isEmpty {
        let notif = GORushMessage.Notification(tokens: androidTokens, platform: .android, message: self.body, title: self.title, priority: .high, topic: kTopic, data: nil, alert: nil, notification: PushService.GORushMessage.Notification.AndroidNotification(message: self), content_available: false)
        notifications.append(notif)
      }

      print("iOS Messages: [\(iOSTokens.count)]\nAndroid Messages: [\(androidTokens.count)]")
      return GORushMessage(notifications: notifications)

    }

  }

  struct UpdateMessage: GORushConvertibale {
    func goRushMessage(for users: [User]) -> GORushMessage {
      let iOSTokens: [String] = users.filter { $0.platform == "IOS" && !$0.pushToken.isEmpty }.compactMap { $0.pushToken }
      let androidTokens: [String] = users.filter { $0.platform == "ANDROID" && !$0.pushToken.isEmpty }.compactMap { $0.pushToken }

      var notifications: [GORushMessage.Notification] = []

      if !iOSTokens.isEmpty {
        let notif = GORushMessage.Notification(tokens: iOSTokens, platform: .iOS, message: nil, title: nil, priority: .high, topic: kTopic, data: nil, alert: nil, notification: nil, content_available: true)
        notifications.append(notif)
      }

      if !androidTokens.isEmpty {
        let notif = GORushMessage.Notification(tokens: androidTokens, platform: .android, message: nil, title: nil, priority: .high, topic: kTopic, data: nil, alert: nil, notification: nil, content_available: true)
        notifications.append(notif)
      }

      return GORushMessage(notifications: notifications)
    }
  }

  struct GORushMessage: Codable {

    struct Notification: Codable {

      struct iOSNotification: Codable {

        let title: String
        let body: String
        let subtitle: String?
        let action: String?

        init(message: Message) {
          self.title = message.title
          self.body = message.body.trunc(length: 253, trailing: "...")
          self.subtitle = message.subtitle
          self.action = message.action
        }

      }

      struct AndroidNotification: Codable {

        init(message: Message) {

        }
      }

      enum Platform: Int, Codable {
        case iOS = 1
        case android = 2
      }

      enum Priority: String, Codable {
        case normal = "normal"
        case high = "high"
      }

      let tokens: [String]
      let platform: Platform
      let message: String?
      let title: String?
      let priority: Priority
      let topic: String
      let data: String?
      let alert: iOSNotification?
      let notification: AndroidNotification?
      let content_available: Bool?

    }

    let notifications: [Notification]

  }

  static let shared: PushService = PushService()

  @discardableResult
  func send(message: GORushConvertibale, to users: [User], on worker: Worker) throws -> Future<Bool> {
    print("Sending [\(users.count)] messages")
    return HTTPClient.connect(scheme: HTTPScheme.http, hostname: kPushBaseURL, port: kPushBaseURLPort, connectTimeout: TimeAmount.seconds(TimeAmount.Value(exactly: 30.0)!), on: worker) { error in
        print("Error connecting to push server.\n\(error.localizedDescription)")
      }
      .flatMap(to: HTTPResponse.self) { client in
      let body = try JSONEncoder().encode(message.goRushMessage(for: users))
      let request = HTTPRequest(method: .POST, url: "/api/push", version: HTTPVersion.init(major: 1, minor: 1), headers: HTTPHeaders([]), body: body)
      return client.send(request)
      }.flatMap(to: Bool.self) { status in
        print("GoRush Response:\n\(status.body)")
        return worker.future((status.status == .ok) ? true : false)
    }
  }

}
