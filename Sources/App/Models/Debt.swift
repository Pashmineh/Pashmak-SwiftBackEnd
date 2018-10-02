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
  var paymentTime: Date
  var reason: String
  var userId: Int
  
  enum Reason: String, Codable {
    case TAKHIR
    case SHIRINI
    case JALASE
    var amount: UInt64 {
      switch self {
      case .JALASE:
        return 50000
      case .SHIRINI:
        return 500000
      case .TAKHIR:
        return 50000
      }
    }
    var title: String {
      switch self {
      case .JALASE:
        return "تاخیر حضور در جلسه"
      case .SHIRINI:
        return "شیرینی خرید"
      case .TAKHIR:
        return "تاخیر ورود به شرکت"
      }
    }
  }
  
  init(id: Int? = nil, amount: UInt64, paymentTime: Date, reason: Reason, userId: Int) {
    self.id = id
    self.amount = amount
    self.paymentTime = paymentTime
    self.reason = reason.rawValue
    self.userId = userId
  }
  
}


/// Allows `Debt` to be encoded to and decoded from HTTP messages.
extension Debt: Content { }

/// Allows `Debt` to be Migrated
extension Debt: Migration { }

/// Allows `Debt` to be used as a dynamic parameter in route definitions.
extension Debt: Parameter { }
