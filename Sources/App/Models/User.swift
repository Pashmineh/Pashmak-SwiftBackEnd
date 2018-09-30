//
//  User.swift
//  App
//
//  Created by Ala Kiani on 9/30/18.
//

import Authentication
import FluentPostgreSQL
import Vapor
import JWT

/// A registered user, capable of owning todo items.
final class User: PostgreSQLModel {
  
  
  /// User's unique identifier.
  /// Can be `nil` if the user has not been saved yet.
  var id: Int?
  
  var userName: String
  var passwordHash: String
  var firstName: String
  var lastName: String
  var pushToken: String
  var platform: String
  var avatar: String
  
  static let entity = "User"
  
  /// Creates a new `User`.
  init(id: Int? = nil, userName: String, passwordHash: String, firstName: String, lastName: String, pushToken: String, platform: String, avatar: String) {
    self.id = id
    self.userName = userName
    self.passwordHash = passwordHash
    self.firstName = firstName
    self.lastName = lastName
    self.pushToken = pushToken
    self.platform = platform
    self.avatar = avatar
  }
}

struct UserJWT: JWTPayload {
  var id: Int
  var userName: String
  
  init(id: Int, userName: String) {
    self.id = id
    self.userName = userName
  }
  func verify(using signer: JWTSigner) throws {
    // nothing to verify
  }
}

/// Allows users to be verified by basic / password auth middleware.
extension User: PasswordAuthenticatable {
  /// See `PasswordAuthenticatable`.
  static var usernameKey: WritableKeyPath<User, String> {
    return \.userName
  }
  
  /// See `PasswordAuthenticatable`.
  static var passwordKey: WritableKeyPath<User, String> {
    return \.passwordHash
  }
}

/// Allows users to be verified by bearer / token auth middleware.
extension User: TokenAuthenticatable {
  /// See `TokenAuthenticatable`.
  typealias TokenType = UserToken
}


/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content { }

extension User: Migration { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter { }
