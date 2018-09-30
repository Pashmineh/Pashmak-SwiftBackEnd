//
//  UserToken.swift
//  App
//
//  Created by Ala Kiani on 9/30/18.
//

import Authentication
import Crypto
import FluentPostgreSQL
import Vapor
import JWT

/// An ephermal authentication token that identifies a registered user.
final class UserToken: PostgreSQLModel {
  /// Creates a new `UserToken` for a given user.
  static func create(userID: User.ID) throws -> UserToken {
    // generate a random 128-bit, base64-encoded string.
    let string = try CryptoRandom().generateData(count: 16).base64EncodedString()
    // init a new `UserToken` from that string.
    return .init(string: string, userID: userID)
  }
  
  static func createJWTToken(user: UserJWT) throws -> UserToken {
    let data = try JWT(payload: user).sign(using: .hs256(key: "secret"))
    let string = String(data: data, encoding: .utf8) ?? ""
    return .init(string: string, userID: user.id)
  }
  
  /// See `Model`.
  static var deletedAtKey: TimestampKey? { return \.expiresAt }
  
  /// UserToken's unique identifier.
  var id: Int?
  
  /// Unique token string.
  var string: String
  
  /// Reference to user that owns this token.
  var userID: User.ID
  
  /// Expiration date. Token will no longer be valid after this point.
  var expiresAt: Date?
  
  static let entity = "UserToken"
  
  /// Creates a new `UserToken`.
  init(id: Int? = nil, string: String, userID: User.ID) {
    self.id = id
    self.string = string
    // set token to expire after 5 hours
    self.expiresAt = Date.init(timeInterval: 60 * 60 * 5, since: .init())
    self.userID = userID
  }
}

extension UserToken {
  /// Fluent relation to the user that owns this token.
  var user: Parent<UserToken, User> {
    return parent(\.userID)
  }
}

/// Allows this model to be used as a TokenAuthenticatable's token.
extension UserToken: Token {
  /// See `Token`.
  typealias UserType = User
  
  /// See `Token`.
  static var tokenKey: WritableKeyPath<UserToken, String> {
    return \.string
  }
  
  /// See `Token`.
  static var userIDKey: WritableKeyPath<UserToken, User.ID> {
    return \.userID
  }
}


extension UserToken: Migration { }

/// Allows `UserToken` to be encoded to and decoded from HTTP messages.
extension UserToken: Content { }

/// Allows `UserToken` to be used as a dynamic parameter in route definitions.
extension UserToken: Parameter { }
