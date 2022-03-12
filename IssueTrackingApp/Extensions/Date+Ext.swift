//
//  Date+Ext.swift
//  IssueTrackingApp
//
//  Created by Scott Bauer on 9/12/21.
//

import Foundation

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var week: Int {
        return Calendar.current.component(.weekOfMonth, from: self)
    }
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    var weekday: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
    var isFirstDayOfMonth: Bool {
        return dayBefore.month != month
    }
}
extension Date {
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth())!
    }
}
