//
//  Formatters.swift
//  App
//
//  Created by Mohammad Porooshani on 10/2/18.
//

import Foundation

enum Formatters {
  static let RialFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "fa_IR")
    formatter.numberStyle = .currency
    formatter.currencySymbol = ""
    //  formatter.currencyGroupingSeparator = ","
    formatter.groupingSize = 3
    formatter.alwaysShowsDecimalSeparator = false
    formatter.isLenient = true
    return formatter
  }()

  static let RialFormatterWithRial: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "fa_IR")
    formatter.numberStyle = .currency
    formatter.currencySymbol = ""
    //  formatter.currencyGroupingSeparator = ","
    formatter.groupingSize = 3
    formatter.alwaysShowsDecimalSeparator = false
    formatter.positiveSuffix = " ﷼ "
    formatter.positivePrefix = "\u{200F}"
    formatter.negativeSuffix = "-" + " ﷼ "
    formatter.negativePrefix = "\u{200F}"
    formatter.isLenient = true
    return formatter
  }()

  static let TomanFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "fa_IR")
    formatter.numberStyle = .currency
    formatter.currencySymbol = ""
    //  formatter.currencyGroupingSeparator = ","
    formatter.groupingSize = 3
    formatter.alwaysShowsDecimalSeparator = false
    formatter.positiveSuffix = " تومان "
    formatter.positivePrefix = "\u{200F}"
    formatter.negativeSuffix = "-" + " تومان "
    formatter.negativePrefix = "\u{200F}"
    formatter.isLenient = true
    return formatter
  }()

  static let TomaniFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "fa_IR")
    formatter.numberStyle = .currency
    formatter.currencySymbol = ""
    //  formatter.currencyGroupingSeparator = ","
    formatter.groupingSize = 3
    formatter.alwaysShowsDecimalSeparator = false
    formatter.positiveSuffix = " تومانی "
    formatter.positivePrefix = "\u{200F}"
    formatter.negativeSuffix = "-" + " ﷼ "
    formatter.negativePrefix = "\u{200F}"
    formatter.isLenient = true
    return formatter
  }()

  static let NumberToTextFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "fa_IR")
    formatter.numberStyle = .spellOut
    return formatter
  }()

}

extension DateFormatter {
  static func farsiDateFormatter(with dateFormat: String) -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "fa_IR")
    dateFormatter.calendar = Calendar(identifier: .gregorian)
    dateFormatter.timeZone = TimeZone(identifier: "Asia/Tehran")
    dateFormatter.timeStyle = .none
    dateFormatter.dateFormat = dateFormat
    return dateFormatter
  }

  static func englishDateFormatterForTehran(with dateFormat: String) -> DateFormatter {
    let dateFormatter = farsiDateFormatter(with: dateFormat)
    dateFormatter.locale = Locale(identifier: "en_US")
    return dateFormatter
  }  

}

extension String {
  var numerals: String {
    func farsiToEnglish(char: String) -> String {
      switch char {
      case "۱":
        return "1"
      case "۲":
        return "2"
      case "۳":
        return "3"
      case "۴":
        return "4"
      case "۵":
        return "5"
      case "۶":
        return "6"
      case "۷":
        return "7"
      case "۸":
        return "8"
      case "۹":
        return "9"
      case "۰":
        return "0"
      default:
        return char
      }
    }
    return self.map {
      farsiToEnglish(char: "\($0)")
      }.joined()
  }
}
