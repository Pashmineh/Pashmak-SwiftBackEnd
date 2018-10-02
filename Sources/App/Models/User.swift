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

extension Models {
  

/// A registered user, capable of owning todo items.
final class User: PostgreSQLUUIDModel {
  
  
  /// User's unique identifier.
  /// Can be `nil` if the user has not been saved yet.
  var id: UUID?
  
  var phoneNumber: String
  var passwordHash: String
  var firstName: String
  var lastName: String
  var pushToken: String
  var platform: String
  var avatar: String
  var deviceID: String
  
  static let entity = "User"
  
  /// Creates a new `User`.
  init(phoneNumber: String, passwordHash: String, firstName: String, lastName: String, pushToken: String, platform: String, avatar: String, deviceID: String) {
    self.phoneNumber = phoneNumber
    self.passwordHash = passwordHash
    self.firstName = firstName
    self.lastName = lastName
    self.pushToken = pushToken
    self.platform = platform
    self.avatar = avatar
    self.deviceID = deviceID
  }
  
  struct JWT: JWTPayload {
    var id: UUID
    var phoneNumber: String
    var issuedAt: Date
    
    init(id: UUID, phoneNumber: String) {
      self.id = id
      self.phoneNumber = phoneNumber
      self.issuedAt = Date()
    }
    func verify(using signer: JWTSigner) throws {
      // nothing to verify
    }
  }
}
}


/// Allows users to be verified by basic / password auth middleware.
extension Models.User: PasswordAuthenticatable {
  /// See `PasswordAuthenticatable`.
  static var usernameKey: WritableKeyPath<Models.User, String> {
    return \.phoneNumber
  }
  
  /// See `PasswordAuthenticatable`.
  static var passwordKey: WritableKeyPath<Models.User, String> {
    return \.passwordHash
  }
}

/// Allows users to be verified by bearer / token auth middleware.
extension Models.User: TokenAuthenticatable {
  /// See `TokenAuthenticatable`.
  typealias TokenType = UserToken
}

/// Validation User Inputs
extension Models.User: Validatable {
  static func validations() throws -> Validations<Models.User> {
    var validations = Validations(Models.User.self)
    try validations.add(\.phoneNumber, .count(3...))
    return validations
  }
  
  
}

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension Models.User: Content { }

extension Models.User: Migration { }

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension Models.User: Parameter { }
