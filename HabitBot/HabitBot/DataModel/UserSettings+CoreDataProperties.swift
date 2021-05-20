//
//  UserSettings+CoreDataProperties.swift
//  HabitBot
//
//  Created by Anna Zhang on 20/5/21.
//
//

import Foundation
import CoreData


extension UserSettings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserSettings> {
        return NSFetchRequest<UserSettings>(entityName: "UserSettings")
    }

    @NSManaged public var reminderNotifications: Bool
    @NSManaged public var dailyQuotes: Bool
    @NSManaged public var userID: String?

}

extension UserSettings : Identifiable {

}
