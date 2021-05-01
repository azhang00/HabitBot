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

}
