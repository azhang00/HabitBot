//
//  SummaryTableViewController.swift
//  HabitBot
//
//  Created by Anna Zhang on 19/5/21.
//

import UIKit

class SummaryTableViewController: UITableViewController, DatabaseListener {
    
    weak var databaseController: DatabaseProtocol?
    var listenerType = ListenerType.habit
    
    let SECTION_SUMMARY = 0
    let SECTION_INFO = 1
    let CELL_SUMMARY = "summaryCell"
    let CELL_INFO = "infoCell"
    
    var allHabits: [Habit] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case SECTION_SUMMARY:
                return allHabits.count
            case SECTION_INFO:
                return 1
            default:
                return 0
       }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == SECTION_SUMMARY {
            let summaryCell = tableView.dequeueReusableCell(withIdentifier: CELL_SUMMARY, for: indexPath) as! SummaryTableViewCell
            
            // populate the cell with the habit name and set the background colour
            summaryCell.habitTitle.text = allHabits[indexPath.row].name
            summaryCell.habitBackgroundView.backgroundColor = UIColor(named: allHabits[indexPath.row].colour!)

            return summaryCell
        }
        
        let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
        if allHabits.count > 0 {
            infoCell.textLabel?.text = "Select a habit to view its summary data."
        } else {
            infoCell.textLabel?.text = "No habits set. Return to the Habits page and click + to add a habit."
        }
        return infoCell
    }
    
    // MARK: - DatabaseListener methods
    
    func onHabitDataForADateChange(change: DatabaseChange, habitData: [HabitData]) {
        // we don't need to do anything here
    }
    
    func onHabitDateChange(change: DatabaseChange, habitDate: [HabitDate]) {
        // we don't need to do anything here
    }
    
    func onHabitChange(change: DatabaseChange, habit: [Habit]) {
        allHabits = habit
        self.tableView.reloadData()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewHabitSummarySegue" {
            let habitSummaryViewController = segue.destination as! HabitSummaryViewController
            if let summaryCell = sender as? SummaryTableViewCell, let indexPath = self.tableView.indexPath(for: summaryCell) {
                habitSummaryViewController.habit = allHabits[indexPath.row]
                habitSummaryViewController.title = allHabits[indexPath.row].name
            }
        }
    }

}
