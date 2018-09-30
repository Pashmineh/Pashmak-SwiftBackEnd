//
//  DebtController.swift
//  App
//
//  Created by Ala Kiani on 9/30/18.
//

import Crypto
import Vapor
import FluentPostgreSQL

/// Creates new users and logs them in.
final class DebtController {
  
  func create(_ req: Request) throws -> Future<Debt> {
    let user = try req.requireAuthenticated(User.self)
    return try req.content.decode(CreateDebtRequest.self).flatMap(to: Debt.self) { createRequest in
      return try Debt(amount: createRequest.amount, paymentTime: createRequest.paymentTime, reason: createRequest.reason, userId: user.requireID(), userLogin: "").save(on: req)
    }
  }
  
}

// MARK: Content

// Data Required to create a Debt
struct CreateDebtRequest: Content {
  var amount: UInt64
  var paymentTime: String
  var reason: Debt.Reason
}
