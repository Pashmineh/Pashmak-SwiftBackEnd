//
//  PollController.swift
//  App
//
//  Created by Mohammad Porooshani on 10/3/18.
//

import Vapor

private let rootPathComponent = "poll"
private let pollItemPathComponent = "item"
private let votePathComponent = "vote"

struct PollRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped([Models.User.tokenAuthMiddleware(), Models.User.guardAuthMiddleware()])
    tokenGroup.post(Models.Poll.CreateRequest.self, use: PollController.create)
    tokenGroup.get(use: PollController.list)
    tokenGroup.get(Models.Poll.parameter, use: PollController.item)
    tokenGroup.grouped(Models.Poll.parameter).put(Models.Poll.UpdateRequest.self, use: PollController.update)
    tokenGroup.delete(Models.Poll.parameter, use: PollController.delete)

    let itemTokenGroup = tokenGroup.grouped(Models.Poll.parameter).grouped(pollItemPathComponent)
    itemTokenGroup.post(Models.PollItem.CreateRequest.self, use: PollItemController.create)
    itemTokenGroup.get("", use: PollItemController.list)
    itemTokenGroup.get(Models.PollItem.parameter, use: PollItemController.item)
    itemTokenGroup.grouped(Models.PollItem.parameter).put(Models.PollItem.UpdateRequest.self, use: PollItemController.update)
    itemTokenGroup.delete(Models.PollItem.parameter, use: PollItemController.delete)

    let voteTokenGroup = tokenGroup.grouped(Models.Poll.parameter).grouped(votePathComponent)
    voteTokenGroup.post(Models.Vote.Input.self, use: VoteController.vote)
    voteTokenGroup.put(Models.Vote.Input.self, use: VoteController.unvote)

  }

}

enum PollController {

  static func create(_ req: Request, createRequest: Models.Poll.CreateRequest) throws -> Future<Models.Poll.Public> {

    return createRequest.poll().save(on: req).flatMap { try $0.public(on: req) }
  }

  static func list(_ req: Request) throws -> Future<[Models.Poll.Public]> {

    return Models.Poll.query(on: req).filter(\Models.Poll.isEnabled, .equal, true).all()
      .flatMap(to: [Models.Poll.Public].self) { try $0.map { try $0.public(on: req)}.flatten(on: req) }
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

  static func item(_ req: Request) throws -> Future<Models.PollItem.Public> {
    _ = try req.parameters.next(Models.Poll.self)
    return try req.parameters.next(Models.PollItem.self).map { $0.public }
  }

  static func update(_ req: Request, updateRequest: Models.PollItem.UpdateRequest) throws -> Future<Models.PollItem.Public> {
    _ = try req.parameters.next(Models.Poll.self)
    return try req.parameters.next(Models.PollItem.self).flatMap(to: Models.PollItem.Public.self) {
      $0.title = updateRequest.title ?? $0.title
      $0.imageSrc = updateRequest.imageSrc ?? $0.imageSrc
      return $0.save(on: req).map { $0.public }
    }
  }

  static func delete(_ req: Request) throws -> Future<HTTPStatus> {
    _ = try req.parameters.next(Models.Poll.self)
    return try req.parameters.next(Models.PollItem.self).delete(on: req).transform(to: .ok)
  }

}

enum VoteController {

  static func vote(_ req: Request, input: Models.Vote.Input) throws -> Future<Models.Poll.Public> {
    let user = try req.requireAuthenticated(Models.User.self)

    return try req.parameters.next(Models.Poll.self).flatMap { poll in

      return try voteItem(for: user, with: input.itemId, in: poll, on: req).save(on: req).flatMap { _ in
        try poll.public(on: req)
      }

    }

  }

  private static func alreadyVoted(user: Models.User, pollId: Models.Poll.ID, itemId: Models.PollItem.ID, on req: Request) throws -> Future<Bool> {
    return try user.votes.query(on: req).filter(\Models.Vote.pollId, .equal, pollId).filter(\Models.Vote.itemId, .equal, itemId).count().map(to: Bool.self) { $0 > 0 }
  }

  private static func voteItem(for user: Models.User, with itemId: Models.PollItem.ID, in poll: Models.Poll, on req: Request) throws -> Future<Models.Vote> {
    let userId = try user.requireID()
    return try poll.pollItems.query(on: req).filter(\Models.PollItem.id, .equal, itemId).first().flatMap { item in
      guard let pollItemId = item?.id, let pollId = poll.id else {
        print("Vote Item not found")
        throw Abort(.notFound)
      }
      return try alreadyVoted(user: user, pollId: pollId, itemId: itemId, on: req).map {
        guard !$0 else {
          print("user already voted")
          throw Abort(.alreadyReported)
        }
        return Models.Vote(userId: userId, pollId: pollId, itemId: pollItemId)
      }

    }
  }

  static func unvote(_ req: Request, input: Models.Vote.Input) throws -> Future<Models.Poll.Public> {
    let user = try req.requireAuthenticated(Models.User.self)
    
    return try req.parameters.next(Models.Poll.self).flatMap(to: Models.Poll.Public.self) { poll in
      guard let pollId = poll.id else {
        throw Abort(.badRequest)
      }
      let itemId = input.itemId
      return try user.votes.query(on: req).filter(\Models.Vote.pollId, .equal, pollId).filter(\Models.Vote.itemId, .equal, itemId).delete(force: true).flatMap(to: Models.Poll.Public.self) { _ in
        return try poll.public(on: req)
        }.do { _ in
          PushService.shared.sendPollUpdate(on: req)
        }.catch {
          print("Error sending poll update.\n\($0.localizedDescription)")
      }
    }

  }

}
