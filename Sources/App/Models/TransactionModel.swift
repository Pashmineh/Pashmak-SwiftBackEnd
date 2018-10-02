//
//  TransactionModel.swift
//  App
//
//  Created by Mohammad Porooshani on 10/2/18.
//

import FluentPostgreSQL
import Vapor

extension Models {
  final class Transaction: PostgreSQLUUIDModel {
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

    var id: UUID?
    var userId: User.ID
    var amount: Int64
    var date: Double
    var reason: String
    var message: String?
    var isValid: Bool

    var user: Parent<Transaction, User> {
      return parent(\.userId)
    }


  }
}

/// Allows `Debt` to be encoded to and decoded from HTTP messages.
extension Models.Transaction: Content { }

/// Allows `Debt` to be Migrated
extension Models.Transaction: Migration { }

/// Allows `Debt` to be used as a dynamic parameter in route definitions.
extension Models.Transaction: Parameter { }
