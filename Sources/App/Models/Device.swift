//
//  Device.swift
//  App
//
//  Created by Ala Kiani on 10/2/18.
//

import Authentication
import FluentPostgreSQL
import Vapor
import JWT


extension Models {
  final class Device: PostgreSQLUUIDModel {
    var id: UUID?
    
    var installationID: String
    var platform: String
    var pushToken: String
    var userId: Models.User.ID
    
    init(installationID: String, platform: String, pushToken: String, userId: Models.User.ID) {
      self.installationID = installationID
      self.platform = platform
      self.pushToken = pushToken
      self.userId = userId
    }
  }
  
 
}


extension Models.Device {
  var user: Parent<Models.Device, Models.User> {
    return parent(\.userId)
  }
}


/// Allows `Device` to be encoded to and decoded from HTTP messages.
extension Models.Device: Content { }

extension Models.Device: Migration { }

/// Allows `Device` to be used as a dynamic parameter in route definitions.
extension Models.Device: Parameter { }
