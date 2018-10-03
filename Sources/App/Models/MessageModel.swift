//
//  MessageModel.swift
//  App
//
//  Created by Mohammad Porooshani on 10/3/18.
//

import FluentPostgreSQL
import Vapor

extension Models {

  final class Message: PostgreSQLUUIDModel {
    var id: UUID?
    var userId: User.ID
    var title: String
    var body: String
    var date: Double

    init(userId:User.ID, title: String, body: String, date: Date) {
      self.userId = userId
      self.title = title
      self.body = body
      self.date = date.timeIntervalSince1970
    }
  }

}

extension Models.Message: Content { }
extension Models.Message: Migration { }
extension Models.Message: Parameter { }

// MARK: Contents
extension Models.Message {

  // Requests
  struct createRequest: Content {
    var title: String
    var body: String
    var userId: Models.User.ID

    func message(for userId: Models.User.ID) -> Models.Message {
      return Models.Message(userId: userId, title: self.title, body: self.body, date: Date())
    }
  }

  // Responses

  struct Public: Content {
    var title: String
    var body: String
    var date: Double
    var id: Models.Message.ID?

  }

  var `public`: Models.Message.Public {
    return Models.Message.Public(title: self.title, body: self.body, date: self.date, id: self.id)
  }

}

// MARK: Relationships
extension Models.Message {

  var user: Parent<Models.Message, Models.User> {
    return parent(\.userId)
  }

}
