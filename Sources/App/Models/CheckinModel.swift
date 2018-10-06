//
//  CheckinModel.swift
//  App
//
//  Created by Mohammad Porooshani on 10/1/18.
//

import Foundation
import FluentPostgreSQL
import Vapor
import JWT

extension Models {

  final class Checkin: PostgreSQLUUIDModel {

    enum CheckinType: String, Codable {
      case manual = "MANUAL"
      case iBeacon = "IBEACON"
    }

    var id: UUID?
    var checkinTime: Double
    var checkinType: String
    var userId: Models.User.ID

    init(checkinTime: Double, checkinType: CheckinType, userId: UUID) {      
      self.checkinTime = checkinTime
      self.checkinType = checkinType.rawValue
      self.userId = userId
    }

  }
}
extension Models.Checkin: Content {}
extension Models.Checkin: Migration {}
extension Models.Checkin: Parameter {}

extension Models.Checkin {
  // Data Required to create a Debt
  struct CreateRequest: Content {

    var checkinType: Models.Checkin.CheckinType

    func checkin(for userId: UUID, on date: Double) -> Models.Checkin {
      return Models.Checkin(checkinTime: date, checkinType: self.checkinType, userId: userId)
    }
  }

  struct Public: Content {
    var id: Models.Checkin.ID?
    var checkinType: String
    var checkinTime: Double

  }

  var `public`: Public {
    return Public(id: self.id, checkinType: self.checkinType, checkinTime: self.checkinTime * 1000)
  }
}

extension Models.Checkin {
  var user: Parent<Models.Checkin, Models.User> {
    return parent(\.userId)
  }
}
