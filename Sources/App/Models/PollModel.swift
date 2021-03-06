//
//  PollModel.swift
//  App
//
//  Created by Mohammad Porooshani on 10/3/18.
//

import FluentPostgreSQL
import Vapor


// MARK: - Poll -

extension Models {

  final class Poll: PostgreSQLUUIDModel {
    var id: UUID?
    var title: String
    var description: String
    var imageSrc: String?
    var voteLimit: Int
    var isAnonymous: Bool
    var expirationDate: Double
    var isEnabled: Bool

    init(title: String, description: String, voteLimit: Int, expirationDate: Double, imageSrc: String? = nil, isAnonymous: Bool = false, isEnabled: Bool = true) {
      self.title = title
      self.description = description
      self.imageSrc = imageSrc
      self.voteLimit = voteLimit
      self.isAnonymous = isAnonymous
      self.expirationDate = expirationDate
      self.isEnabled = isEnabled
    }

    var isExpired: Bool {
      return self.expirationDate > Date().timeIntervalSince1970
    }

  }

}

extension Models.Poll: Content { }
extension Models.Poll: Migration { }
extension Models.Poll: Parameter { }

// MARK: Contents
extension Models.Poll {

  // Requests
  struct CreateRequest: Content {
    let title: String
    let description: String
    let imageSrc: String?
    let voteLimit: Int
    let isAnonymous: Bool
    let expirationDate: Double
    let isEnabled: Bool

    func poll() -> Models.Poll {
      return Models.Poll(title: self.title, description: self.description, voteLimit: self.voteLimit, expirationDate: self.expirationDate, imageSrc: self.imageSrc, isAnonymous: self.isAnonymous, isEnabled: self.isEnabled)
    }

  }

  struct UpdateRequest: Content {
    let title: String?
    let description: String?
    let imageSrc: String?
    let voteLimit: Int?
    let isAnonymous: Bool?
    let expirationDate: Double?
    let isEnabled: Bool?
  }

  // Responses

  struct Public: Content {
    var id: UUID?
    var title: String
    var description: String
    var imageSrc: String?
    var voteLimit: Int
    var isAnonymous: Bool
    var expirationDateEpoch: Double
    var pollItems: [Models.PollItem.Public]
    var totalVotes: Int
  }

  func `public`(on req: Request, for userId: Models.User.ID) throws -> Future<Models.Poll.Public> {    
    return try self.pollItems.query(on: req).all().flatMap { pItems in
      return try pItems.map { try $0.public(for: userId, req)}.flatten(on: req)
      }.flatMap(to: Models.Poll.Public.self) { pItems in
      return try self.votes.query(on: req).all()
        .map { votes in
          let voteCount = Array(Set(votes.map { $0.userId })).count          
          return Public(id: self.id, title: self.title, description: self.description, imageSrc: self.imageSrc, voteLimit: self.voteLimit, isAnonymous: self.isAnonymous, expirationDateEpoch: self.expirationDate * 1000.0, pollItems: pItems, totalVotes: voteCount)
      }

    }

  }

}

extension Models.Poll {

  func didCreate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Poll> {
    return conn.future(self).always {
      PushService.shared.sendPollUpdate(on: conn)
    }
  }

  func didUpdate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Poll> {
    return conn.future(self).always {
      PushService.shared.sendPollUpdate(on: conn)
    }
  }

  func didDelete(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Poll> {

    return try self.pollItems.query(on: conn).delete(force: true)
      .flatMap { return try self.votes.query(on: conn).delete(force: true).map { self } }
      .always {  PushService.shared.sendPollUpdate(on: conn) }
  }

}

// MARK: Relationships
extension Models.Poll {

  var pollItems: Children<Models.Poll, Models.PollItem> {
    return children(\.pollId)
  }

  var votes: Children<Models.Poll, Models.Vote> {
    return children(\.pollId)
  }

}


// MARK: - Poll Item -

extension Models {

  final class PollItem: PostgreSQLUUIDModel {
    var id: UUID?
    var title: String
    var imageSrc: String?
    var pollId: Models.Poll.ID

    init(title: String, pollId: Models.Poll.ID, imageSrc: String? = nil) {
      self.title = title
      self.pollId = pollId
      self.imageSrc = imageSrc
    }
  }

}

extension Models.PollItem: Content { }
extension Models.PollItem: Migration { }
extension Models.PollItem: Parameter { }

// MARK: Contents
extension Models.PollItem {

  // Request

  struct CreateRequest: Content {
    var title: String
    var imageSrc: String?
    func pollItem(pollId: Models.Poll.ID) -> Models.PollItem {
      return Models.PollItem(title: self.title, pollId: pollId, imageSrc: self.imageSrc)
    }
  }

  struct UpdateRequest: Content {
    var title: String?
    var imageSrc: String?
  }

  // Response
  struct Public: Content {
    var id: UUID?
    var title: String
    var imageSrc: String?
    var votesCount: Int
    var isVoted: Bool
  }

  func `public`(for userId: Models.User.ID, _ req: Request) throws -> Future<Models.PollItem.Public> {

    return try self.votes.query(on: req).all().map { itemVotes in
      let votesCount = itemVotes.count
      let isVoted = itemVotes.first() { $0.userId == userId } != nil
      return Public(id: self.id, title: self.title, imageSrc: self.imageSrc, votesCount: votesCount, isVoted: isVoted)
    }

  }

//  var `public`: Public {
//    return Public(id: self.id, title: self.title, imageSrc: self.imageSrc)
//  }

  func didUpdate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.PollItem> {
    return conn.future(self).always {
      PushService.shared.sendPollUpdate(on: conn)
    }
  }

  func didCreate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.PollItem> {
    return conn.future(self).always {
      PushService.shared.sendPollUpdate(on: conn)
    }
  }

  func didDelete(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.PollItem> {

    return try self.votes.query(on: conn).delete(force: true).map { self }
      .always {
      PushService.shared.sendPollUpdate(on: conn)
    }
  }

}

// MARK: Relationships
extension Models.PollItem {

  var poll: Parent<Models.PollItem, Models.Poll> {
    return parent(\.pollId)
  }

  var votes: Children<Models.PollItem, Models.Vote> {
    return children(\.itemId)
  }

}


// MARK: - Vote -

extension Models {

  final class Vote: PostgreSQLUUIDModel {
    var id: UUID?
    var userId: User.ID
    var pollId: Poll.ID
    var itemId: PollItem.ID
    var voteDate: Date

    init(userId: User.ID, pollId: Poll.ID, itemId: PollItem.ID) {
      self.userId = userId
      self.pollId = pollId
      self.itemId = itemId
      self.voteDate = Date()
    }

  }

}

extension Models.Vote: Migration { }

// MARK: Interface

extension Models.Vote {

  struct Input: Content {
    let itemId: Models.PollItem.ID

    func vote(for userId: Models.User.ID, on pollId: Models.Poll.ID) -> Models.Vote {
      return Models.Vote(userId: userId, pollId: pollId, itemId: self.itemId)
    }
  }

}

// MARK: Relationships

extension Models.Vote {

  var user: Parent<Models.Vote, Models.User> {
    return parent(\.userId)
  }

  var poll: Parent<Models.Vote, Models.Poll> {
    return parent(\.pollId)
  }

  var pollItem: Parent<Models.Vote, Models.User> {
    return parent(\.itemId)
  }
}

// MARK: Notifications


extension Models.Vote {

  func didCreate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Vote> {
    return conn.future(self).always {
      PushService.shared.sendPollUpdate(on: conn)
    }
  }

  func didDelete(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Vote> {
    return conn.future(self).always {
      PushService.shared.sendPollUpdate(on: conn)
    }
  }  

}

