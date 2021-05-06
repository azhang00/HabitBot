//
//  HabitsOverviewViewController.swift
//  HabitBot
//
//  Created by Anna Zhang on 22/4/21.
//

import UIKit
import Foundation

class HabitsOverviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DatabaseListener {

    @IBOutlet weak var habitsTableView: UITableView!
    @IBOutlet weak var date: UILabel!
    
    let SECTION_HABIT = 0
    let SECTION_INFO = 1
    let CELL_HABIT = "habitCell"
    let CELL_INFO = "infoCell"
    
    var listenerType = ListenerType.all
    weak var databaseController: DatabaseProtocol?
    
    var currentDate = Date().dateOnly()
    var habitDataIndex = 0
    var currentHabitData: [HabitData] = []
    var allHabitDates: [HabitDate] = []
    let formatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set tableview delegate and datasource to this object
        self.habitsTableView.delegate = self
        self.habitsTableView.dataSource = self
        
        formatter.dateFormat = "dd MMM yyyy"
        date.text = formatter.string(from: currentDate)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        
        // get the index of the HabitData object for the current date
        var index = 0
        for date in allHabitDates {
            if date.date! == currentDate {
                habitDataIndex = index
                break
            }
            index += 1
        }
        
        if habitDataIndex < allHabitDates.count && habitDataIndex > -1 {
            currentHabitData = Array(allHabitDates[habitDataIndex].habits!).sorted {
                return $0.habit!.name! < $1.habit!.name!
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    @IBAction func goBackOneDay(_ sender: Any) {
        if habitDataIndex == 0 {
            displayErrorMessage(title: "No Data", message: "There is no more data earlier than the current date.")
        } else {
            currentDate.addTimeInterval(-60*60*24)
            habitDataIndex -= 1
            currentHabitData = Array(allHabitDates[habitDataIndex].habits!).sorted {
                return $0.habit!.name! < $1.habit!.name!
            }
            date.text = formatter.string(from: currentDate)
            self.habitsTableView.reloadData()
        }
    }
    
    @IBAction func goAheadOneDay(_ sender: Any) {
        currentDate.addTimeInterval(60*60*24)
        habitDataIndex += 1
        if habitDataIndex < allHabitDates.count && habitDataIndex > -1 {
            currentHabitData = Array(allHabitDates[habitDataIndex].habits!).sorted {
                return $0.habit!.name! < $1.habit!.name!
            }
            date.text = formatter.string(from: currentDate)
            self.habitsTableView.reloadData()
        } else {
            // create more HabitDates in Core Data
            databaseController?.createOneMonthOfHabitDates(startDate: currentDate)
        }
    }
    
    // MARK: - TableView functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case SECTION_HABIT:
                return currentHabitData.count
            case SECTION_INFO:
                return 1
            default:
                return 0
       }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == SECTION_HABIT {
            let habitCell = tableView.dequeueReusableCell(withIdentifier: CELL_HABIT, for: indexPath) as! HabitTableViewCell
            habitCell.habitTitle.text = currentHabitData[indexPath.row].habit!.name
            if currentHabitData[indexPath.row].count >= currentHabitData[indexPath.row].habit!.frequency {
                habitCell.habitCount.text = "Done"
            } else {
                habitCell.habitCount.text = "\(currentHabitData[indexPath.row].count) / \(currentHabitData[indexPath.row].habit!.frequency) \(currentHabitData[indexPath.row].habit!.freqDescription!)"
            }
            habitCell.habitBackgroundView.backgroundColor = UIColor(named: currentHabitData[indexPath.row].habit!.colour!)
            habitCell.habitData = currentHabitData[indexPath.row]
            habitCell.tableView = tableView
            return habitCell
        }
        
        let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
        if currentHabitData.count > 0 {
            infoCell.textLabel?.text = "Instructions: Swipe left / right to increment / decrement habit count, and tap on a habit to edit the habit."
        } else {
            infoCell.textLabel?.text = "No habits set. Click + to add a habit."
        }
        return infoCell
    }
    
    // MARK: - Database Listener
    
    func onHabitDataForADateChange(change: DatabaseChange, habitData: [HabitData]) {
        self.habitsTableView.reloadData()
    }
    
    func onHabitDateChange(change: DatabaseChange, habitDate: [HabitDate]) {
        allHabitDates = habitDate
        if habitDataIndex < allHabitDates.count && habitDataIndex > -1 {
            currentHabitData = Array(allHabitDates[habitDataIndex].habits!).sorted {
                return $0.habit!.name! < $1.habit!.name!
            }
        } else {
            currentHabitData = []
            habitDataIndex = 0
        }
        self.habitsTableView.reloadData()
    }
    
    func onHabitChange(change: DatabaseChange, habit: [Habit]) {
        self.habitsTableView.reloadData()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddHabitSegue" {
            let addOrEditMealController = segue.destination as! AddOrEditHabitViewController
            addOrEditMealController.title = "Add New Habit"
        } else if segue.identifier == "EditHabitSegue" {
            let addOrEditMealController = segue.destination as! AddOrEditHabitViewController
            
            if let habitCell = sender as? HabitTableViewCell, let indexPath = habitsTableView.indexPath(for: habitCell) {
                addOrEditMealController.title = currentHabitData[indexPath.row].habit!.name
                addOrEditMealController.existingHabit = currentHabitData[indexPath.row].habit!
            }
        }
    }

}
