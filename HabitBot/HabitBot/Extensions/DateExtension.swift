//
//  DateExtension.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//

import Foundation

extension Date {

    /// This function returns the Date object with the seconds, minutes and hours zeroed - i.e. the date object only stores the date and not the time component.
    /// - returns: Date object that ignores the time components
    func dateOnly() -> Date
    {
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)

        components.hour = 0
        components.minute = 0
        components.second = 0

        return calendar.date(from: components)!
    }
    
    /// This function returns the hour component of the Date object.
    /// - returns: the hour component of the Date object as an integer.
    func getHour() -> Int {
        let calendar = Calendar.current
        return calendar.component(.hour, from: self)
    }
    
    /// This function returns the minute component of the Date object.
    /// - returns: the minute component of the Date object as an integer.
    func getMinutes() -> Int {
        let calendar = Calendar.current
        return calendar.component(.minute, from: self)
    }
    
    func getWeekDay() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.component(.weekday, from: self)
    }

}
