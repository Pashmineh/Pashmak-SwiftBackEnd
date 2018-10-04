//
//  EventController.swift
//  App
//
//  Created by Ala Kiani on 10/1/18.
//

import Vapor

private let rootPathComponent = "event"

struct EventRouteCollection: RouteCollection {
  func boot(router: Router) throws {
    let tokenGroup = router.grouped(rootPathComponent).grouped(Models.User.tokenAuthMiddleware())
    tokenGroup.post(Models.Event.CreateRequest.self, use: EventController.create)
    tokenGroup.get(use: EventController.list)
    tokenGroup.get(Models.Event.parameter, use: EventController.item)
    tokenGroup.put(Models.Event.parameter, use: EventController.update)
  }
}

enum EventController {
  
  static func create(_ req: Request, eventInfo: Models.Event.CreateRequest) throws -> Future<Models.Event.Public> {
    
    // Create Event Object for Save in Database
    let event = Models.Event(title: eventInfo.title,
                             description: eventInfo.description,
                             date: eventInfo.date,
                             addressId: eventInfo.addressId,
                             imageURL: eventInfo.imageURL)
    
    // Save and Return Public Model
    return event.save(on: req).flatMap(to: Models.Event.Public.self) { event in
      return event.convertToPublic(on: req)
    }
    
  }
  
  static func list(_ req: Request) throws -> Future<[Models.Event.Public]> {
    return Models.Event.query(on: req).filter(\Models.Event.isEnabled, .equal, true).all().flatMap(to: [Models.Event.Public].self) {events in
      let promise = req.eventLoop.newPromise([Models.Event.Public].self)
      
      DispatchQueue.global().async {
        let publicEvents = events.compactMap { try? $0.convertToPublic(on: req).wait() }
        promise.succeed(result: publicEvents)
      }
      
      return promise.futureResult
    }
    
  }
  
  static func item(_ req: Request) throws -> Future<Models.Event.Public> {
    return try req.parameters.next(Models.Event.self).flatMap(to: Models.Event.Public.self) { event in
      return event.convertToPublic(on: req)
    }
  }
  
  static func update(_ req: Request) throws -> Future<Models.Event.Public> {
    return try req.parameters.next(Models.Event.self).flatMap(to: Models.Event.Public.self) { event in
      return try req.content.decode(Models.Event.UpdateRequest.self).flatMap(to: Models.Event.Public.self) {updateRequest in
        
        // Update title if presents in Update Request
        if let title = updateRequest.title {
          event.title = title
        }
        
        // Update description if presents in Update Request
        if let description = updateRequest.description {
          event.description = description
        }
        
        // Update date if presents in Update Request
        if let date = updateRequest.date {
          event.date = date
        }
        
        // Update addressId if presents in Update Request
        if let addressId = updateRequest.addressId {
          event.addressId = addressId
        }
        
        // Update imageURL if presents in Update Request
        if let imageURL = updateRequest.imageURL {
          event.imageURL = imageURL
        }
        
        // Update isHeld if presents in Update Request
        if let isHeld = updateRequest.isHeld {
          event.isHeld = isHeld
        }
        
        // Update isEnabled if presents in Update Request
        if let isEnabled = updateRequest.isEnabled {
          event.isEnabled = isEnabled
        }
        
        return event.save(on: req).flatMap(to: Models.Event.Public.self) { $0.convertToPublic(on: req) }
      }
    }
  }
}
