//
//  TransactionController.swift
//  App
//
//  Created by Mohammad Porooshani on 10/2/18.
//

import Vapor

/*
 - insert
 - list
 - item
 - update
*/

private let rootPathComponent = "transaction"

struct TransacrionRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(User.tokenAuthMiddleware())
    tokenGroup.post(rootPathComponent, use: TransactionController.create)
    tokenGroup.get(rootPathComponent, use: TransactionController.get)
  }
}

enum TransactionController {

  static func create(_ req: Request) throws -> Future<Models.Transaction> {
    fatalError("Not implemented")
  }

  static func get(_ req: Request) throws -> Future<HTTPResponse> {
    fatalError("Not implemented")
  }

}




