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
  func login(_ req: Request) throws -> Future<UserToken> {

    let user = try req.content.decode(LoginRequest.self).map(to: <#T##T.Type#>, <#T##callback: (LoginRequest) throws -> T##(LoginRequest) throws -> T#>)
    
    let user = try req.requireAuthenticated(User.self)
    let userPayload: UserJWT = UserJWT(id: user.id!, userName: user.userName)
    let token = try UserToken.createJWTToken(user: userPayload)
    
    return token.save(on: req)
    
  }
  
  /// Creates a new user.
  func create(_ req: Request) throws -> Future<LoginResponse> {
    
    return try req.content.decode(LoginRequest.self)
      
      .flatMap(to: User.self) { user -> Future<User> in
        let paswordHash = try BCrypt.hash(user.password)
        return User(id: nil, userName: user.username, passwordHash: paswordHash, firstName: "", lastName: "", pushToken: user.pushToken, platform: "", avatar: "").save(on: req)
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

/// Data required to create a user.
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
