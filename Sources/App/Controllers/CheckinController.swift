//
//  CheckinController.swift
//  App
//
//  Created by Mohammad Porooshani on 10/1/18.
//

import Vapor
import FluentPostgreSQL
import SwiftDate

private let kTodayFormatter = DateFormatter.englishDateFormatterForTehran(with: "YYYY/MM/dd")
private let kMessageDateFormatter = DateFormatter.farsiDateFormatter(with: "EEEE dd MMMM YYYY ساعت HH:mm")
private let rootPathComponent = "checkin"

struct CheckinRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped([Models.User.tokenAuthMiddleware(), Models.User.guardAuthMiddleware()])
    tokenGroup.post(Models.Checkin.CreateRequest.self, use: CheckinController.create)
    tokenGroup.get(use: CheckinController.list)
    tokenGroup.get(Models.Checkin.parameter, use: CheckinController.item)
//    tokenGroup.put(Models.Transaction.parameter, use: TransactionController.update)

  }
}

enum CheckinController {
  
  static func create(_ req: Request, createRequest: Models.Checkin.CreateRequest) throws -> Future<Models.Checkin.Public> {
    let user = try req.requireAuthenticated(Models.User.self)
    let userID = try user.requireID()
    let refDate = Date()

    return try isCheckinReported(req, on: refDate, for: user).flatMap(to: Models.Checkin.Public.self) { isReported in
      guard !isReported else {
        throw Abort(.alreadyReported)
      }


      return req.transaction(on: .psql) { conn in
        func addCheckin() -> Future<Models.Checkin.Public> {
          return createRequest.checkin(for: userID, on: refDate.timeIntervalSince1970).save(on: conn).map(to: Models.Checkin.Public.self) { return $0.public }
            .do { _ in
              let updateMsg = PushService.UpdateMessage(type: .checkin, event: .create)
              do {
                try PushService.shared.send(message: updateMsg, to: [user], on: req)
              } catch {
                print("error sending checkin update notif.\n\(error.localizedDescription)")
              }
            }
        }

        if refDate.hourInTehran ?? 0 >= 10 {
          let reason = Models.Transaction.Reason.TAKHIR
          let dateString = kMessageDateFormatter.string(from: refDate)
          let amountNum = NSNumber(value:abs(reason.amount))
          let amount = Formatters.RialFormatterWithRial.string(from: amountNum) ?? "\(reason.amount)"
          let message = "جریمه تاخیر ورود در \(dateString) به مبلغ \(amount) ثبت شد."
          let penalty = Models.Transaction.CreateRequest.init(amount: reason.amount, reason: reason, message: message)
          return TransactionController.addNewTransaction(userID: userID, createRequest: penalty, on: conn).flatMap { _ in
            return addCheckin()
              .do { _ in
                do {
                  let msg = PushService.Message(title: "ثبت تاخیر", body: message, subtitle: nil)
                  try PushService.shared.send(message: msg, to: [user], on: req)
                } catch {
                  print("Error sending penalty message.\n\(error.localizedDescription)")
                }
            }
          }
        } else {
          return addCheckin()
        }

      }

    }
    
  }

  static func isCheckinReported(_ req: Request, on refDate: Date, for user: Models.User) throws -> Future<Bool> {

    let today = Date()
    let todayString = kTodayFormatter.string(from: today)

    return try user.checkins.query(on: req).sort(\.checkinTime, .descending).first().map(to: Bool.self) {
      guard let checkinDate = $0?.checkinTime else {
        return false
      }

      let chDate = Date(timeIntervalSince1970: checkinDate)
      let lastDateString = kTodayFormatter.string(from: chDate)
      return todayString == lastDateString
    }

  }

  static func list(_ req: Request) throws -> Future<[Models.Checkin.Public]> {
    let user = try req.requireAuthenticated(Models.User.self)
    return try user.checkins.query(on: req).sort(\.checkinTime, .descending).decode(data: Models.Checkin.Public.self).all()
  }

  static func item(_ req: Request) throws -> Future<Models.Checkin.Public> {
    return try req.parameters.next(Models.Checkin.self).map(to: Models.Checkin.Public.self) { $0.public }
  }

}


