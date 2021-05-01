//
//  UIViewControllerAlertExtension.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//

import UIKit

extension UIViewController {
    
    /// This function displays an error message using UIAlertController.
    /// - parameter title: title of the alert
    /// - parameter message: error message to be shown in the laert
    func displayErrorMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
