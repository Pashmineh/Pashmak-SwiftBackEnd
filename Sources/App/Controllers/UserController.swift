//
//  UserController.swift
//  App
//
//  Created by Ala Kiani on 9/30/18.
//

import Crypto
import Vapor
import FluentPostgreSQL

/// Creates new users and logs them in.
final class UserController {
  
  
  /// Logs a user in, returning a token for accessing protected endpoints.
  func login(_ req: Request) throws -> Future<LoginResponse> {
   
    var tempUser: User?
    return try req.content.decode(LoginRequest.self)
      .flatMap(to: LoginResponse.self) { loginInfo in
        return User
          .query(on: req)
          .filter(\User.userName, .equal, loginInfo.username)
          .first()
          .unwrap(or: Abort(.notFound))
          .flatMap(to: UserToken.self) { foundUser in
            tempUser = foundUser
            let passwordhash = try MD5.hash(loginInfo.password).base64EncodedString()
            if foundUser.passwordHash == passwordhash {
              let userPayload: UserJWT = UserJWT(id: foundUser.id ?? 0, userName: foundUser.userName)
              let token = try UserToken.createJWTToken(user: userPayload)
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
  func create(_ req: Request) throws -> Future<LoginResponse> {
    
    return try req.content.decode(CreateUserRequest.self)
      .flatMap(to: User.self) { user -> Future<User> in
        let paswordHash = try MD5.hash(user.password).base64EncodedString()
        return User(id: nil,
                    userName: user.userName,
                    passwordHash: paswordHash,
                    firstName: user.firstName,
                    lastName: user.lastName,
                    pushToken: user.pushToken,
                    platform: user.platform,
                    avatar: user.avatar,
                    deviceID: user.deviceID)
          .save(on: req)
      }
      
      .map(to: LoginResponse.self) { userResponse in
        return LoginResponse(name: "", lastName: "", token: "", avatar: "")
    }
    
  }
  
  // Get User Profile
  func profile(_ req: Request) throws -> Future<String> {
    let user = try req.requireAuthenticated(User.self)
    return req.future("Welcome \(user.userName)")
  }
  
  // Sign Out Request
  func logout(_ req: Request) throws -> Future<HTTPResponse> {
    let user = try req.requireAuthenticated(User.self)
    return try UserToken
      .query(on: req)
      .filter(\UserToken.userID, .equal, user.requireID())
      .delete()
      .transform(to: HTTPResponse(status: .ok))
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
struct CreateUserRequest: Content {
  var userName: String
  var password: String
  var firstName: String
  var lastName: String
  var pushToken: String
  var platform: String
  var avatar: String
  var deviceID: String
}
