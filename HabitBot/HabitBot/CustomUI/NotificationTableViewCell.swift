//
//  NotificationTableViewCell.swift
//  HabitBot
//
//  Created by Anna Zhang on 6/5/21.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {

    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var notificationSwitch: UISwitch!
    var view: UIViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    /// This function handles the action of users toggling the push notification switch and will trigger an alert to inform users to navigate to Settings to change their notification settings for the application.
    /// - parameter sender: `UISwitch` object that was toggled.
    @IBAction func toggleNotificationSettings(_ sender: UISwitch) {
        let alertController = UIAlertController(title: "Change push notification settings", message: "Please change notification settings by navigating to your device's Settings app > HabitBot > Notifications > Allow Notifications.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { _ in
            sender.setOn(!sender.isOn, animated: true)
        }))
        self.view?.present(alertController, animated: true, completion: nil)
    }
    
}
