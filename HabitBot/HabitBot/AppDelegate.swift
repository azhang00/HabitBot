//
//  AppDelegate.swift
//  HabitBot
//
//  Created by Anna Zhang on 21/4/21.
//

import UIKit
import CoreData
import UserNotifications
import HealthKit
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var databaseController: DatabaseProtocol?
    var healthStore: HKHealthStore?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        databaseController = CoreDataController()
        UNUserNotificationCenter.current().delegate = self
        
        // request notification permissions
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let _ = error {
                print("Error in getting notification permissions.")
            }
            if !granted {
                print("User has not allowed notifications.")
            }
        }
        
        // request healthkit permissions
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            let allTypes = Set([HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                                HKObjectType.quantityType(forIdentifier: .stepCount)!,
                                HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!])
            healthStore?.requestAuthorization(toShare: nil, read: allTypes) { (success, error) in
                if !success {
                    print("Did not get HealthKit access permissions.")
                } else {
                    print("Obtained HealthKit permissions.")
                    self.updateHealthData(types: allTypes)
                    self.setUpBackgroundHealthDataObserver(allTypes: allTypes)
                }
            }
        }
        return true
    }
    
    func setUpBackgroundHealthDataObserver(allTypes: Set<HKSampleType>) {
        // set up background delivery for each HealthKit data
        var frequency = HKUpdateFrequency.hourly
        for type in allTypes {
            if type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
                frequency = HKUpdateFrequency.daily
            }
            self.healthStore?.enableBackgroundDelivery(for: type, frequency: frequency, withCompletion: {
                success, error in
                if !success && error != nil {
                    print("Error in setting up background delivery for \(type).")
                }
            })
            
            let query = HKObserverQuery(sampleType: type, predicate: nil, updateHandler: {
                query, completionHandler, error in
                guard error != nil else {
                  return
                }
                self.updateHealthData(types: [type])
                completionHandler()
                
            })
            self.healthStore!.execute(query)
        }
    }
    
    func updateHealthData(types: Set<HKSampleType>) {
        // create day interval and anchor date
        let calendar = Calendar.current
        let interval = DateComponents(day: 1)
        var components = calendar.dateComponents([.day, .month, .year], from: Date())
        components.hour = 0
        let anchorDate = calendar.date(from: components)
        
        // update each health data type
        for type in types {
            var habitName: String?
            var unit: HKUnit?
            switch type {
            case HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!:
                habitName = "Distance Travelled"
                unit = HKUnit.meter()
            case HKObjectType.quantityType(forIdentifier: .stepCount)!:
                habitName = "Steps"
                unit = HKUnit.count()
            case HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!:
                habitName = "Sleep Duration"
            default:
                print("HKObjectType: \(type) not supported.")
                continue
            }
            
            if habitName != nil {
                // check that there is a habit associated with the health data
                let habit = databaseController?.fetchHabit(habitName: habitName!)
                
                // get today's habitData
                var habitData: HabitData?
                if habit != nil {
                    for data in habit!.habitData! {
                        if data.date!.date == Date().dateOnly() {
                            habitData = data
                            break
                        }
                    }
                }
                if habitData != nil {
                    if habitName == "Sleep Duration" {
                        var startDate = Date()
                        startDate.addTimeInterval(-60*60*24)
                        startDate = startDate.setTime(hour: 12, minute: 0, second: 0)
                        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
                        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 100000, sortDescriptors: [sortDescriptor]) { (query, result, error) -> Void in
                            if error != nil {
                                print("Error in retrieving sleep data: \(error!)")
                            } else {
                                var totalTime = 0
                                if let result = result {
                                   for item in result {
                                        if let sample = item as? HKCategorySample {
                                            let sleepTime = sample.endDate.timeIntervalSince(sample.startDate)
                                            totalTime += Int(sleepTime)
                                        }
                                    }
                                }
                                self.databaseController?.updateHabitCount(habitData: habitData!, incrementVal: Int64(totalTime/60/60))
                            }
                        }
                        healthStore?.execute(query)
                    } else {
                        // fetch health data
                        let query = HKStatisticsCollectionQuery(quantityType: type as! HKQuantityType,
                                                                quantitySamplePredicate: nil,
                                                                options: .cumulativeSum,
                                                                anchorDate: anchorDate!,
                                                                intervalComponents: interval)
                        query.initialResultsHandler = {
                            query, results, error in
                            if error != nil {
                                print("Error in retrieving health data: \(error!)")
                            }
                            
                            let endDate = NSDate()
                            let startDate = calendar.date(byAdding: .day, value: 0, to: endDate as Date, wrappingComponents: false)
                            if let results = results {
                                results.enumerateStatistics(from: startDate!, to: endDate as Date) { statistics, stop in
                                    if let quantity = statistics.sumQuantity() {
                                        let date = statistics.startDate
                                        let count = quantity.doubleValue(for: unit!)
                                        print("\(date): \(habitName!) = \(count)")
                                        self.databaseController?.updateHabitCount(habitData: habitData!, incrementVal: Int64(count))
                                    }
                                }
                            }
                        }
                        healthStore?.execute(query)
                    }
                }
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // MARK: Handle User Notification
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
           didReceive response: UNNotificationResponse,
           withCompletionHandler completionHandler:
             @escaping () -> Void) {
        switch response.actionIdentifier {
        case "ACCEPT_ACTION":
            let habitName = response.notification.request.content.userInfo["habitName"] as! String
            // get habit
            let habit = databaseController?.fetchHabit(habitName: habitName)
            if habit != nil {
                for habitData in habit!.habitData! {
                    if habitData.date!.date == Date().dateOnly() {
                        databaseController?.updateHabitCount(habitData: habitData, incrementVal: 1)
                        break
                    }
                }
            }
            break
        case "DECLINE_ACTION":
            // do nothing if user hasn't completed the task
            break
        default:
            break
        }
        completionHandler()
    }
}

