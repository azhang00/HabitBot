//
//  SummaryTableViewCell.swift
//  HabitBot
//
//  Created by Anna Zhang on 19/5/21.
//

import UIKit

class SummaryTableViewCell: UITableViewCell {

    @IBOutlet weak var habitBackgroundView: UIView!
    @IBOutlet weak var habitTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
