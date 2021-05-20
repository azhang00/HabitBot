//
//  StringExtension.swift
//  HabitBot
//
//  Created by Anna Zhang on 19/5/21.
//

import Foundation

extension String {
    /// This function returns the string with the first letter capitalised. Note that it does not mutate the original string.
    /// - returns a new String with the first letter capitalised
    func capitaliseFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}
