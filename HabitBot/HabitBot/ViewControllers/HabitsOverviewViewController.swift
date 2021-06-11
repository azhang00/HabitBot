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
    @IBOutlet weak var date: UIDatePicker!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set tableview delegate and datasource to this object
        self.habitsTableView.delegate = self
        self.habitsTableView.dataSource = self
        
        date.date = currentDate
        
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
        
        // sort the habits in alphabetical order
        if habitDataIndex < allHabitDates.count && habitDataIndex > -1 {
            currentHabitData = Array(allHabitDates[habitDataIndex].habits!).sorted {
                return $0.habit!.name! < $1.habit!.name!
            }
        }
        
        // set up datepicker
        setDatePicker()
        setDatePickerDates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    /// This function configures the date picker selection action.
    func setDatePicker() {
        date.addTarget(self, action: #selector(selectDate), for: .valueChanged)
    }
    
    /// This function sets the minimum and maximum dates that can be selected.
    func setDatePickerDates() {
        date.minimumDate = allHabitDates[0].date!
        date.maximumDate = allHabitDates[allHabitDates.count - 1].date!
    }
    
    /// This function handles the action of users selecting a date in the date picker.
    @objc func selectDate() {
        let originalDate = currentDate
        currentDate = date.date.dateOnly()
        
        // calculate how the number of days between the selected date and the original date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: originalDate, to: currentDate)
        let daysDifference = components.day!
        habitDataIndex = habitDataIndex + daysDifference
        
        // get the habit data for the selected day
        currentHabitData = Array(allHabitDates[habitDataIndex].habits!).sorted {
            return $0.habit!.name! < $1.habit!.name!
        }
        self.habitsTableView.reloadData()
        
        date.endEditing(true)
    }
    
    /// This function handles the action of displaying the previous day's habit data. It will display an alert if the current date is the initial date to contain any data.
    /// - parameter sender: button that was clicked on
    @IBAction func goBackOneDay(_ sender: Any) {
        if habitDataIndex == 0 {
            displayErrorMessage(title: "No Data", message: "There is no more data earlier than the current date.")
        } else {
            currentDate.addTimeInterval(-60*60*24)
            habitDataIndex -= 1
            currentHabitData = Array(allHabitDates[habitDataIndex].habits!).sorted {
                return $0.habit!.name! < $1.habit!.name!
            }
            self.habitsTableView.reloadData()
        }
        date.date = currentDate
    }
    
    /// This function handles the action of displaying the next day's habit data.
    /// - parameter sender: button that was clicked on
    @IBAction func goAheadOneDay(_ sender: Any) {
        currentDate.addTimeInterval(60*60*24)
        habitDataIndex += 1
        if habitDataIndex < allHabitDates.count && habitDataIndex > -1 {
            currentHabitData = Array(allHabitDates[habitDataIndex].habits!).sorted {
                return $0.habit!.name! < $1.habit!.name!
            }
            
            date.date = currentDate
            self.habitsTableView.reloadData()
        } else {
            // create more HabitDates in Core Data if no more future dates exist
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
            
            // populate the habit cell with the habit's name and count
            habitCell.habitTitle.text = currentHabitData[indexPath.row].habit!.name
            if currentHabitData[indexPath.row].count >= currentHabitData[indexPath.row].habit!.frequency {
                habitCell.habitCount.text = "Done"
                habitCell.habitCheckMark.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
    
                habitCell.habitTitle.textColor = UIColor.white
                habitCell.habitCount.textColor = UIColor.white
                
                // set the cell border and checkmark colour
                habitCell.habitBackgroundView.layer.borderWidth = 0
                habitCell.habitBackgroundView.backgroundColor = UIColor(named: currentHabitData[indexPath.row].habit!.colour!)
                habitCell.habitCheckMark.tintColor = UIColor.white
            } else {
                habitCell.habitCount.text = "\(currentHabitData[indexPath.row].count) / \(currentHabitData[indexPath.row].habit!.frequency) \(currentHabitData[indexPath.row].habit!.freqDescription!)"
                habitCell.habitCheckMark.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
                
                habitCell.habitTitle.textColor = UIColor.label
                habitCell.habitCount.textColor = UIColor.secondaryLabel
                
                // set the cell border and checkmark colour
                habitCell.habitBackgroundView.layer.borderWidth = 2
                habitCell.habitBackgroundView.layer.borderColor = UIColor(named: currentHabitData[indexPath.row].habit!.colour!)?.cgColor
                habitCell.habitBackgroundView.backgroundColor = .clear
                habitCell.habitCheckMark.tintColor = UIColor(named: currentHabitData[indexPath.row].habit!.colour!)
            }
            
            habitCell.habitData = currentHabitData[indexPath.row]
            habitCell.tableView = tableView
            return habitCell
        }
        
        // info cell either contains instructions for adding a new habit or updating a habit
        let infoCell = tableView.dequeueReusableCell(withIdentifier: CELL_INFO, for: indexPath)
        if currentHabitData.count > 0 {
            infoCell.textLabel?.text = "Hint: Swipe left / right to increment / decrement habit count, and tap on a habit to edit the habit."
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
        // check that the index is still valid
        if habitDataIndex < allHabitDates.count && habitDataIndex > -1 {
            // sort the habits by name in alphabetical order
            currentHabitData = Array(allHabitDates[habitDataIndex].habits!).sorted {
                return $0.habit!.name! < $1.habit!.name!
            }
        } else {
            currentHabitData = []
            habitDataIndex = 0
        }
        setDatePickerDates()
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
