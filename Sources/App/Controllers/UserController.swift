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

/// Creates new users and logs them in.
final class UserController {
  
  
  /// Logs a user in, returning a token for accessing protected endpoints.
  func login(_ req: Request) throws -> Future<LoginResponse> {
   
    var tempUser: Models.User?
    return try req.content.decode(LoginRequest.self)
      .flatMap(to: LoginResponse.self) { loginInfo in
        return Models.User
          .query(on: req)
          .filter(\Models.User.phoneNumber, .equal, loginInfo.username)
          .first()
          .unwrap(or: Abort(.notFound))
          .flatMap(to: UserToken.self) { foundUser in
            tempUser = foundUser
            let passwordhash = try MD5.hash(loginInfo.password).base64EncodedString()
            if foundUser.passwordHash == passwordhash {
              let userPayload: Models.User.JWT = Models.User.JWT(id: foundUser.id ?? UUID(), phoneNumber: foundUser.phoneNumber)
              let token = try UserToken.createJWTToken(payload: userPayload)
              return token.save(on: req)
            } else {
              throw Abort(HTTPResponseStatus.forbidden)
            }
          }
          .map(to: LoginResponse.self) { savedToken in
            return LoginResponse(name: tempUser?.firstName ?? "", lastName: tempUser?.lastName ?? "", token: savedToken.string, avatar: tempUser?.avatar ?? "")
        }
      }
  }
  
  /// Creates a new user.
  func create(_ req: Request) throws -> Future<HTTPResponse> {
    
    return try req.content.decode(CreateUserRequest.self)
      .flatMap(to: Models.User.self) { user -> Future<Models.User> in
        let paswordHash = try MD5.hash(user.password).base64EncodedString()
        try user.validate()
        return Models.User(phoneNumber: user.userName,
                           passwordHash: paswordHash,
                           firstName: user.firstName,
                           lastName: user.lastName,
                           pushToken: user.pushToken,
                           platform: user.platform,
                           avatar: user.avatar,
                           deviceID: user.deviceID)
          .save(on: req)
      }
      .map(to: HTTPResponse.self) { userResponse in
        return HTTPResponse(status: .created, body: "User Created")
    }
    
  }
  
  // Get User Profile
  func profile(_ req: Request) throws -> Future<String> {
    let user = try req.requireAuthenticated(Models.User.self)
    return req.future("Welcome \(user.phoneNumber)")
  }
  
  // Sign Out Request
  func logout(_ req: Request) throws -> Future<HTTPResponse> {
    let user = try req.requireAuthenticated(Models.User.self)
    return try UserToken
      .query(on: req)
      .filter(\UserToken.userID, .equal, user.requireID())
      .delete()
      .transform(to: HTTPResponse(status: .ok))
  }
  
  // Test Redis Functionality
  func redis(_ req: Request) throws -> Future<String> {
    return req.withNewConnection(to: .redis) { redis in
      return redis.get("test", as: String.self).map {
        $0 ?? ""
      }
    }
  }
  



}

// MARK: Content

/// Data required to Loging in a user.
struct LoginRequest: Content {

  var username: String
  var password: String
  var platform: String
  var pushToken: String
  var deviceID: String
  
}

/// Public representation of user data.
struct LoginResponse: Content {
  
  var name: String
  var lastName: String
  var token: String
  var avatar: String
  
}

// Data Required to create a User
struct CreateUserRequest: Content, Reflectable {
  var userName: String
  var password: String
  var firstName: String
  var lastName: String
  var pushToken: String
  var platform: String
  var avatar: String
  var deviceID: String
}

extension CreateUserRequest: Validatable {
  static func validations() throws -> Validations<CreateUserRequest> {
    var validations = Validations(CreateUserRequest.self)
    try validations.add(\.userName, .count(3...))
    return validations
  }
  
  
}
