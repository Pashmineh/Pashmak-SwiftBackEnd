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
  
  final class Event: PostgreSQLModel {
    
    var id: Int?
    
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
