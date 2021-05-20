//
//  AboutViewController.swift
//  HabitBot
//
//  Created by Anna Zhang on 20/5/21.
//

import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var aboutTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let attributedString = NSMutableAttributedString(string: "HabitBot is an habit tracker application that helps users achieve their personal habit goals through an easy-to-use tracking system, and motivates them with customisable reminder notifications, insightful summaries and streaks data, and daily motivational quotes.\n\nAll quotes are obtained via the API provided by ZenQuotes.io. Charts generated in the application utilises Daniel Cohen Gindi & Philipp Jahoda's Charts library. Custom text views are from TextFieldEffects.")
        
        // make links for the text
        let apiURL = URL(string: "https://zenquotes.io/")!
        let chartsURL = URL(string: "https://github.com/danielgindi/Charts")!
        let textFieldURL = URL(string: "https://github.com/raulriera/TextFieldEffects")!
        
        let apiRange = NSMakeRange(313, 12)
        let chartsRange = NSMakeRange(372, 52)
        let textFieldRange = NSMakeRange(453, 16)

        // insert links into the text
        attributedString.setAttributes([.font: UIFont.preferredFont(forTextStyle: .body)], range: NSMakeRange(0, attributedString.length))
        
        attributedString.setAttributes([.link: apiURL], range: apiRange)
        attributedString.setAttributes([.link: chartsURL], range: chartsRange)
        attributedString.setAttributes([.link: textFieldURL], range: textFieldRange)
        
        // for some reason, need to remove the existing font for links to add the body font
        attributedString.removeAttribute(NSAttributedString.Key.font, range: apiRange)
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.preferredFont(forTextStyle: .body), range: apiRange)
        attributedString.removeAttribute(NSAttributedString.Key.font, range: chartsRange)
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.preferredFont(forTextStyle: .body), range: chartsRange)
        attributedString.removeAttribute(NSAttributedString.Key.font, range: textFieldRange)
        attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.preferredFont(forTextStyle: .body), range: textFieldRange)

        aboutTextView.attributedText = attributedString
        aboutTextView.isUserInteractionEnabled = true
        aboutTextView.isEditable = false

        // set link format
        aboutTextView.linkTextAttributes = [
            .foregroundColor: UIColor(named: "PurpleColour")!,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
