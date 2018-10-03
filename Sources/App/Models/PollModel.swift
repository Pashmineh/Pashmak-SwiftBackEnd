//
//  PollModel.swift
//  App
//
//  Created by Mohammad Porooshani on 10/3/18.
//

import FluentPostgreSQL
import Vapor

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

  // Responses

  struct Public: Content {
    var id: UUID?
    var title: String
    var description: String
    var imageSrc: String?
    var voteLimit: Int
    var isAnonymous: Bool
    var expirationDate: Double

  }

  var `public`: Public {
    return Public(id: self.id, title: self.title, description: self.description, imageSrc: self.imageSrc, voteLimit: self.voteLimit, isAnonymous: self.isAnonymous, expirationDate: self.expirationDate)
  }

}

// MARK: Relationships
extension Models.Poll {

}
