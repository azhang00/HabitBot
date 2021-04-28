//
//  HabitTableViewCell.swift
//  HabitBot
//
//  Created by Anna Zhang on 22/4/21.
//

import UIKit

class HabitTableViewCell: UITableViewCell {

    @IBOutlet weak var habitBackgroundView: UIView!
    @IBOutlet weak var habitTitle: UILabel!
    @IBOutlet weak var habitCount: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
