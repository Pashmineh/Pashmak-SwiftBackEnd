//
//  Models.UserToken.swift
//  App
//
//  Created by Ala Kiani on 9/30/18.
//

import Authentication
import Crypto
import FluentPostgreSQL
import Vapor
import JWT


extension Models {
  
  /// An ephermal authentication token that identifies a registered user.
  final class UserToken: PostgreSQLUUIDModel {
    /// Creates a new `UserToken` for a given user.
    static func create(userID: Models.User.ID) throws -> UserToken {
      // generate a random 128-bit, base64-encoded string.
      let string = try CryptoRandom().generateData(count: 16).base64EncodedString()
      // init a new `UserToken` from that string.
      return .init(string: string, userID: userID)
    }
    
    static func createJWTToken(payload: Models.User.JWT) throws -> UserToken {
      let data = try JWT(payload: payload).sign(using: .hs256(key: "secret"))
      let string = String(data: data, encoding: .utf8) ?? ""
      return .init(string: string, userID: payload.id)
    }
    
    /// See `Model`.
    static var deletedAtKey: TimestampKey? { return \.expiresAt }
    
    /// UserToken's unique identifier.
    var id: UUID?
    
    /// Unique token string.
    var string: String
    
    /// Reference to user that owns this token.
    var userID: Models.User.ID
    
    /// Expiration date. Token will no longer be valid after this point.
    var expiresAt: Date?
    
    static let entity = "UserToken"
    
    /// Creates a new `UserToken`.
    init(string: String, userID: Models.User.ID) {
      self.string = string
      // set token to expire after 5 hours
      self.expiresAt = Date.init(timeInterval: 60 * 60 * 5, since: .init())
      self.userID = userID
    }
  }
}

extension Models.UserToken {
  /// Fluent relation to the user that owns this token.
  var user: Parent<Models.UserToken, Models.User> {
    return parent(\.userID)
  }
}

/// Allows this model to be used as a TokenAuthenticatable's token.
extension Models.UserToken: Token {
  /// See `Token`.
  typealias UserType = Models.User
  
  /// See `Token`.
  static var tokenKey: WritableKeyPath<Models.UserToken, String> {
    return \.string
  }
  
  /// See `Token`.
  static var userIDKey: WritableKeyPath<Models.UserToken, Models.User.ID> {
    return \.userID
  }
}


extension Models.UserToken: Migration { }

/// Allows `Models.UserToken` to be encoded to and decoded from HTTP messages.
extension Models.UserToken: Content { }

/// Allows `UserToken` to be used as a dynamic parameter in route definitions.
extension Models.UserToken: Parameter { }
