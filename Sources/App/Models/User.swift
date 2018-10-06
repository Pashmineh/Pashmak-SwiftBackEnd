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
    var avatarURL: String
    var balance: Int64
    var totalPaid: Int64
    
    static let entity = "User"
    
    /// Creates a new `User`.
    init(phoneNumber: String, passwordHash: String, firstName: String, lastName: String, avatarURL: String, balance: Int64, totalPaid: Int64) {
      self.phoneNumber = phoneNumber
      self.passwordHash = passwordHash
      self.firstName = firstName
      self.lastName = lastName
      self.avatarURL = avatarURL
      self.balance = balance
      self.totalPaid = totalPaid
    }
    
    struct JWT: JWTPayload {
      var id: UUID
      var phoneNumber: String
      var issuedAt: Date
      
      init(id: UUID?, phoneNumber: String) {
        self.id = id ?? UUID()
        self.phoneNumber = phoneNumber
        self.issuedAt = Date()
      }
      func verify(using signer: JWTSigner) throws {
        // nothing to verify
      }
    }
    
    
    final class Public: Content {
      var id: Models.User.ID
      var phoneNumber: String
      var firstName: String
      var lastName: String
      var avatarURL: String
      var balance: Int64
      var totalPaid: Int64
      
      init(id: Models.User.ID, phoneNumber: String, firstName: String, lastName: String, avatarURL: String, balance: Int64, totalPaid: Int64) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.lastName = lastName
        self.avatarURL = avatarURL
        self.balance = balance
        self.totalPaid = totalPaid
      }
    }
    
    
    // Content required for Creating A New User
    struct CreateRequest: Content {
      var phoneNumber: String
      var firstName: String
      var lastName: String
      var password: String
      var avatarURL: String
      var balance: Int64
      var totalPaid: Int64
    }
    
    // Content required for Loging in A User
    struct LoginRequest: Content {
      var installationID: String
      var platform: String
      var pushToken: String
      
      func device(for userID: User.ID) -> Device{
        return Device(installationID: self.installationID, platform: self.platform, pushToken: self.pushToken, userId: userID)
      }
    }
    
  }
}

extension Models.User {
  func convertToPublic() -> Models.User.Public {
    return Models.User.Public(id: self.id ?? UUID(),
                              phoneNumber: self.phoneNumber,
                              firstName: self.firstName,
                              lastName: self.lastName,
                              avatarURL: self.avatarURL,
                              balance: self.balance,
                              totalPaid: self.totalPaid)
  }
}


extension Models.User {
  var devices: Children<Models.User, Models.Device> {
    return children(\.userId)
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
  typealias TokenType = Models.UserToken
}


/// Validation User Inputs
extension Models.User: Validatable {
  static func validations() throws -> Validations<Models.User> {
    var validations = Validations(Models.User.self)
    try validations.add(\.phoneNumber, .count(3...))
    return validations
  }
}

extension Models.User {
  @discardableResult
  func updateBalance(_ req: DatabaseConnectable) throws -> Future<Models.User.Public> {
    return try self.transactions.query(on: req).filter(\.isValid == true).all().flatMap(to: Models.User.Public.self) { transactions in
      let balance: Int64 = transactions.reduce(0) { $0 + $1.amount }
      let totalPaid: Int64 = transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
      self.balance = balance
      self.totalPaid = totalPaid
      return self.save(on: req).map(to: Models.User.Public.self) { return $0.convertToPublic()}
        .do { _ in
          let msg = PushService.UpdateMessage(type: .profile, event: .update)
          do {
            try PushService.shared.send(message: msg, to: [self] , on: req)
          } catch {
            print("error sending balance update push.\n\(error.localizedDescription)")
          }
      }
    }
  }
}


/// Allows `User` to be encoded to and decoded from HTTP messages.
extension Models.User: Content { }

extension Models.User: Migration {
  static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
    return Database.create(self, on: connection) { builder in
      try addProperties(to: builder)
      builder.unique(on: \.phoneNumber)
    }
  }
  
  static func revert(on conn: PostgreSQLConnection) -> Future<Void> {
    return Database.update(self, on: conn) { builder in
      builder.deleteUnique(from: \.phoneNumber)
    }
  }
  
}

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension Models.User: Parameter { }

extension Models.User {
  var transactions: Children<Models.User, Models.Transaction> {
    return children(\.userId)
  }

  var checkins: Children<Models.User, Models.Checkin> {
    return children(\.userId)
  }

  var messages: Children<Models.User, Models.Message> {
    return children(\.userId)
  }

  var votes: Children<Models.User, Models.Vote> {
    return children(\.userId)
  }

}

extension Models.User {

  struct ImportModel: Content {

    var login: String
    var password: String
    var firstName: String
    var lastName: String
    var email: String
    var imageUrl: String?
    var platform: String?

  }

  struct ImportResult: Content {

    var inserted: Int
    var error: Int

  }

}
