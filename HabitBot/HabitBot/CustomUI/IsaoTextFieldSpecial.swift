//
//  IsaoTextFieldExtension.swift
//  HabitBot
//
//  Created by Anna Zhang on 21/5/21.
//

import UIKit
import TextFieldEffects

class IsaoTextFieldSpecial: IsaoTextField {
    
    var defaultPlaceholder: String?
    
    override func drawViewsForRect(_ rect: CGRect) {
        // save the original placeholder text and set the placeholder text to
        // an empty string if the user has entered text
        if let text = text, !text.isEmpty {
            defaultPlaceholder = placeholder
            placeholder = ""
        }
        
        super.drawViewsForRect(rect)
    }
    
    override open func textFieldDidEndEditing() {
        // do not display the placeholder text if the user has entered text
        if let text = text, !text.isEmpty {
            defaultPlaceholder = placeholder
            placeholder = ""
        } else {
            placeholder = defaultPlaceholder ?? ""
        }
        
        super.textFieldDidEndEditing()
    }
}
