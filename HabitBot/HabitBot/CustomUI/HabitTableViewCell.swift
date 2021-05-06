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
    
    var originalCenter = CGPoint()
    var habitData: HabitData?
    var tableView: UITableView?
    weak var databaseController: DatabaseProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        initialise()
    }
    
    /// This function sets up the swipe gesture recognisers.
    func initialise() {
        // set up right and left swipe gesture recognisers
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(gesture:)))
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(gesture:)))
        swipeRightGesture.direction = UISwipeGestureRecognizer.Direction.right
        swipeLeftGesture.direction = UISwipeGestureRecognizer.Direction.left
        self.addGestureRecognizer(swipeRightGesture)
        self.addGestureRecognizer(swipeLeftGesture)
    }
    
    /// This function handles the swipe gesture.
    /// - parameter gesture: swipe gesture
    @objc func handleSwipe(gesture: UISwipeGestureRecognizer) {
        // animate view off screen and increment/decrement habit count accordingly
        originalCenter = self.center
        
        // only custom habits' count can be manually edited by users
        if habitData!.habit?.type == "custom" {
            if gesture.direction == UISwipeGestureRecognizer.Direction.right {
                // do not allow left swiping if the habit's frequency is 0 - i.e. cannot be decremented further
                if habitData!.count == 0 {
                    return
                }
                UIView.animate(withDuration: 0.75, animations: { [self] in
                    self.center.x += self.bounds.width
                }, completion: { (value: Bool) in
                    self.center = self.originalCenter
                    // decrement habit data count by 1
                    self.databaseController?.updateHabitCount(habitData: self.habitData!, incrementVal: -1)
                    self.tableView?.reloadData()
                })
            } else if gesture.direction == UISwipeGestureRecognizer.Direction.left {
                // do not allow right swiping if the habit's frequency is met
                if habitData!.count >= habitData!.habit!.frequency {
                    return
                }
                UIView.animate(withDuration: 0.75, animations: { [self] in
                    self.center.x -= self.bounds.width
                }, completion: { (value: Bool) in
                    self.center = self.originalCenter
                    // increment habit data count by 1
                    self.databaseController?.updateHabitCount(habitData: self.habitData!, incrementVal: 1)
                    self.tableView?.reloadData()
                })
            }
        }
    }
}
