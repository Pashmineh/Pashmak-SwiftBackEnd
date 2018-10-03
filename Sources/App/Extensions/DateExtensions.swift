//
//  DateExtensions.swift
//  App
//
//  Created by Mohammad Porooshani on 10/3/18.
//

import Foundation

private let kHourFormatter = DateFormatter.englishDateFormatterForTehran(with: "H")

extension Date {

  var hourInTehran: Int? {
    let hourString = kHourFormatter.string(from: self)
    return Int(hourString)
  }

}
