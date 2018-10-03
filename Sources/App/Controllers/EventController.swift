//
//  EventController.swift
//  App
//
//  Created by Ala Kiani on 10/1/18.
//

import Vapor

private let rootPathComponent = "event"

struct EventRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped(Models.User.tokenAuthMiddleware())
    tokenGroup.post(Models.Event.self, use: EventController.create)
    tokenGroup.get(use: EventController.list)
    tokenGroup.get(Models.Event.parameter, use: EventController.item)
    tokenGroup.put(Models.Event.parameter, use: EventController.update)
  }
}

enum EventController {
  
  static func create(_ req: Request, event: Models.Event) throws -> Future<Models.Event> {
    return event.save(on: req)
  }
  
  static func list(_ req: Request) throws -> Future<[Models.Address]> {
    return Models.Address.query(on: req).all()
  }
  
  static func item(_ req: Request) throws -> Future<Models.Address> {
    return try req.parameters.next(Models.Address.self)
  }
  
  static func update(_ req: Request) throws -> Future<Models.Address> {
    fatalError()
  }
}
