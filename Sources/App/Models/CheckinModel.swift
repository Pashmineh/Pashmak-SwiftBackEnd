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

/*
{
  "checkinTime": "2018-10-01T12:09:47.712Z",
  "checkinTimeEpoch": 0,
  "checkinType": "MANUAL",
  "id": 0,
  "message": "string",
  "userId": 0,
  "userLogin": "string"
}
*/

final class Checkin: PostgreSQLModel {

  enum CheckinType: String, Codable {
    case manual = "MANUAL"
    case iBeacon = "IBEACON"
  }

  var id: Int?

  var checkinTime: Date
  var checkinType: String

  var userId: Int

  init(id: Int? = nil, checkinTime: Date, checkinType: CheckinType, userId: Int) {
    self.id = id
    self.checkinTime = checkinTime
    self.checkinType = checkinType.rawValue
    self.userId = userId
  }

}

extension Checkin: Content {}
extension Checkin: Migration {}
extension Checkin: Parameter {}

/*
final class Debt: PostgreSQLModel {

  /// User's unique identifier.
  /// Can be `nil` if the user has not been saved yet.
  var id: Int?

  var amount: UInt64
  var paymentTime: String
  var reason: String
  var userId: Int
  var userLogin: String

  enum Reason: String, Codable {
    case TAKHIR
    case SHIRINI
    case JALASE
  }

  init(id: Int? = nil, amount: UInt64, paymentTime: String, reason: Reason, userId: Int, userLogin: String) {
    self.id = id
    self.amount = amount
    self.paymentTime = paymentTime
    self.reason = reason.rawValue
    self.userId = userId
    self.userLogin = userLogin
  }

}


/// Allows `Debt` to be encoded to and decoded from HTTP messages.
extension Debt: Content { }

/// Allows `Debt` to be Migrated
extension Debt: Migration { }

/// Allows `Debt` to be used as a dynamic parameter in route definitions.
extension Debt: Parameter { }
*/
