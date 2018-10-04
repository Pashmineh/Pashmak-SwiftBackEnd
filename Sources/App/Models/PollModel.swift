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
    var expirationDate: Double
    var pollItems: [Models.PollItem.Public]
  }

  func `public`(on req: Request) throws -> Future<Models.Poll.Public> {

    return try self.pollItems.query(on: req).all().map(to: Models.Poll.Public.self) {
      let polltems = $0.map { $0.public }
      return Public(id: self.id, title: self.title, description: self.description, imageSrc: self.imageSrc, voteLimit: self.voteLimit, isAnonymous: self.isAnonymous, expirationDate: self.expirationDate, pollItems: polltems)
    }

  }

}

extension Models.Poll {

  func didCreate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Poll> {
    return Models.User.query(on: conn).all().flatMap(to: Models.Poll.self) { users in
      return conn.future(self).do { _ in
        self.sendUpdate(to: users, on: conn)
      }
    }
  }

  func didUpdate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Poll> {
    return Models.User.query(on: conn).all().flatMap(to: Models.Poll.self) { users in
      return conn.future(self).do { _ in
        self.sendUpdate(to: users, on: conn)
      }
    }
  }

  func didDelete(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Poll> {
    return Models.User.query(on: conn).all().flatMap(to: Models.Poll.self) { users in
      return conn.future(self).do { _ in
        self.sendUpdate(to: users, on: conn)
      }
    }
  }

  func sendUpdate(to users: [Models.User], on conn: DatabaseConnectable) {
    let updateMessage = PushService.UpdateMessage.init(type: .poll, event: .update)
    do {
      try PushService.shared.send(message: updateMessage, to: users, on: conn)
    } catch {
      print("Error sending update message for poll.\n\(error.localizedDescription)")
    }
  }
}

// MARK: Relationships
extension Models.Poll {

  var pollItems: Children<Models.Poll, Models.PollItem> {
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
  }

  var `public`: Public {
    return Public(id: self.id, title: self.title, imageSrc: self.imageSrc)
  }

  func didUpdate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.PollItem> {
    return Models.User.query(on: conn).all().flatMap(to: Models.PollItem.self) { users in
      return conn.future(self).do { _ in
        self.sendUpdate(to: users, on: conn)
      }
    }
  }

  func didCreate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.PollItem> {
    return Models.User.query(on: conn).all().flatMap(to: Models.PollItem.self) { users in
      return conn.future(self).do { _ in
        self.sendUpdate(to: users, on: conn)
      }
    }
  }

  func didDelete(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.PollItem> {
    return Models.User.query(on: conn).all().flatMap(to: Models.PollItem.self) { users in
      return conn.future(self).do { _ in
        self.sendUpdate(to: users, on: conn)
      }
    }
  }

  func sendUpdate(to users: [Models.User], on conn: DatabaseConnectable) {
    let updateMessage = PushService.UpdateMessage.init(type: .poll, event: .update)
    do {
      try PushService.shared.send(message: updateMessage, to: users, on: conn)
    } catch {
      print("Error sending update message for poll.\n\(error.localizedDescription)")
    }
  }

}

// MARK: Relationships
extension Models.PollItem {

  var poll: Parent<Models.PollItem, Models.Poll> {
    return parent(\.pollId)
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
