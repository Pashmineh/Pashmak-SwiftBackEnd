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
    var date: Date
    var address: Models.Address
    var imageURL: String
    
  }
  
  func convertToPublic(on req : Request) -> Future<Models.Event.Public> {
    return Models.Address.find(self.addressId, on: req).unwrap(or: Abort(.badRequest)).map(to: Models.Event.Public.self) { address in
      return Models.Event.Public(id: self.id, title: self.title, description: self.description, date: self.date, address: address, imageURL: self.imageURL)
    }
  }
}


