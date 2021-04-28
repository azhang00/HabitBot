//
//  Habit.swift
//  HabitBot
//
//  Created by Anna Zhang on 22/4/21.
//

import UIKit

class Habit: NSObject {
    var title: String
    var count: String
    var colour: UIColor
    
    init(title: String, count: String, colour: UIColor) {
        self.title = title
        self.count = count
        self.colour = colour
    }

}
