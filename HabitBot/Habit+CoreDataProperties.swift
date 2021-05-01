//
//  Habit+CoreDataProperties.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//
//

import Foundation
import CoreData


extension Habit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Habit> {
        return NSFetchRequest<Habit>(entityName: "Habit")
    }

    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var frequencyDuration: String?
    @NSManaged public var frequency: Int64
    @NSManaged public var freqDescription: String?
    @NSManaged public var colour: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var habitData: Set<HabitData>?
    @NSManaged public var reminder: Reminder?

}

// MARK: Generated accessors for habitData
extension Habit {

    @objc(addHabitDataObject:)
    @NSManaged public func addToHabitData(_ value: HabitData)

    @objc(removeHabitDataObject:)
    @NSManaged public func removeFromHabitData(_ value: HabitData)

    @objc(addHabitData:)
    @NSManaged public func addToHabitData(_ values: Set<HabitData>)

    @objc(removeHabitData:)
    @NSManaged public func removeFromHabitData(_ values: Set<HabitData>)

}

extension Habit : Identifiable {

}
