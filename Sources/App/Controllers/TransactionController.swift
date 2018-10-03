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

  static func create(_ req: Request, createRequest: Models.Transaction.CreateRequest) throws -> Future<Models.Transaction.Public> {
    let user = try req.requireAuthenticated(Models.User.self)
    let userID = try user.requireID()

    return addNewTransaction(userID: userID, createRequest: createRequest, on: req)
      .do { trans in
        let reason = Models.Transaction.Reason(rawValue: trans.reason) ?? .TAKHIR
        let amountNum = NSNumber(value: trans.amount)
        let amount = Formatters.RialFormatterWithRial.string(from: amountNum) ?? "\(trans.amount)"


        let message = (reason == .Payment)
        ?
        PushService.Message(title: "پشمک", body: "پرداخت مبلغ \(amount) ثبت شد.", subtitle: "ثبت پرداختی")
        :
        PushService.Message(title: "پشمک", body: "بدهی به مبلغ \(amount) به دلیل \(reason.title)", subtitle: "اعلام بدهی")

        let updateMsg = PushService.UpdateMessage(type: .transaction, event: .create)

        do {
          try PushService.shared.send(message: message, to: [user], on: req)
          try PushService.shared.send(message: updateMsg, to: [user], on: req)
        }
        catch {
          print("Error sending push.\n\(error.localizedDescription)")
        }
      }.map(to: Models.Transaction.Public.self) { return $0.public }

  }

  static func addNewTransaction(userID: Models.User.ID, createRequest: Models.Transaction.CreateRequest, on conn: DatabaseConnectable) -> Future<Models.Transaction> {
    return createRequest.transaction(for: userID).save(on: conn)
  }

  static func list(_ req: Request) throws -> Future<[Models.Transaction.Public]> {
    let user = try req.requireAuthenticated(Models.User.self)
    return try user.transactions.query(on: req).sort(\.date, .descending).decode(data: Models.Transaction.Public.self).all()
  }

  static func item(_ req: Request) throws -> Future<Models.Transaction.Public> {
    return try req.parameters.next(Models.Transaction.self)
      .map(to: Models.Transaction.Public.self) { $0.public }
  }

  static func update(_ req: Request) throws -> Future<Models.Transaction.Public> {
    let user = try req.requireAuthenticated(Models.User.self)
    return try req.parameters.next(Models.Transaction.self)
      .flatMap(to: Models.Transaction.Public.self) { oldTrans in
        return try req.content.decode(Models.Transaction.UpdateRequest.self)
          .flatMap(to: Models.Transaction.Public.self) { changes in
          if let isValid = changes.isValid {
            oldTrans.isValid = isValid
          }
          if let message = changes.message {
            oldTrans.message = message
          }
          return oldTrans.save(on: req).map(to: Models.Transaction.Public.self){ return $0.public }
            .do { trans in

              let msg = PushService.UpdateMessage(type: .transaction, event: .update)
              do {
                try PushService.shared.send(message: msg, to: [user], on: req)
              } catch {
                print("Could not send update push.")
              }

            }.always {
              do {
                try user.updateBalance(req)
              } catch {
                print("Error updating balance")
              }
            }

        }
    }
  }
}




