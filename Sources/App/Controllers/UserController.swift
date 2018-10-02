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
    let basicGroup = router.grouped("login").grouped(Models.User.basicAuthMiddleware(using: BCryptDigest()))
    let tokenGroup = baseRouter.grouped(Models.User.tokenAuthMiddleware())
    let openGroup = baseRouter.grouped("/")
    
    // Open
    openGroup.post(Models.User.CreateRequest.self, use: UserController.create)
    
    // Basic APIs
    basicGroup.post(Models.User.LoginRequest.self, use: UserController.login)
    
    // Token APIs
    tokenGroup.get(rootPathComponent, use: TransactionController.get)
    
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
  
  static func get(_ req: Request) throws -> Future<HTTPResponse> {
    fatalError("Not implemented")
  }
  
  static func login(_ req: Request, loginInfo: Models.User.LoginRequest) throws -> Future<UserToken> {
    let user = try req.requireAuthenticated(Models.User.self)
    let userPayload: Models.User.JWT = Models.User.JWT(id: user.id, phoneNumber: user.phoneNumber)
    let token = try UserToken.createJWTToken(payload: userPayload)
    return try insertOrUpdateDevice(req, loginInfo: loginInfo).flatMap(to: UserToken.self) { _ in
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

/// Creates new users and logs them in.
//final class UserController {
//
//
//  /// Logs a user in, returning a token for accessing protected endpoints.
//  func login(_ req: Request) throws -> Future<LoginResponse> {
//
//    var tempUser: Models.User?
//    return try req.content.decode(LoginRequest.self)
//      .flatMap(to: LoginResponse.self) { loginInfo in
//        return Models.User
//          .query(on: req)
//          .filter(\Models.User.phoneNumber, .equal, loginInfo.username)
//          .first()
//          .unwrap(or: Abort(.notFound))
//          .flatMap(to: UserToken.self) { foundUser in
//            tempUser = foundUser
//            let passwordhash = try MD5.hash(loginInfo.password).base64EncodedString()
//            if foundUser.passwordHash == passwordhash {
//              let userPayload: Models.User.JWT = Models.User.JWT(id: foundUser.id ?? UUID(), phoneNumber: foundUser.phoneNumber)
//              let token = try UserToken.createJWTToken(payload: userPayload)
//              return token.save(on: req)
//            } else {
//              throw Abort(HTTPResponseStatus.forbidden)
//            }
//          }
//          .map(to: LoginResponse.self) { savedToken in
//            return LoginResponse(name: tempUser?.firstName ?? "", lastName: tempUser?.lastName ?? "", token: savedToken.string, avatar: tempUser?.avatar ?? "")
//        }
//      }
//  }
//
//  /// Creates a new user.
//  func create(_ req: Request) throws -> Future<HTTPResponse> {
//
//    return try req.content.decode(CreateUserRequest.self)
//      .flatMap(to: Models.User.self) { user -> Future<Models.User> in
//        let paswordHash = try MD5.hash(user.password).base64EncodedString()
//        try user.validate()
//        return Models.User(phoneNumber: user.userName,
//                           passwordHash: paswordHash,
//                           firstName: user.firstName,
//                           lastName: user.lastName,
//                           pushToken: user.pushToken,
//                           platform: user.platform,
//                           avatar: user.avatar,
//                           deviceID: user.deviceID)
//          .save(on: req)
//      }
//      .map(to: HTTPResponse.self) { userResponse in
//        return HTTPResponse(status: .created, body: "User Created")
//    }
//
//  }
//
//  // Get User Profile
//  func profile(_ req: Request) throws -> Future<String> {
//    let user = try req.requireAuthenticated(Models.User.self)
//    return req.future("Welcome \(user.phoneNumber)")
//  }
//
//  // Sign Out Request
//  func logout(_ req: Request) throws -> Future<HTTPResponse> {
//    let user = try req.requireAuthenticated(Models.User.self)
//    return try UserToken
//      .query(on: req)
//      .filter(\UserToken.userID, .equal, user.requireID())
//      .delete()
//      .transform(to: HTTPResponse(status: .ok))
//  }
//
//  // Test Redis Functionality
//  func redis(_ req: Request) throws -> Future<String> {
//    return req.withNewConnection(to: .redis) { redis in
//      return redis.get("test", as: String.self).map {
//        $0 ?? ""
//      }
//    }
//  }
//
//
//
//
//}


}
