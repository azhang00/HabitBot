//
//  DateAxisValueFormatter.swift
//  HabitBot
//
//  Created by Anna Zhang on 20/5/21.
//

import Foundation
import Charts

class DateAxisValueFormatter: IAxisValueFormatter {
    
    var initialDate = Date().dateOnly()
    var stepType = "daily"
    
    /// This function sets the initial date for the axis formatter.
    /// - parameter date: first date in the axis formatter
    func setInitialDate(date: Date) {
        self.initialDate = date
    }
    
    /// This function sets the step type for the axis formatter.
    /// - parameter stepType: can be "daily" or "weekly"
    func setDateStepType(stepType: String) {
        self.stepType = stepType
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM"
        dateFormatter.locale = .current
        
        var date = self.initialDate
        
        if stepType == "weekly" {
            date.addTimeInterval(60*60*24*value*7)
        } else {
            date.addTimeInterval(60*60*24*value)
        }
        
        return dateFormatter.string(from: date)
    }
}
