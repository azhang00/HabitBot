//
//  HabitDate+CoreDataProperties.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//
//

import Foundation
import CoreData


extension HabitDate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HabitDate> {
        return NSFetchRequest<HabitDate>(entityName: "HabitDate")
    }

    @NSManaged public var date: Date?
    @NSManaged public var habits: Set<HabitData>?

}

// MARK: Generated accessors for habits
extension HabitDate {

    @objc(addHabitsObject:)
    @NSManaged public func addToHabits(_ value: HabitData)

    @objc(removeHabitsObject:)
    @NSManaged public func removeFromHabits(_ value: HabitData)

    @objc(addHabits:)
    @NSManaged public func addToHabits(_ values: Set<HabitData>)

    @objc(removeHabits:)
    @NSManaged public func removeFromHabits(_ values: Set<HabitData>)

}

extension HabitDate : Identifiable {

}
