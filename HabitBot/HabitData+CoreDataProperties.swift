//
//  HabitData+CoreDataProperties.swift
//  HabitBot
//
//  Created by Anna Zhang on 1/5/21.
//
//

import Foundation
import CoreData


extension HabitData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HabitData> {
        return NSFetchRequest<HabitData>(entityName: "HabitData")
    }

    @NSManaged public var count: Int64
    @NSManaged public var habit: Habit?
    @NSManaged public var date: HabitDate?

}

extension HabitData : Identifiable {

}
