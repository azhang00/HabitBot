//
//  HabitsOverviewViewController.swift
//  HabitBot
//
//  Created by Anna Zhang on 22/4/21.
//

import UIKit

class HabitsOverviewViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var habitsTableView: UITableView!
    
    let CELL_HABIT = "habitCell"
    
    var allHabits: [Habit] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        testHabits()
        
        // set tableview delegate and datasource to this object
        self.habitsTableView.delegate = self
        self.habitsTableView.dataSource = self
    }
    
    // MARK: - TableView functions
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allHabits.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let habitCell = tableView.dequeueReusableCell(withIdentifier: CELL_HABIT, for: indexPath) as! HabitTableViewCell
        if allHabits.isEmpty {
            habitCell.habitTitle.text = "No habits set. Click + to add a habit."
        } else {
            habitCell.habitTitle.text = allHabits[indexPath.row].title
            habitCell.habitCount.text = allHabits[indexPath.row].count
            habitCell.habitBackgroundView.backgroundColor = allHabits[indexPath.row].colour
        }
        return habitCell
    }
    
    func testHabits() {
        let habit1 = Habit(title: "Drink Water", count: "6/8 Cups", colour: UIColor(named: "LightBlueColour") ?? UIColor.label)
        let habit2 = Habit(title: "Walking", count: "5K/10K Steps", colour: UIColor(named: "LightGreenColour") ?? UIColor.label)
        let habit3 = Habit(title: "Meditate", count: "1/2 Times", colour: UIColor(named: "RedColour") ?? UIColor.label)
        
        allHabits.append(habit1)
        allHabits.append(habit2)
        allHabits.append(habit3)
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddHabitSegue" {
            let addOrEditMealController = segue.destination as! AddOrEditHabitViewController
            addOrEditMealController.title = "Add New Habit"
        } else if segue.identifier == "EditHabitSegue" {
            let addOrEditMealController = segue.destination as! AddOrEditHabitViewController
            
            if let habitCell = sender as? HabitTableViewCell, let indexPath = habitsTableView.indexPath(for: habitCell) {
                addOrEditMealController.title = allHabits[indexPath.row].title
            }
        }
    }

}
