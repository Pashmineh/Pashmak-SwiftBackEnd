//
//  Event.swift
//  App
//
//  Created by Ala Kiani on 9/30/18.
//

import Authentication
import FluentPostgreSQL
import Vapor
import JWT

final class Event: PostgreSQLModel {
  
  /// User's unique identifier.
  /// Can be `nil` if the user has not been saved yet.
  var id: Int?
  
  var name: String
  var description: String
  var location: String
  var eventTime: Date
  var eventTimeEpoch: Double
  
  
  static let entity = "Event"
  
  init(id: Int? = nil,
       name: String,
       description: String,
       location: String,
       eventTime: Date,
       eventTimeEpoch: Double) {
    
    self.id = id
    self.name = name
    self.description = description
    self.location = location
    self.eventTime = eventTime
    self.eventTimeEpoch = eventTimeEpoch
  
  }
  
}


/// Allows `Event` to be encoded to and decoded from HTTP messages.
extension Event: Content { }

/// Allows `Event` to be Migrated
extension Event: Migration { }

/// Allows `Event` to be used as a dynamic parameter in route definitions.
extension Event: Parameter { }
