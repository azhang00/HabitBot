//
//  CoreDataController.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//

import UIKit
import CoreData

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistentContainer: NSPersistentContainer
    var allHabitDataFetchedResultsController: NSFetchedResultsController<HabitData>?
    var allHabitDatesFetchedResultsController: NSFetchedResultsController<HabitDate>?
    var allHabitFetchedResultsController: NSFetchedResultsController<Habit>?
    var childContext: NSManagedObjectContext?
    
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
        
        // DELETE LATER
        if fetchAllHabits().count == 0 {
            createDefaultHabits()
        }
        
        if fetchAllHabitDates().count == 0 {
            createOneMonthOfHabitDates(startDate: Date().dateOnly())
        }
        
    }
    
    // DELETE LATER
    func createDefaultHabits() {
        let _ = createHabit(name: "Drink Water", type: "custom", frequencyDuration: "daily", frequency: 8, freqDescription: "Cups", colour: "DarkBlueColour")
        let _ = createHabit(name: "Steps", type: "special", frequencyDuration: "weekly", frequency: 10000, freqDescription: "Steps", colour: "DarkGreenColour")
    }
    
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
    
    func getChildContextHabit(habit: Habit?) -> Habit {
        // delete any Habit objects that may have been created in the child context
        childContext?.reset()
        
        // if a Habit object is not provided, create a new child context Habit
        if habit != nil {
            let childContextHabit = childContext?.object(with: habit!.objectID) as! Habit
            return childContextHabit
        }
        // Habit object is provided so a copy of it is made in the child context
        return NSEntityDescription.insertNewObject(forEntityName: "Habit", into: childContext!) as! Habit
    }
    
    func saveHabitEdit(habit: Habit) {
        do {
            try childContext?.save()
        } catch {
            fatalError("Failed to save changes to Core Data with error: \(error)")
        }
        // once the changes have been saved in persistent storage, we can delete the habit
        // from the child context
        childContext?.delete(habit)
    }
    
    func deleteHabit(habit: Habit) {
        persistentContainer.viewContext.delete(habit)
    }
    
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
    }
    
    func deleteReminder(habit: Habit) {
        if habit.reminder != nil {
            persistentContainer.viewContext.delete(habit.reminder!)
            habit.reminder = nil
        }
    }
    
    func updateHabitCount(habitData: HabitData, incrementVal: Int64) {
        habitData.count += incrementVal
    }
    
    func createOneMonthOfHabitDates(startDate: Date) {
        var currentDate = startDate
        // create 30 new days
        for _ in 1...30 {
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
    
    func createHabitData(habit: Habit, startDate: Date) {
        let habitDates = fetchAllHabitDates()
        var count = 0
        for date in habitDates {
            if date.date! >= startDate {
                count += 1
                let habitData = NSEntityDescription.insertNewObject(forEntityName: "HabitData", into: persistentContainer.viewContext) as! HabitData
                habitData.count = 0
                // habitData.habit = habit
                date.addToHabits(habitData)
                habit.addToHabitData(habitData)
            }
        }
    }
    
    func fetchAllHabitData() -> [HabitData] {
        if allHabitDataFetchedResultsController == nil {
            // make a request to fetch all meals that are sorted in ascending order by their name
            let request: NSFetchRequest<HabitData> = HabitData.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "count", ascending: true)
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
        
        // if there are any meals fetched, return the array of Meals; otherwise, return
        // an empty Meal array
        if let habitData = allHabitDataFetchedResultsController?.fetchedObjects {
            return habitData
        }
        return [HabitData]()
    }
    
    func fetchAllHabitDates() -> [HabitDate] {
        if allHabitDatesFetchedResultsController == nil {
            // make a request to fetch all HabitDates that are sorted in ascending order by their name
            let request: NSFetchRequest<HabitDate> = HabitDate.fetchRequest()
            let nameSortDescriptor = NSSortDescriptor(key: "date", ascending: true)
            request.sortDescriptors = [nameSortDescriptor]
            
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
        
        // if there are any meals fetched, return the array of Meals; otherwise, return
        // an empty Meal array
        if let habitDate = allHabitDatesFetchedResultsController?.fetchedObjects {
            return habitDate
        }
        return [HabitDate]()
    }
    
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
        
        // if there are any meals fetched, return the array of Meals; otherwise, return
        // an empty Meal array
        if let habits = allHabitFetchedResultsController?.fetchedObjects {
            return habits
        }
        return [Habit]()
    }
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        if listener.listenerType == .habitData || listener.listenerType == .all {
            listener.onHabitDataForADateChange(change: .update, habitData: fetchAllHabitData())
        }
        if listener.listenerType == .habitDate || listener.listenerType == .all {
            listener.onHabitDateChange(change: .update, habitDate: fetchAllHabitDates())
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
