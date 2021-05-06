//
//  DateExtension.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//

import Foundation

extension Date {

    /// This function returns the Date object with the seconds, minutes and hours zeroed - i.e. the date object only stores the date and not the time component.
    /// - returns: Date object that ignores the time components.
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
    /// - returns: The minute component of the Date object as an integer.
    func getMinutes() -> Int {
        let calendar = Calendar.current
        return calendar.component(.minute, from: self)
    }
    
    /// This function returns an integer which represents the day of the week.
    /// - returns: An integer which represents the day of the week.
    func getWeekDay() -> Int {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.component(.weekday, from: self)
    }

    /// This function sets the time components of the Date object.
    /// - parameter hour: Number of hours passed.
    /// - parameter minute: Number of minutes passed.
    /// - parameter second: Number of seconds passed.
    func setTime(hour: Int, minute: Int, second: Int) -> Date {
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)

        components.hour = hour
        components.minute = minute
        components.second = second

        return calendar.date(from: components)!
    }
}
