//
//  MessageController.swift
//  App
//
//  Created by Mohammad Porooshani on 10/3/18.
//

import Vapor

private let rootPathComponent = "message"

struct MessageRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped([Models.User.tokenAuthMiddleware(), Models.User.guardAuthMiddleware()])
    tokenGroup.post(Models.Message.createRequest.self, use: MessageController.create)
    tokenGroup.get(use: MessageController.list)
    tokenGroup.get(Models.Message.parameter, use: MessageController.item)
//    tokenGroup.put(Models.Message.parameter, use: MessageController.update)
  }
}

enum MessageController {

  static func create(_ req: Request, createrequest: Models.Message.createRequest) throws -> Future<Models.Message.Public> {
    let userId = createrequest.userId
    return Models.User.find(userId, on: req).flatMap(to: Models.Message.Public.self) { userRes in
      guard let user = userRes else {
        throw Abort(.badRequest)
      }
      return addMessage(userId: userId, createRequest: createrequest, on: req).map(to: Models.Message.Public.self) { $0.public }
        .do { message in
          let msg = PushService.Message(title: "پیام جدید", body: message.body, subtitle: message.title, action: nil, badge: 1)
          let updateMsg = PushService.UpdateMessage(type: .messages, event: .create)
          do {
            try PushService.shared.send(message: msg, to: [user], on: req)
            try PushService.shared.send(message: updateMsg, to: [user], on: req)
          } catch {
            print("Could not send notification for message.\n\(error.localizedDescription)")
          }
      }

    }

  }

  static func addMessage(userId: Models.User.ID, createRequest: Models.Message.createRequest, on req: Request) -> Future<Models.Message> {
    return createRequest.message(for: userId).save(on: req)
  }

  static func list(_ req: Request) throws -> Future<[Models.Message.Public]> {
    let user = try req.requireAuthenticated(Models.User.self)
    return try user.messages.query(on: req).sort(\.date, .descending).all().map { $0.map { $0.public } }
  }

  static func item(_ req: Request) throws -> Future<Models.Message.Public> {
    return try req.parameters.next(Models.Message.self).map(to: Models.Message.Public.self) { $0.public }
  }

//  static func update(_ req: Request) throws -> Future<Models.Message.Public> {
//    fatalError("Not Implemented")
//  }

}
