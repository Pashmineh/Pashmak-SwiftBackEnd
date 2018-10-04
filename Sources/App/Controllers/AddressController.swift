//
//  AddressController.swift
//  App
//
//  Created by Ala Kiani on 10/3/18.
//

import Vapor

private let rootPathComponent = "address"

struct AddressRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped([Models.User.tokenAuthMiddleware(), Models.User.guardAuthMiddleware()])
    tokenGroup.post(Models.Address.self, use: AddressController.create)
    tokenGroup.get(use: AddressController.list)
    tokenGroup.get(Models.Transaction.parameter, use: AddressController.item)
    tokenGroup.put(Models.Transaction.parameter, use: AddressController.update)
  }
}

enum AddressController {
  
  static func create(_ req: Request, address: Models.Address) throws -> Future<Models.Address> {
    return address.save(on: req)
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
