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
    tokenGroup.get(Models.Address.parameter, use: AddressController.item)
    tokenGroup.put(Models.Address.parameter, use: AddressController.update)
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
    return try req.content.decode(Models.Address.UpdateRequest.self).flatMap(to: Models.Address.self) { updateRequest in
      return try req.parameters.next(Models.Address.self).flatMap(to: Models.Address.self) { address in
        address.title = updateRequest.title ?? address.title
        address.street = updateRequest.street ?? address.street
        address.mapImageURL = updateRequest.mapImageURL ?? address.mapImageURL
        address.lat = updateRequest.lat ?? address.lat
        address.long = updateRequest.long ?? address.long
        return address.save(on: req)
      }
    }
  }
}
