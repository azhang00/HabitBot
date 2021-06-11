//
//  CoreDataController.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//

import UIKit
import CoreData
import BackgroundTasks

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistentContainer: NSPersistentContainer
    var allHabitDataFetchedResultsController: NSFetchedResultsController<HabitData>?
    var allHabitDatesFetchedResultsController: NSFetchedResultsController<HabitDate>?
    var allHabitFetchedResultsController: NSFetchedResultsController<Habit>?
    var allRemindersFetchedResultsController: NSFetchedResultsController<Reminder>?
    var childContext: NSManagedObjectContext?
    
    let USER_ID = "default"
    
    override init() {
        // initialise persistent container
        persistentContainer = NSPersistentContainer(name: "HabitBot")
        persistentContainer.loadPersistentStores() { (description, error ) in
            if let error = error {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        }
        
        // create child context
        childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext?.parent = persistentContainer.viewContext
        
        super.init()
        
        // create habit dates if none exist
        if fetchAllHabitDates().count == 0 {
            createOneMonthOfHabitDates(startDate: Date().dateOnly())
        }
        
    }
    
    // MARK: - Habit methods
    
    func createHabit(name: String, type: String, frequencyDuration: String, frequency: Int64, freqDescription: String, colour: String) -> Habit {
        let habit = NSEntityDescription.insertNewObject(forEntityName: "Habit", into: persistentContainer.viewContext) as! Habit
        habit.name = name
        habit.type = type
        habit.frequencyDuration = frequencyDuration
        habit.frequency = frequency
        habit.freqDescription = freqDescription
        habit.colour = colour
        
        let currentDate = Date().dateOnly()
        habit.startDate = currentDate
        createHabitData(habit: habit, startDate: currentDate)
        return habit
    }
    
    func getChildContextHabit(habit: Habit) -> Habit {
        // delete any Habit objects that may have been created in the child context
        childContext?.reset()
        
        // if a Habit object is not provided, create a new child context Habit
        let childContextHabit = childContext?.object(with: habit.objectID) as! Habit
        return childContextHabit
    }
    
    func saveHabitEdit(habit: Habit) {
        do {
            try childContext?.save()
        } catch {
            fatalError("Failed to save changes to Core Data with error: \(error)")
        }
        // once the changes have been saved in persistent storage, we can reset the child context
        childContext?.reset()
    }
    
    func deleteHabit(habit: Habit) {
        deleteReminder(habit: habit)
        persistentContainer.viewContext.delete(habit)
    }
    
    // MARK: - Reminder methods
    
    func setReminder(habit: Habit, startTime: Date, msgDescription: String, completeMsg: String, incompleteMsg: String, frequency: Int64, count: Int64) {
        // delete the existing reminder if there already is one
        if habit.reminder != nil {
            deleteReminder(habit: habit)
        }
        
        // create the new reminder
        let reminder = NSEntityDescription.insertNewObject(forEntityName: "Reminder", into: habit.managedObjectContext!) as! Reminder
        reminder.startTime = startTime
        reminder.msgDescription = msgDescription
        reminder.completeMsg = completeMsg
        reminder.incompleteMsg = incompleteMsg
        reminder.frequency = frequency
        reminder.count = count
        habit.reminder = reminder
        
        // create recurring system notification
        if getNotificationSettings(type: "reminders") {
            createReminderNotification(reminder: reminder)
        }
    }
    
    func deleteReminder(habit: Habit) {
        if habit.reminder != nil {
            deleteReminderNotification(reminderName: habit.name!)
            habit.managedObjectContext!.delete(habit.reminder!)
            habit.reminder = nil
        }
    }
    
    /// This function schedules a new recurring reminder notification.
    /// - parameter reminder: reminder to be scheduled
    func createReminderNotification(reminder: Reminder) {
        // custom notification actions
        let completeAction = UNNotificationAction(identifier: "ACCEPT_ACTION",
                                                  title: reminder.completeMsg!,
                                                  options: [])
        
        let incompleteAction = UNNotificationAction(identifier: "DECLINE_ACTION",
                                                    title: reminder.incompleteMsg!,
                                                    options: [])
        
        // create notification category
        let recurringNotificationCategory =
            UNNotificationCategory(identifier: reminder.habit!.name!,
              actions: [completeAction, incompleteAction],
              intentIdentifiers: [],
              hiddenPreviewsBodyPlaceholder: "",
              options: .customDismissAction)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([recurringNotificationCategory])
        
        let content = UNMutableNotificationContent()
        content.title = reminder.habit!.name!
        content.body = reminder.msgDescription!
        content.categoryIdentifier = recurringNotificationCategory.identifier
        content.userInfo = ["habitName": reminder.habit!.name!]
        content.sound = UNNotificationSound.default
           
        // create the repeating notifications
        var hourIncrement = 0
        for _ in 1...reminder.count {
            var date = DateComponents()
            date.hour = (reminder.startTime?.getHour())! + hourIncrement
            date.minute = (reminder.startTime?.getMinutes())! + hourIncrement
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            
            // create the request
            let request = UNNotificationRequest(identifier: recurringNotificationCategory.identifier + "\(hourIncrement)",
                        content: content, trigger: trigger)
            
            // Schedule the request with the system.
            notificationCenter.add(request) { (error) in
                if error != nil {
                    print("Failed to create the notification.")
                }
            }
            hourIncrement += Int(reminder.frequency)
        }
    }
    
    /// This function deletes a recurring reminder from the notification center.
    /// - parameter reminderName: name of the reminder to be deleted
    func deleteReminderNotification(reminderName: String) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                if request.identifier.contains(reminderName) {
                    notificationCenter.removePendingNotificationRequests(withIdentifiers: [request.identifier])
                }
            }
        })
    }
    
    // MARK: - HabitDate methods
    
    func createOneMonthOfHabitDates(startDate: Date) {
        var currentDate = startDate
        // create 35 new days - 35 was chosen as it is exactly 5 weeks
        for _ in 1...35 {
            let newDate = NSEntityDescription.insertNewObject(forEntityName: "HabitDate", into: persistentContainer.viewContext) as! HabitDate
            newDate.date = currentDate
            currentDate.addTimeInterval(60*60*24)
        }
        cleanup()
        
        // create habitData for the new days
        let allHabits = fetchAllHabits()
        for habit in allHabits {
            createHabitData(habit: habit, startDate: startDate)
        }
    }
    
    // MARK: - HabitData methods
    
    /// This function creates new HabitData for a Habit starting at the provided start date.
    /// - parameter habit: the new HabitData's habit
    /// - parameter startDate: the first date that the new HabitData objects should be created for
    func createHabitData(habit: Habit, startDate: Date) {
        let habitDates = fetchAllHabitDates()
        for date in habitDates {
            // create a new HabitData for the existing dates starting from the start date
            if date.date! >= startDate {
                let habitData = NSEntityDescription.insertNewObject(forEntityName: "HabitData", into: persistentContainer.viewContext) as! HabitData
                habitData.count = 0
                date.addToHabits(habitData)
                habit.addToHabitData(habitData)
            }
        }
    }
    
    func updateHabitCount(habitData: HabitData, incrementVal: Int64) {
        // if the habit is weekly, increment/set the counts for all the habitData within the week
        if habitData.habit?.frequencyDuration == "weekly" {
            let sortedHabitDataByDates = Array(habitData.habit!.habitData!).sorted {
                return $0.date!.date! < $1.date!.date!
            }
            let currentDateIndex = sortedHabitDataByDates.firstIndex(of: habitData)!
            let weekDay = habitData.date!.date!.getWeekDay()
            // get the index of the first day of the week
            let firstDayIndex = currentDateIndex - weekDay + 1
            for i in 1...7 {
                if (firstDayIndex + i) > -1 && (firstDayIndex + i) < sortedHabitDataByDates.count {
                    if habitData.habit?.type == "custom" {
                        sortedHabitDataByDates[firstDayIndex + i].count += incrementVal
                    } else {
                        sortedHabitDataByDates[firstDayIndex + i].count = incrementVal
                    }
                }
            }
        } else {
            // only increment/set the count of a single habitData if it's a daily habit
            if habitData.habit?.type == "custom" {
                habitData.count += incrementVal
            } else {
                habitData.count = incrementVal
            }
        }
    }
    
    // MARK: - Notification Settings methods
    
    func initialiseUserSettings(notificationsEnabled: Bool) {
        // only create user settings if it doesn't exist in persistent storage
        if fetchUserSettings() == nil {
            let userSettings = NSEntityDescription.insertNewObject(forEntityName: "UserSettings", into: persistentContainer.viewContext) as! UserSettings
            userSettings.userID = USER_ID
            userSettings.reminderNotifications = notificationsEnabled
            userSettings.dailyQuotes = notificationsEnabled
            cleanup()
        }
    }
    
    func changeNotificationSettings(type: String, enabled: Bool) {
        if let userSettings = fetchUserSettings() {
            if type == "reminders" {
                userSettings.reminderNotifications = enabled
                
                if !enabled {
                    // delete all existing reminders
                    for habit in fetchAllHabits() {
                        deleteReminder(habit: habit)
                    }
                }
            }
            else if type == "quotes" {
                userSettings.dailyQuotes = enabled
                
                if !enabled {
                    BGTaskScheduler.shared.cancelAllTaskRequests()
                }
            }
        }
    }
    
    func getNotificationSettings(type: String) -> Bool {
        if let userSettings = fetchUserSettings() {
            if type == "reminders" {
                return userSettings.reminderNotifications
            }
            return userSettings.dailyQuotes
        }
        return false
    }
    
    // MARK: - Fetch methods
    
    /// This function fetches all HabitData from persistent storage.
    /// - returns: an array containing all `HabitData` objects in the database.
    func fetchAllHabitData() -> [HabitData] {
        if allHabitDataFetchedResultsController == nil {
            // make a request to fetch all meals that are sorted in ascending order by their name
            let request: NSFetchRequest<HabitData> = HabitData.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(keyPath: \HabitData.habit?.name, ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            // initialise fetched results controller
            allHabitDataFetchedResultsController = NSFetchedResultsController<HabitData>(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            // set this object to be the results delegate
            allHabitDataFetchedResultsController?.delegate = self
            
            // make the fetch
            do {
                try allHabitDataFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        // return the fetched HabitData
        if let habitData = allHabitDataFetchedResultsController?.fetchedObjects {
            return habitData
        }
        return [HabitData]()
    }
    
    /// This function fetches all HabitDates from persistent storage.
    /// - returns: an array containing all `HabitDate` objects in the database.
    func fetchAllHabitDates() -> [HabitDate] {
        if allHabitDatesFetchedResultsController == nil {
            // make a request to fetch all HabitDates that are sorted in ascending order by their date
            let request: NSFetchRequest<HabitDate> = HabitDate.fetchRequest()
            let dateSortDescriptor = NSSortDescriptor(key: "date", ascending: true)
            request.sortDescriptors = [dateSortDescriptor]
            
            // initialise fetched results controller
            allHabitDatesFetchedResultsController = NSFetchedResultsController<HabitDate>(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            // set this object to be the results delegate
            allHabitDatesFetchedResultsController?.delegate = self
            
            // make the fetch
            do {
                try allHabitDatesFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        // if there are any HabitDates fetched, return the array of HabitDates; otherwise, return
        // an empty HabitDate array
        if let habitDate = allHabitDatesFetchedResultsController?.fetchedObjects {
            return habitDate
        }
        return [HabitDate]()
    }
    
    /// This function fetches all Habits from persistent storage.
    /// - returns: an array containing all `Habit` objects in the database.
    func fetchAllHabits() -> [Habit] {
        if allHabitFetchedResultsController == nil {
            // make a request to fetch all habits that are sorted in ascending order by their name
            let request: NSFetchRequest<Habit> = Habit.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            // initialise fetched results controller
            allHabitFetchedResultsController = NSFetchedResultsController<Habit>(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            // set this object to be the results delegate
            allHabitFetchedResultsController?.delegate = self
            
            // make the fetch
            do {
                try allHabitFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        // return the fetched habits
        if let habits = allHabitFetchedResultsController?.fetchedObjects {
            return habits
        }
        return [Habit]()
    }
    
    func fetchHabit(habitName: String) -> Habit? {
        // make a request to the habit with the provided habit name
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", habitName)
        
        // make the fetch
        do {
            let habit = try persistentContainer.viewContext.fetch(request)
            if habit.count >= 1 {
                return habit[0]
            }
        } catch {
            print("Fetch Request Failed: \(error)")
        }
        return nil
    }
    
    /// This function fetches all Reminders from persistent storage.
    /// - returns: an array containing all `Reminder` objects in the database.
    func fetchAllReminders() -> [Reminder] {
        if allHabitFetchedResultsController == nil {
            // make a request to fetch all reminders that are sorted in ascending order by their time
            let request: NSFetchRequest<Reminder> = Reminder.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "startTime", ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
            // initialise fetched results controller
            allRemindersFetchedResultsController = NSFetchedResultsController<Reminder>(fetchRequest: request, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
            
            // set this object to be the results delegate
            allRemindersFetchedResultsController?.delegate = self
            
            // make the fetch
            do {
                try allRemindersFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        // return the fetched reminders
        if let reminders = allRemindersFetchedResultsController?.fetchedObjects {
            return reminders
        }
        return [Reminder]()
    }
    
    /// This function fetches a user's settings from persistent storage.
    func fetchUserSettings() -> UserSettings? {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", USER_ID)
        
        // make the fetch
        do {
            let userSettings = try persistentContainer.viewContext.fetch(request)
            if userSettings.count >= 1 {
                return userSettings[0]
            }
        } catch {
            print("Fetch Request Failed: \(error)")
        }
        return nil
    }
    
    // MARK: - Methods related to listeners
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        if listener.listenerType == .habitData || listener.listenerType == .all {
            listener.onHabitDataForADateChange(change: .update, habitData: fetchAllHabitData())
        }
        if listener.listenerType == .habitDate || listener.listenerType == .all {
            listener.onHabitDateChange(change: .update, habitDate: fetchAllHabitDates())
        }
        if listener.listenerType == .habit || listener.listenerType == .all {
            listener.onHabitChange(change: .update, habit: fetchAllHabits())
        }
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func cleanup() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("Failed to save changes to Core Data with error: \(error)")
            }
        }
    }
    
    // MARK: - Fetched Results Controller Protocol methods
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == allHabitDataFetchedResultsController {
            listeners.invoke() { listener in
                if listener.listenerType == .habitData || listener.listenerType == .all {
                    listener.onHabitDataForADateChange(change: .update, habitData: fetchAllHabitData())
                }
            }
        } else if controller == allHabitDatesFetchedResultsController {
            listeners.invoke { listener in
                if listener.listenerType == .habitDate || listener.listenerType == .all {
                    listener.onHabitDateChange(change: .update, habitDate: fetchAllHabitDates())
                }
            }
        }
    }
}
