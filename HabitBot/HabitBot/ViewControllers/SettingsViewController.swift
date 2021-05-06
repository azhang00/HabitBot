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
    
    let SECTION_REMINDERS = 0
    let SECTION_INFO = 1
    let CELL_NOTIF = "notificationCell"
    let CELL_INFO = "appInstructCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                return 1
            case SECTION_INFO:
                return 1
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
            reminderCell.notificationLabel?.text = "Push notifications"
            
            // check whether notifications are turned on and toggle the switch accordingly
            let notifCenter = UNUserNotificationCenter.current()
            notifCenter.getNotificationSettings(completionHandler: { permission in
                if permission.authorizationStatus == .authorized {
                    DispatchQueue.main.async {
                        reminderCell.notificationSwitch.isOn = true
                    }
                } else {
                    DispatchQueue.main.async {
                        reminderCell.notificationSwitch.isOn = false
                    }
                }
            })
            return reminderCell
        }
        
        let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
        infoCell.textLabel?.text = "How to use the application"
        return infoCell
    }

}
