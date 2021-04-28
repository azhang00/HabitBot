//
//  AddOrEditHabitViewController.swift
//  HabitBot
//
//  Created by Anna Zhang on 23/4/21.
//

import UIKit

class AddOrEditHabitViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var habitNameLabel: UILabel!
    @IBOutlet weak var habitName: UITextField!
    @IBOutlet weak var habitType: UISegmentedControl!
    @IBOutlet weak var specialHabitTitle: UILabel!
    @IBOutlet weak var specialHabit: UITextField!
    
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var frequencyCount: UITextField!
    @IBOutlet weak var frequencyDescription: UITextField!
    
    let specialHabitSelection = [
        [
            "habitTitle": "Steps",
            "frequencyLabel": "Step count goal:",
            "frequencyDesc": "Steps"
        ],
        [
            "habitTitle": "Distance Travelled",
            "frequencyLabel": "Distance goal:",
            "frequencyDesc": "km"
        ],
        [
            "habitTitle": "Sleep Duration",
            "frequencyLabel": "Sleep duration goal:",
            "frequencyDesc": "Hours"
        ]
    ]
    let specialHabitFrequencyLabels = ["Step count goal:", "Distance goal:", ""]
    var habitPicker = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set the input for the special habit as a picker view
        habitPicker.delegate = self
        habitPicker.dataSource = self
        specialHabit.inputView = habitPicker
        
        // initially hide the special habit selection
        specialHabit.isHidden = true
        specialHabitTitle.isHidden = true
    }
    
    // MARK: - PickerView methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return specialHabitSelection.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return specialHabitSelection[row]["habitTitle"]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        specialHabit.text = specialHabitSelection[row]["habitTitle"]
        frequencyLabel.text = specialHabitSelection[row]["frequencyLabel"]
        frequencyDescription.text = specialHabitSelection[row]["frequencyDesc"]
        
        // dismiss the pickerview once the user has selected a habit
        specialHabit.resignFirstResponder()
    }
    
    /// This method handles the event of users changing the habit type and will hide the irrelevant UI text labels and fields
    /// - parameter sender: the Segmented Control that was changed
    @IBAction func selectHabitType(_ sender: UISegmentedControl) {
        // hide special habit picker if the user selects "custom" habit
        if sender.selectedSegmentIndex == 0 {
            specialHabit.isHidden = true
            specialHabitTitle.isHidden = true
            habitName.isHidden = false
            habitNameLabel.isHidden = false
        }
        // show special habit picker if user selects "special" habit
        else {
            specialHabit.isHidden = false
            specialHabitTitle.isHidden = false
            habitName.isHidden = true
            habitNameLabel.isHidden = true
        }
    }
    
    /// This method handles the event of users changing the habit type and will hide the irrelevant UI text labels and fields
    /// - parameter sender: the Segmented Control that was changed
    @IBAction func selectFrequency(_ sender: UISegmentedControl) {
        // only change the frequency label if it's for a custom habit
        // since special habits have their own labels
        if habitType.selectedSegmentIndex == 0 {
            if sender.selectedSegmentIndex == 0 {
                frequencyLabel.text = "How often each day?"
            } else if sender.selectedSegmentIndex == 1 {
                frequencyLabel.text = "How often each week?"
            } else {
                frequencyLabel.text = "How often each month?"
            }
        }
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
