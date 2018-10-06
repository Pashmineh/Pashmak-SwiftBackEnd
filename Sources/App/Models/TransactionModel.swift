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
      case Payment
      var amount: Int64 {
        switch self {
        case .JALASE:
          return -50000
        case .SHIRINI:
          return -500000
        case .TAKHIR:
          return -50000
        case .Payment:
          return 0
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
        case .Payment:
          return "پرداخت بدهی"
        }
      }

      var defaultValid: Bool {
        switch self {
        case .JALASE, .TAKHIR, .SHIRINI:
          return true
        case .Payment:
          return false
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

    init(userId: User.ID, amount: Int64, reason: Reason, isValid: Bool , message: String? = nil) {
      self.userId = userId
      self.amount = amount
      self.reason = reason.rawValue
      self.isValid = isValid
      self.message = message
      self.date = Date().timeIntervalSince1970
    }

    struct CreateRequest: Content {
      var amount: Int64
      var reason: Reason
      var message: String?

      func transaction(for userID: User.ID) -> Transaction {
        return Transaction(userId: userID, amount: self.amount, reason: self.reason, isValid: reason.defaultValid, message: self.message)
      }
    }

    struct Public: Content {
      var id: Transaction.ID?
      var amount: Int64
      var reason: String
      var message: String?
      var isValid: Bool
      var date: Double

    }

    var `public`: Public {
      return Public(id: self.id, amount: self.amount, reason: self.reason, message: self.message, isValid: self.isValid, date: self.date)
    }

    struct UpdateRequest: Content {
      var message: String?
      var isValid: Bool?
    }
  }
}

extension Models.Transaction {

  func didCreate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Transaction> {
    return self.user.query(on: conn).first().map {
      do {
        try $0?.updateBalance(conn)
      } catch {
        print("Could not update Balance.")
      }

      return self
    }
  }

  func didUpdate(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Transaction> {
    return self.user.query(on: conn).first().map {
      do {
        try $0?.updateBalance(conn)
      } catch {
        print("Could not update Balance.")
      }

      return self
    }

  }

  func didDelete(on conn: PostgreSQLConnection) throws -> EventLoopFuture<Models.Transaction> {
    return self.user.query(on: conn).first().map {
      do {
        try $0?.updateBalance(conn)
      } catch {
        print("Could not update Balance.")
      }

      return self
    }

  }

}

/// Allows `Debt` to be encoded to and decoded from HTTP messages.
extension Models.Transaction: Content { }

/// Allows `Debt` to be Migrated
extension Models.Transaction: Migration { }

/// Allows `Debt` to be used as a dynamic parameter in route definitions.
extension Models.Transaction: Parameter { }

extension Models.Transaction {
  var user: Parent<Models.Transaction, Models.User> {
    return parent(\.userId)
  }
}

