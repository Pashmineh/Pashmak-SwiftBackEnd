//
//  PollController.swift
//  App
//
//  Created by Mohammad Porooshani on 10/3/18.
//

import Vapor

private let rootPathComponent = "poll"

struct PollRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped(Models.User.tokenAuthMiddleware())
    tokenGroup.post(Models.Poll.CreateRequest.self, use: PollController.create)
    tokenGroup.get(use: PollController.list)
    tokenGroup.get(Models.Poll.parameter, use: PollController.item)
//    tokenGroup.put(Models.Poll.parameter, use: PollController)
  }
}

enum PollController {

  static func create(_ req: Request, createRequest: Models.Poll.CreateRequest) throws -> Future<Models.Poll.Public> {
    return createRequest.poll().save(on: req).map { $0.public }
  }

  static func list(_ req: Request) throws -> Future<[Models.Poll.Public]> {
    return Models.Poll.query(on: req).filter(\Models.Poll.isEnabled, .equal, true).all().map(to: [Models.Poll.Public].self) { $0.map{ $0.public } }

    /*
    let promise = req.eventLoop.newPromise([Models.Poll.Public].self)
    DispatchQueue.global().async {
      let result = (try? Models.Poll.query(on: req).filter(\Models.Poll.isEnabled, .equal, true).all().map(to: [Models.Poll.Public].self) { $0.map{ $0.public } }.wait() ) ?? []
      promise.succeed(result: result)
    }
    return promise.futureResult
     */

  }

  static func item(_ req: Request) throws -> Future<Models.Poll.Public> {
    return try req.parameters.next(Models.Poll.self).map { $0.public }
  }

}
