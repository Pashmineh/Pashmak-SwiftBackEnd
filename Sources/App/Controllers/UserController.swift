//
//  UserController.swift
//  App
//
//  Created by Ala Kiani on 9/30/18.
//

import Crypto
import Vapor
import FluentPostgreSQL
import Redis


private let rootPathComponent = "user"

struct UserRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let baseRouter = router.grouped(rootPathComponent)
    let openGroup = baseRouter.grouped("/")
    let basicGroup = router.grouped("login").grouped(Models.User.basicAuthMiddleware(using: BCryptDigest()))
    let logOutRoute = router.grouped("logout").grouped(Models.User.tokenAuthMiddleware())
    let profileRoute = router.grouped("profile").grouped(Models.User.tokenAuthMiddleware())
    
    // Open
    openGroup.post(Models.User.CreateRequest.self, use: UserController.create)
    
    // Basic APIs
    basicGroup.post(Models.User.LoginRequest.self, use: UserController.login)
    
    // Token APIs
    logOutRoute.get(use: UserController.logout)
    profileRoute.get(use: UserController.get)
    
  }
}

enum UserController {
  
  static func create(_ req: Request, user: Models.User.CreateRequest) throws -> Future<HTTPStatus> {
    let passwordHash = try BCrypt.hash(user.password)
    return Models.User(phoneNumber: user.phoneNumber,
                       passwordHash: passwordHash,
                       firstName: user.firstName,
                       lastName: user.lastName,
                       avatarURL: user.avatarURL,
                       balance: user.balance)
      .save(on: req)
      .transform(to: .ok)
  }
  
  static func get(_ req: Request) throws -> Models.User.Public {
    let user = try req.requireAuthenticated(Models.User.self)
    return user.convertToPublic()
  }
  
  static func logout(_ req: Request) throws -> Future<HTTPStatus> {
    let user = try req.requireAuthenticated(Models.User.self)
    return try Models.UserToken
      .query(on: req)
      .filter(\Models.UserToken.userID, .equal, user.requireID())
      .delete()
      .transform(to: .ok)
  }
  
  static func login(_ req: Request, loginInfo: Models.User.LoginRequest) throws -> Future<Models.UserToken> {
    let user = try req.requireAuthenticated(Models.User.self)
    let userPayload: Models.User.JWT = Models.User.JWT(id: user.id, phoneNumber: user.phoneNumber)
    let token = try Models.UserToken.createJWTToken(payload: userPayload)
    return try insertOrUpdateDevice(req, loginInfo: loginInfo).flatMap(to: Models.UserToken.self) { _ in
      return token.save(on: req)
    }
  }
  
  static func insertOrUpdateDevice(_ req: Request, loginInfo: Models.User.LoginRequest) throws -> Future<Bool> {
    let user = try req.requireAuthenticated(Models.User.self)
    let userID = try user.requireID()
    return try user.devices.query(on: req).filter(\.installationID == loginInfo.installationID).first().flatMap(to: Bool.self) { device in
      let dev = device == nil ?
        loginInfo.device(for: userID) : device!
      dev.pushToken = loginInfo.pushToken
      return dev.save(on: req).transform(to: true)
    }
  }
}
