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
    
  }
}


extension Models.Device {
  var user: Parent<Models.Device, Models.User> {
    return parent(\.userId)
  }
}
