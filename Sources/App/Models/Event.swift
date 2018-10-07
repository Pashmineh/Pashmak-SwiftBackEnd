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

extension Models {
  
  final class Event: PostgreSQLUUIDModel {
    
    var id: UUID?
    
    var title: String
    var description: String
    var date: Date
    var addressId: Models.Address.ID
    var imageURL: String
    var isEnabled: Bool
    var isHeld: Bool
    
    static let entity = "Event"
    
    init(title: String,
         description: String,
         date: Date,
         addressId: Models.Address.ID,
         imageURL: String) {
      
      self.title = title
      self.description = description
      self.date = date
      self.addressId = addressId
      self.imageURL = imageURL
      self.isHeld = false
      self.isEnabled = true
    }
    
   
    
  }
}


/// Allows `Event` to be encoded to and decoded from HTTP messages.
extension Models.Event: Content { }

/// Allows `Event` to be Migrated
extension Models.Event: Migration { }

/// Allows `Event` to be used as a dynamic parameter in route definitions.
extension Models.Event: Parameter { }

extension Models.Event {
  
  struct Public: Content {
    
    var id: Models.Event.ID?
    var title: String
    var description: String
    var dateEpoch: Double
    var address: Models.Address
    var imageURL: String
    
  }
  
  func convertToPublic(on req : Request) -> Future<Models.Event.Public> {
    return Models.Address.find(self.addressId, on: req).unwrap(or: Abort(.badRequest)).map(to: Models.Event.Public.self) { address in
      return Models.Event.Public(id: self.id, title: self.title, description: self.description, dateEpoch: /*self.date.timeIntervalSince1970 * 1000*/156566555, address: address, imageURL: self.imageURL)
    }
  }
  
  struct CreateRequest: Content {
    var title: String
    var description: String
    var date: Date
    var addressId: Models.Address.ID
    var imageURL: String
  }
  
  struct UpdateRequest: Content {
    var title: String?
    var description: String?
    var date: Date?
    var addressId: Models.Address.ID?
    var imageURL: String?
    var isHeld: Bool?
    var isEnabled: Bool?
  }
}


