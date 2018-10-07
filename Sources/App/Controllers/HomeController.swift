//
//  HomeController.swift
//  App
//
//  Created by Mohammad Porooshani on 10/6/18.
//

import Vapor

private let rootPathComponent = "home"

struct HomeRoutesCollection: RouteCollection {

  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped([Models.User.tokenAuthMiddleware(), Models.User.guardAuthMiddleware()])
    tokenGroup.get("", use: HomeController.list)
  }

}

enum HomeController {

  static func list(_ req: Request) throws -> Future<Models.Home> {
    let user = try req.requireAuthenticated(Models.User.self)
    return Models.Event.query(on: req).filter(\Models.Event.isEnabled, .equal, true).all()
      .flatMap { $0.map { $0.convertToPublic(on: req)}.flatten(on: req) }.map {
        Models.Home(user: user, events: $0)
    }
  }

}
