//
//  Debt.swift
//  App
//
//  Created by Ala Kiani on 9/30/18.
//

import Authentication
import FluentPostgreSQL
import Vapor
import JWT

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
