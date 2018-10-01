//
//  CheckinController.swift
//  App
//
//  Created by Mohammad Porooshani on 10/1/18.
//

import Vapor
import FluentPostgreSQL

final class CheckinController {
  
  func create(_ req: Request) throws -> Future<HTTPStatus> {
    let user = try req.requireAuthenticated(User.self)

    // TODD: Check already checkin
    // TODO: Add Penalty

    return try req.content.decode(CreateCheckinRequest.self).flatMap(to: Checkin.self) { createReq in
      return try Checkin(checkinTime: Date(), checkinType: createReq.checkinType, userId: user.requireID()).save(on: req)
      }.flatMap(to: HTTPStatus.self) { _ in
        return req.future(.created)
    }
  }

  func getAll(_ req: Request) throws -> Future<[CheckinResponse]> {
    let user = try req.requireAuthenticated(User.self)
    return try Checkin.query(on: req).filter(\.userId == user.requireID()).all().flatMap(to: [CheckinResponse].self) { checkins in
      var result: [CheckinResponse] = []
      checkins.forEach {
        result.append(CheckinResponse(checkinType: Checkin.CheckinType(rawValue: $0.checkinType) ?? .manual, chckinTime: $0.checkinTime.timeIntervalSince1970, id: $0.id, userId: $0.userId))
      }
      return req.future(result)
    }
  }

  func getCheckin(_ req: Request) throws -> Future<CheckinResponse> {
    let user = try req.requireAuthenticated(User.self)
    return try req.parameters.next(Checkin.self).flatMap(to: CheckinResponse.self) { checkin in
      let userID = try user.requireID()
      if checkin.userId != userID {
        throw Abort(.notFound)
      }

      let checkinContent = CheckinResponse(checkinType: Checkin.CheckinType(rawValue: checkin.checkinType) ?? .manual , chckinTime: checkin.checkinTime.timeIntervalSince1970, id: checkin.id, userId: checkin.userId)
      return req.future(checkinContent)
    }

  }

}

// MARK: Content

// Data Required to create a Debt
struct CreateCheckinRequest: Content {
  var checkinType: Checkin.CheckinType
}

struct CheckinResponse: Content {
  var checkinType: Checkin.CheckinType
  var chckinTime: Double
  var id: Int?
  var userId: Int
}
