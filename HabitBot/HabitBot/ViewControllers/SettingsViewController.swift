//
//  SettingsViewController.swift
//  HabitBot
//
//  Created by Anna Zhang on 23/4/21.
//

import UIKit
import UserNotifications

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var settingsTableView: UITableView!
    
    weak var databaseController: DatabaseProtocol?
    
    let SECTION_REMINDERS = 0
    let SECTION_INFO = 1
    let CELL_NOTIF = "notificationCell"
    let CELL_INFO = "appInstructCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        self.settingsTableView.delegate = self
        self.settingsTableView.dataSource = self
    }
    
    // MARK: - TableView functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case SECTION_REMINDERS:
                return 2
            case SECTION_INFO:
                return 2
            default:
                return 0
       }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case SECTION_REMINDERS:
                return "Push Notifications"
            case SECTION_INFO:
                return "Information"
            default:
                return ""
       }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_REMINDERS {
            let reminderCell = tableView.dequeueReusableCell(withIdentifier: CELL_NOTIF, for: indexPath) as! NotificationTableViewCell
            reminderCell.view = self
            
            if indexPath.row == 0 {
                reminderCell.notificationLabel?.text = "Habit reminder notifications"
                reminderCell.notificationType = "reminders"
            } else if indexPath.row == 1 {
                reminderCell.notificationLabel?.text = "Daily motivational quotes"
                reminderCell.notificationType = "quotes"
            }
            
            // check whether notifications are turned on and toggle the switch accordingly
            let notifCenter = UNUserNotificationCenter.current()
            notifCenter.getNotificationSettings(completionHandler: { permission in
                if permission.authorizationStatus == .authorized {
                    DispatchQueue.main.async {
                        if indexPath.row == 0 {
                            reminderCell.notificationSwitch.isOn = self.databaseController!.getNotificationSettings(type: "reminders")
                        } else {
                            reminderCell.notificationSwitch.isOn = self.databaseController!.getNotificationSettings(type: "quotes")
                        }
                        reminderCell.systemNotificationsEnabled = true
                    }
                } else {
                    DispatchQueue.main.async {
                        reminderCell.notificationSwitch.isOn = false
                        reminderCell.systemNotificationsEnabled = false
                    }
                }
            })
            return reminderCell
        }
        
        let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
        if indexPath.row == 0 {
            infoCell.textLabel?.text = "How to use the application"
        } else if indexPath.row == 1 {
            infoCell.textLabel?.text = "About the app"
        }
        return infoCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == SECTION_INFO {
            if indexPath.row == 0 {
                // navigate to the instructions view
                let instructionsViewController = self.storyboard?.instantiateViewController(withIdentifier: "InstructionsViewController") as! InstructionsViewController
                instructionsViewController.title = "Instructions"
                navigationController?.pushViewController(instructionsViewController, animated: true)
            } else {
                // navigate to the about view
                let instructionsViewController = self.storyboard?.instantiateViewController(withIdentifier: "InstructionsViewController") as! InstructionsViewController
                navigationController?.pushViewController(instructionsViewController, animated: true)
            }
        }
    }
}
