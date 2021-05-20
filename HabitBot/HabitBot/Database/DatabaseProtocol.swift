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
    case habit
    case all
}

protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType {get set}
    
    /// This function handles the event of HabitData changing in the database and will update the tableview.
    /// - parameter change: database change type - e.g. add, remove, update
    /// - parameter habitData: an array containing all `HabitData` in the database
    func onHabitDataForADateChange(change: DatabaseChange, habitData: [HabitData])
    
    /// This function handles the event of HabitDates changing in the database and will update the tableview.
    /// - parameter change: database change type - e.g. add, remove, update
    /// - parameter habitDate: an array containing all `HabitDate`s in the database
    func onHabitDateChange(change: DatabaseChange, habitDate: [HabitDate])
    
    /// This function handles the event of Habits changing in the database and will update the tableview.
    /// - parameter change: database change type - e.g. add, remove, update
    /// - parameter habitDate: an array containing all `Habit`s in the database
    func onHabitChange(change: DatabaseChange, habit: [Habit])
}

protocol DatabaseProtocol: AnyObject {
    /// This function initialises the user settings
    /// - parameter notificationsEnabled: true if users have enabled notification settings; false otherwise
    func initialiseUserSettings(notificationsEnabled: Bool)
    
    /// This function changes the user notification settings.
    /// - parameter type: type of notification setting ('reminders' or 'quotes')
    /// - parameter enabled: `Boolean` value for whether the notification should be enabled or not
    func changeNotificationSettings(type: String, enabled: Bool)
    
    /// This function returns whether the specified type of notification is enable or not.
    /// - parameter type: type of notification setting ('reminders' or 'quotes')
    /// - returns: true if the notification type is enabled; false otherwise
    func getNotificationSettings(type: String) -> Bool
    
    /// This function creates a new habit.
    /// - parameter name: name of the new habit
    /// - parameter type: type of the new habit - i.e. custom or special
    /// - parameter frequencyDuration: how frequently the habit goal should be met - i.e. daily, weekly
    /// - parameter frequency: frequency goal for the new habit
    /// - parameter freqDescription: frequency descriptor for the new habit - e.g. Times
    /// - parameter colour: colour of the new habit
    func createHabit(name: String, type: String, frequencyDuration: String, frequency: Int64, freqDescription: String, colour: String) -> Habit
    
    /// This function creates a copy of the habit in the child context and returns it.
    /// - parameter habit: habit to be copied
    /// - returns: a copy of the habit in the child context
    func getChildContextHabit(habit: Habit) -> Habit
    
    /// This function saves any changes made to the habit.
    /// - parameter habit: habit to be saved
    func saveHabitEdit(habit: Habit)
    
    /// This function deletes a habit from the database.
    /// - parameter habit: habit to be deleted
    func deleteHabit(habit: Habit)
    
    /// This function sets a new reminder for a habit.
    /// - parameter habit: habit that the reminder is set for
    /// - parameter startTime: time at which the reminder should start notifying each day
    /// - parameter msgDescription: message displayed in the reminder notification
    /// - parameter completeMsg: text displayed on the reminder as the descriptor for the 'user did complete task' action
    /// - parameter incompleteMsg: text displayed on the reminder as the descriptor for the 'user did not complete task' action
    /// - parameter frequency: describes how frequently the reminder notification should be sent
    /// - parameter count: max number of reminder notifications that should be sent within a day
    func setReminder(habit: Habit, startTime: Date, msgDescription: String, completeMsg: String, incompleteMsg: String, frequency: Int64, count: Int64)
    
    /// This function deletes a habit's reminder from the database.
    /// - parameter habit: the habit that should have their reminders cleared
    func deleteReminder(habit: Habit)
    
    /// This function updates the counter for a `HabitData`. If the `HabitData`'s habit type is "custom", the count will be incremented / decremented; if the type is special, the counter will be updated to be the incremental value since the value is obtained from the Health app.
    /// - parameter habitData: the `HabitData` object that needs to be updated
    /// - parameter incrementalVal: value that the counter should be updated by (can be positive or negative)
    func updateHabitCount(habitData: HabitData, incrementVal: Int64)
    
    /// This function creates one month (exactly 5 weeks) of new habit dates.
    /// - parameter startDate: the first date of the new habit dates
    func createOneMonthOfHabitDates(startDate: Date)
    
    /// This function returns the Habit that matches the provided habit name if it exists; if it does not exist, nil will be returned.
    /// - parameter habitName: name of the habit to be found
    /// - returns: the `Habit` that has the provided habit name if it exists; otherwise, nil
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
