//
//  PollController.swift
//  App
//
//  Created by Mohammad Porooshani on 10/3/18.
//

import Vapor

private let rootPathComponent = "poll"
private let pollItemPathComponent = "item"

struct PollRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped([Models.User.tokenAuthMiddleware(), Models.User.guardAuthMiddleware()])
    tokenGroup.post(Models.Poll.CreateRequest.self, use: PollController.create)
    tokenGroup.get(use: PollController.list)
    tokenGroup.get(Models.Poll.parameter, use: PollController.item)
    tokenGroup.get(Models.Poll.parameter, use: PollController.item)
    tokenGroup.grouped(Models.Poll.parameter).put(Models.Poll.UpdateRequest.self, use: PollController.update)
    tokenGroup.delete(Models.Poll.parameter, use: PollController.delete)

    let itemTokenGroup = tokenGroup.grouped(Models.Poll.parameter).grouped(pollItemPathComponent)
    itemTokenGroup.post(Models.PollItem.CreateRequest.self, use: PollItemController.create)
    itemTokenGroup.get("", use: PollItemController.list)
  }
}

enum PollController {

  static func create(_ req: Request, createRequest: Models.Poll.CreateRequest) throws -> Future<Models.Poll.Public> {

    return createRequest.poll().save(on: req).flatMap { try $0.public(on: req) }
  }

  static func list(_ req: Request) throws -> Future<[Models.Poll.Public]> {

      return Models.Poll.query(on: req).filter(\Models.Poll.isEnabled, .equal, true).all().flatMap(to: [Models.Poll.Public].self) { polls in
        let promise = req.eventLoop.newPromise([Models.Poll.Public].self)
        DispatchQueue.global().async {
          let result = polls.compactMap { try? $0.public(on: req).wait() }
          promise.succeed(result: result)
        }
        return promise.futureResult
      }
  }

  static func item(_ req: Request) throws -> Future<Models.Poll.Public> {
    _ = try req.requireAuthenticated(Models.User.self)
    return try req.parameters.next(Models.Poll.self).flatMap { try $0.public(on: req) }
  }

  static func update(_ req: Request, updateRequest: Models.Poll.UpdateRequest) throws -> Future<Models.Poll.Public> {
    return try req.parameters.next(Models.Poll.self).flatMap(to: Models.Poll.Public.self) {
      $0.title = updateRequest.title ?? $0.title
      $0.description = updateRequest.description ?? $0.description
      $0.imageSrc = updateRequest.imageSrc ?? $0.imageSrc
      $0.voteLimit = updateRequest.voteLimit ?? $0.voteLimit
      $0.isAnonymous = updateRequest.isAnonymous ?? $0.isAnonymous
      $0.expirationDate = updateRequest.expirationDate ?? $0.expirationDate
      $0.isEnabled = updateRequest.isEnabled ?? $0.isEnabled
      return $0.save(on: req).flatMap { try $0.public(on: req) }
      }
  }

  static func delete(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.parameters.next(Models.Poll.self).flatMap(to: HTTPStatus.self) { poll in
      return try poll.pollItems.query(on: req).delete(force: true).flatMap(to: HTTPStatus.self) { _ in
        poll.delete(on: req).transform(to: .ok)
      }
    }
  }

}

enum PollItemController {

  static func create(_ req: Request, createRequest: Models.PollItem.CreateRequest) throws -> Future<Models.PollItem.Public> {
    return try req.parameters.next(Models.Poll.self).flatMap(to: Models.PollItem.Public.self) {
      guard let pollId = $0.id else {
        throw Abort(.badRequest)
      }
      return createRequest.pollItem(pollId: pollId).save(on: req).map { $0.public }
    }
  }

  static func list(_ req: Request) throws -> Future<[Models.PollItem.Public]> {
    return try req.parameters.next(Models.Poll.self).flatMap(to: [Models.PollItem.Public].self) {
      return try $0.pollItems.query(on: req).all().map(to: [Models.PollItem.Public].self){ $0.map { $0.public } }
    }
  }

}
