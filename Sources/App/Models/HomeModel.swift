//
//  HomeModel.swift
//  App
//
//  Created by Mohammad Porooshani on 10/6/18.
//

import FluentPostgreSQL
import Vapor

private let kCycleDateFormatter: DateFormatter = DateFormatter.farsiDateFormatter(with: "MMMM YY")

extension Models {

  struct Home: Content {

    struct Balance: Content {
      var balance: Int64
      var totalPaid: Int64
    }

    var cycle: String
    var balance: Balance
    var events: [Models.Event.Public]

    init(user: Models.User, events: [Event.Public]) {
      self.events = events
      self.cycle = kCycleDateFormatter.string(from: Date())
      self.balance = Balance(balance: user.balance, totalPaid: user.totalPaid)
    }

  }

}
