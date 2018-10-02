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
    return try req.content.decode(CreateDebtRequest.self).flatMap(to: Debt.self) { createRequest in
      return try self.insertDebt(req, reason: createRequest.reason, amount: createRequest.amount)
    }
  }
  
  func insertDebt(_ req: Request, reason: Debt.Reason, amount: UInt64 = 0) throws -> Future<Debt> {
    let user = try req.requireAuthenticated(Models.User.self)
    return try Debt(amount: amount == 0 ? reason.amount : amount,
                    paymentTime: Date(),
                    reason: reason,
                    userId: user.requireID())
      .save(on: req)
      .do { debt in
        let reason = Debt.Reason(rawValue: debt.reason) ?? .TAKHIR
        let amountNum = NSNumber(value: debt.amount)
        let amount = Formatters.RialFormatterWithRial.string(from: amountNum) ?? "\(debt.amount)"
//        let message = PushService.Message(title: "پشمک", body: "بدهی به مبلغ \(amount) به دلیل \(reason.title)", subtitle: "اعلام بدهی")
        do {
//          try PushService.shared.send(message: message, to: [user], on: req)
        }
        catch {
          print("Error sending push.\n\(error.localizedDescription)")
        }

      }

  }
}

// MARK: Content

// Data Required to create a Debt
struct CreateDebtRequest: Content {
  var amount: UInt64
  var reason: Debt.Reason
}
