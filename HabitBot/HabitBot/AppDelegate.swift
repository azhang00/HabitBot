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
    
    let TASK_IDENTIFIER = "HabitBot.DailyQuotes"

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
                self.databaseController?.initialiseUserSettings(notificationsEnabled: false)
            } else {
                self.databaseController?.initialiseUserSettings(notificationsEnabled: true)
            }
        }
        
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: {
            settings in
            if settings.authorizationStatus == .authorized {
                // register daily quotes notification task
                BGTaskScheduler.shared.register(forTaskWithIdentifier: self.TASK_IDENTIFIER, using: nil) { task in
                    self.handleQuoteNotificationBGTask(task: task as! BGAppRefreshTask)
                }
                self.scheduleQuoteNotification()
                // self.sendDailyQuoteNotification()
            }
        })
        
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
                    // get updated health data
                    self.updateHealthData(types: allTypes)
                    // set up observer for health data so the app can get background updates
                    self.setUpBackgroundHealthDataObserver(allTypes: allTypes)
                }
            }
        }
        return true
    }
    
    /// This function sets up observers for health data.
    /// - parameter allTypes: a set of all `HKSampleType` data that the application wants to observe from the Health app
    func setUpBackgroundHealthDataObserver(allTypes: Set<HKSampleType>) {
        // update frequency is set to hourly by default
        var frequency = HKUpdateFrequency.hourly
        for type in allTypes {
            if type.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue {
                // sleep data updates daily
                frequency = HKUpdateFrequency.daily
            }
            
            // set up background delivery for each HealthKit data
            self.healthStore?.enableBackgroundDelivery(for: type, frequency: frequency, withCompletion: {
                success, error in
                if !success && error != nil {
                    print("Error in setting up background delivery for \(type).")
                }
            })
            
            // set up handler method when observed data changes
            let query = HKObserverQuery(sampleType: type, predicate: nil, updateHandler: {
                query, completionHandler, error in
                guard error != nil else {
                  return
                }
                // get updated health data
                self.updateHealthData(types: [type])
                completionHandler()
                
            })
            self.healthStore!.execute(query)
        }
    }
    
    /// This function obtains the updated health data from the Health app and stores the updates in core data.
    /// - parameter types: a set of all `HKSampleType` data that the application wants to obtain from the Health app
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
                    // fetch updated sleep data and store it in core data
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
                                // calculate the sleep duration
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
                        // fetch other health data and store it in core data
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
                                // get the health data for today's date
                                results.enumerateStatistics(from: startDate!, to: endDate as Date) { statistics, stop in
                                    if let quantity = statistics.sumQuantity() {
                                        let count = quantity.doubleValue(for: unit!)
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
                // increment habit count by 1 if it is a custom habit
                if habit!.type! == "custom" {
                    for habitData in habit!.habitData! {
                        if habitData.date!.date == Date().dateOnly() {
                            databaseController?.updateHabitCount(habitData: habitData, incrementVal: 1)
                            break
                        }
                    }
                } else {
                    // update habit count by obtaining health data if it is a special habit
                    switch habitName {
                    case "Distance Travelled":
                        updateHealthData(types: [HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!])
                    case "Steps":
                        updateHealthData(types: [HKObjectType.quantityType(forIdentifier: .stepCount)!])
                    case "Sleep Duration":
                        updateHealthData(types: [HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!])
                    default:
                        print("\(habitName) is not a valid special habit.")
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
    
    // MARK: Daily Motivational Quotes Background Task
    
    /// This function schedules a daily quote notification background task.
    func scheduleQuoteNotification() {
        // check that the user has enabled quote notifications
        if databaseController!.getNotificationSettings(type: "quotes") {
            let request = BGAppRefreshTaskRequest(identifier: TASK_IDENTIFIER)
            var taskExists = false
            
            // check if task already exists
            BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: {
                BGTaskRequests in
                for BGTaskRequest in BGTaskRequests {
                    
                    print(BGTaskRequest.identifier)
                    
                    if BGTaskRequest.identifier == self.TASK_IDENTIFIER {
                        taskExists = true
                    }
                }
            })
        
            if !taskExists {
                // schedule next task for 24 hours from now
                request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60 * 24)
                do {
                    try BGTaskScheduler.shared.submit(request)
                } catch {
                    print("Could not schedule daily motivational quote notification: \(error)")
                }
            }
        }
    }
    
    /// This function send the quote notification to send and schedules the next
    /// quote notification background task.
    func handleQuoteNotificationBGTask(task: BGAppRefreshTask) {        
        // schedule the next quote notification
        scheduleQuoteNotification()
        
        // send notification
        sendDailyQuoteNotification()
    }
    
    /// This functions retrieves a quote from an API and sends it in a push notification.
    func sendDailyQuoteNotification() {
        if databaseController!.getNotificationSettings(type: "quotes") {
            // get quote from API
            guard let url = URL(string: "https://zenquotes.io/api/today") else {
                print("URL not valid")
                return
            }
            
            // make a request to the API to obtain the daily quote
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                // print error if any
                if let error = error {
                    print(error)
                    return
                }
                
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let allQuotes = try decoder.decode([QuoteData].self, from: data)
                        let quote = allQuotes[0].quote
                        let author = allQuotes[0].author ?? "Unknown"
                        
                        // send notification
                        let content = UNMutableNotificationContent()
                        content.title = "Daily Quote"
                        content.body = "\(quote) — \(author)"
                        content.sound = UNNotificationSound.default
                        
                        // show notification in 5 seconds
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                        
                        let request = UNNotificationRequest(identifier: "DAILY QUOTE", content: content, trigger: trigger)
                        UNUserNotificationCenter.current().add(request)
                    } catch let err {
                        print(err)
                    }

                }
            }
            
            task.resume()
        }
    }
}

