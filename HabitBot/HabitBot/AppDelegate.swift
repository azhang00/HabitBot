//
//  AppDelegate.swift
//  HabitBot
//
//  Created by Anna Zhang on 21/4/21.
//

import UIKit
import CoreData
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var databaseController: DatabaseProtocol?

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
        return true
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

