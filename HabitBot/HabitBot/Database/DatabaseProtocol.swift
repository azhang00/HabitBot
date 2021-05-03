//
//  DatabaseProtocol.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//

import Foundation

enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case habitData
    case habitDate
    case all
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    
    func onHabitDataForADateChange(change: DatabaseChange, habitData: [HabitData])
    
    func onHabitDateChange(change: DatabaseChange, habitDate: [HabitDate])
}

protocol DatabaseProtocol: AnyObject {
    func createHabit(name: String, type: String, frequencyDuration: String, frequency: Int64, freqDescription: String, colour: String) -> Habit
    
    func getChildContextHabit(habit: Habit?) -> Habit
    
    func saveHabitEdit(habit: Habit)
    
    func deleteHabit(habit: Habit)
    
    func setReminder(habit: Habit, startTime: Date, msgDescription: String, completeMsg: String, incompleteMsg: String, frequency: Int64, count: Int64)
    
    func deleteReminder(habit: Habit)
    
    func updateHabitCount(habitData: HabitData, incrementVal: Int64)
    
    func createOneMonthOfHabitDates(startDate: Date)
    
    func fetchHabit(habitName: String) -> Habit?
    
    /// This function adds a listener that will be notified when there is a change to the saved meals and / or ingredients.
    /// - parameter listener: a `DatabaseListener` to be added
    func addListener(listener: DatabaseListener)
    
    /// This function removes a listener.
    /// - parameter listener: a `DatabaseListener` to be removed
    func removeListener(listener: DatabaseListener)
    
    /// This function saves any changes made to the main context.
    func cleanup()
}
