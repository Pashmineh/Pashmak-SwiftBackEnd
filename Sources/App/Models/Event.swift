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
  var eventTime: String
  var eventTimeEpoch: Double
  
  
  static let entity = "Event"
  
  init(id: Int? = nil,
       name: String,
       description: String,
       location: String,
       eventTime: String,
       eventTimeEpoch: Double) {
    
    self.id = id
    self.name = name
    self.description = description
    self.location = location
    self.eventTime = eventTime
    self.eventTimeEpoch = eventTimeEpoch
  
  }
  
}
