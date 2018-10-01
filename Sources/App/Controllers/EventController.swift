//
//  EventController.swift
//  App
//
//  Created by Ala Kiani on 10/1/18.
//

import Crypto
import Vapor
import FluentPostgreSQL

/// Creates new users and logs them in.
final class EventController {
  
  func create(_ req: Request) throws -> Future<Event> {
    
    return try req.content.decode(CreateEventRequest.self).flatMap(to: Event.self) { createRequest in
      return Event(id: nil,
                   name: createRequest.name,
                   description: createRequest.description,
                   location: createRequest.location,
                   eventTime: Date(timeIntervalSince1970: createRequest.eventTimeEpoch),
                   eventTimeEpoch: createRequest.eventTimeEpoch)
        .save(on: req)
    }
  }
  
}

// MARK: Content

// Data Required to create a Debt
struct CreateEventRequest: Content {
  var name: String
  var description: String
  var location: String
  var eventTimeEpoch: Double
}
