//
//  TransactionController.swift
//  App
//
//  Created by Mohammad Porooshani on 10/2/18.
//

import Vapor

private let rootPathComponent = "transaction"

struct TransacrionRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped(Models.User.tokenAuthMiddleware())
    tokenGroup.post(Models.Transaction.CreateRequest.self, use: TransactionController.create)
    tokenGroup.get(use: TransactionController.list)
    tokenGroup.get(Models.Transaction.parameter, use: TransactionController.item)
    tokenGroup.put(Models.Transaction.parameter, use: TransactionController.update)

  }
}

enum TransactionController {

  static func create(_ req: Request, createRequest: Models.Transaction.CreateRequest) throws -> Future<Models.Transaction> {
    let user = try req.requireAuthenticated(Models.User.self)
    let userID = try user.requireID()

    return createRequest.transaction(for: userID)
    .save(on: req)
      .do { trans in
        let reason = Models.Transaction.Reason(rawValue: trans.reason) ?? .TAKHIR
        let amountNum = NSNumber(value: trans.amount)
        let amount = Formatters.RialFormatterWithRial.string(from: amountNum) ?? "\(trans.amount)"


        let message = (reason == .Payment)
        ?
        PushService.Message(title: "پشمک", body: "پرداخت مبلغ \(amount) ثبت شد.", subtitle: "ثبت پرداختی")
        :
        PushService.Message(title: "پشمک", body: "بدهی به مبلغ \(amount) به دلیل \(reason.title)", subtitle: "اعلام بدهی")

        do {
          try PushService.shared.send(message: message, to: [user], on: req)
        }
        catch {
          print("Error sending push.\n\(error.localizedDescription)")
        }
      }

  }

  static func list(_ req: Request) throws -> Future<[Models.Transaction]> {
    fatalError("Not implemented")
  }

  static func item(_ req: Request) throws -> Future<Models.Transaction> {
    fatalError("Not implemented")
  }

  static func update(_ req: Request) throws -> Future<Models.Transaction> {
    fatalError("Not implemented")
  }
}




