//
//  QuoteData.swift
//  HabitBot
//
//  Created by Anna Zhang on 20/5/21.
//

import UIKit

class QuoteData: Codable {
    var quote: String
    var author: String?
    
    private enum CodingKeys: String, CodingKey {
        case quote = "q"
        case author = "a"
    }
}
