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
    let logOutRoute = router.grouped("logout").grouped([Models.User.tokenAuthMiddleware(), Models.User.guardAuthMiddleware()])
    let profileRoute = router.grouped("profile").grouped([Models.User.tokenAuthMiddleware(), Models.User.guardAuthMiddleware()])
    let tokenGroup = router.grouped("token").grouped([Models.User.tokenAuthMiddleware(), Models.User.guardAuthMiddleware()])
    
    // Open
    openGroup.post(Models.User.CreateRequest.self, use: UserController.create)
    
    // Basic APIs
    basicGroup.post(Models.User.LoginRequest.self, use: UserController.login)
    
    // Token APIs
    logOutRoute.get(use: UserController.logout)
    profileRoute.get(use: UserController.get)

    // Import Users
    openGroup.grouped("import").post([Models.User.ImportModel].self, use: UserController.import)

    // Update Push
    tokenGroup.put(Models.Device.PushUpdateRequest.self, use: UserController.updateToken)

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
                       balance: user.balance,
                       totalPaid: user.totalPaid)
      .save(on: req)
      .transform(to: .created)
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
  
  static func login(_ req: Request, loginInfo: Models.User.LoginRequest) throws -> Future<Models.UserToken.Public> {
    let user = try req.requireAuthenticated(Models.User.self)
    let userPayload: Models.User.JWT = Models.User.JWT(id: user.id, phoneNumber: user.phoneNumber)
    let token = try Models.UserToken.createJWTToken(payload: userPayload)
    return try insertOrUpdateDevice(req, loginInfo: loginInfo).flatMap { _ in
      return token.save(on: req).map { $0.publicApi(for: user) }
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

  static func updateToken(_ req: Request, updateInfo: Models.Device.PushUpdateRequest) throws -> Future<HTTPStatus> {
    let user = try req.requireAuthenticated(Models.User.self)
    return try user.devices.query(on: req).filter(\.installationID == updateInfo.installationID).first().unwrap(or: Abort(.notFound, reason: "Could not find device")).flatMap {
      $0.pushToken = updateInfo.token
      return $0.save(on: req).transform(to: .ok)
    }
  }

  static func `import`(_ req: Request, importData: [Models.User.ImportModel]) throws -> Future<Models.User.ImportResult> {

    let promise = req.eventLoop.newPromise(Models.User.ImportResult.self)

    DispatchQueue.global(qos: .background).async {
      var successCount = 0
      var errorCount = 0
      importData.forEach {
        do {
          let passwordHash = try BCrypt.hash($0.password)
          let _ = try Models.User(phoneNumber: $0.login, passwordHash: passwordHash, firstName: $0.firstName, lastName: $0.lastName, avatarURL: $0.imageUrl ?? "", balance: 0, totalPaid: 0).save(on: req).wait()
          successCount += 1
        } catch {
          errorCount += 1
          print("Error saving import data for: [\($0)]\n\(error.localizedDescription)")
        }

      }

      let result = Models.User.ImportResult(inserted: successCount, error: errorCount)
      promise.succeed(result: result)
    }

    return promise.futureResult
  }
}
