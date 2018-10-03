//
//  Address.swift
//  App
//
//  Created by Ala Kiani on 10/3/18.
//

import Authentication
import FluentPostgreSQL
import Vapor
import JWT

extension Models {
  
  final class Address: PostgreSQLUUIDModel {
    
    var id: UUID?
    
    var title: String
    var street: String
    var lat: Double
    var long: Double
    var mapImageURL: String
    
    static let entity = "Address"

    
    init(title: String, street: String, lat: Double = 0, long: Double = 0, mapImageURL: String) {
      self.title = title
      self.street = street
      self.lat = lat
      self.long = long
      self.mapImageURL = mapImageURL
    }
  }
  
  
  
}

/// Allows `Address` to be encoded to and decoded from HTTP messages.
extension Models.Address: Content { }

/// Allows `Address` to be Migrated
extension Models.Address: Migration { }

/// Allows `Address` to be used as a dynamic parameter in route definitions.
extension Models.Address: Parameter { }
