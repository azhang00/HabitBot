//
//  Reminder+CoreDataProperties.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//
//

import Foundation
import CoreData


extension Reminder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reminder> {
        return NSFetchRequest<Reminder>(entityName: "Reminder")
    }

    @NSManaged public var msgDescription: String?
    @NSManaged public var completeMsg: String?
    @NSManaged public var incompleteMsg: String?
    @NSManaged public var count: Int64
    @NSManaged public var frequency: Int64
    @NSManaged public var startTime: Date?
    @NSManaged public var habit: Habit?

}

extension Reminder : Identifiable {

}
