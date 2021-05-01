//
//  AddOrEditHabitViewController.swift
//  HabitBot
//
//  Created by Anna Zhang on 23/4/21.
//

import UIKit

class AddOrEditHabitViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    weak var databaseController: DatabaseProtocol?
    
    var existingHabit: Habit?
    var editedHabit: Habit?
    
    let CELL_COLOUR = "colourCell"
    var selectedColourIndex = 0

    @IBOutlet weak var habitNameLabel: UILabel!
    @IBOutlet weak var habitName: UITextField!
    @IBOutlet weak var habitType: UISegmentedControl!
    @IBOutlet weak var specialHabitTitle: UILabel!
    @IBOutlet weak var specialHabit: UITextField!
    
    @IBOutlet weak var frequencyDuration: UISegmentedControl!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var frequencyCount: UITextField!
    @IBOutlet weak var frequencyDescription: UITextField!
    
    @IBOutlet weak var colourCollectionView: UICollectionView!
    
    @IBOutlet weak var reminderView: UIView!
    @IBOutlet weak var reminderDescription: UITextField!
    @IBOutlet weak var completedTaskMessage: UITextField!
    @IBOutlet weak var incompleteTaskMessage: UITextField!
    @IBOutlet weak var notificationCount: UITextField!
    @IBOutlet weak var notificationFrequency: UITextField!
    @IBOutlet weak var deleteHabitButton: UIButton!
    @IBOutlet weak var reminderSwitch: UISwitch!
    
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
    var habitPicker = UIPickerView()
    
    let colours = ["RedColour", "OrangeColour", "YellowColour", "SandColour", "LightGreenColour", "DarkGreenColour", "LightBlueColour", "DarkBlueColour", "PurpleColour", "PinkColour"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    
        self.colourCollectionView.delegate = self
        self.colourCollectionView.dataSource = self
        
        // we want to get the Habit in the child context so that any changes the user makes
        // does not get saved to persistent storage before they click the Save button
        editedHabit = databaseController?.getChildContextHabit(habit: existingHabit)
        
        // populate the view with the existing habit's data
        if existingHabit != nil {
            if existingHabit?.type == "custom" {
                // hide the special habit selection
                habitName.isHidden = false
                habitNameLabel.isHidden = false
                specialHabit.isHidden = true
                specialHabitTitle.isHidden = true
                habitType.selectedSegmentIndex = 0
                habitName.text = existingHabit?.name
            } else {
                // hide the custom habit selection
                habitName.isHidden = true
                habitNameLabel.isHidden = true
                specialHabit.isHidden = false
                specialHabitTitle.isHidden = false
                habitType.selectedSegmentIndex = 1
                specialHabit.text = existingHabit?.name
            }
            if existingHabit?.frequencyDuration == "daily" {
                frequencyDuration.selectedSegmentIndex = 0
            } else {
                frequencyDuration.selectedSegmentIndex = 1
            }
            if existingHabit?.reminder != nil {
                reminderView.isHidden = false
                reminderSwitch.isOn = true
            }
            selectedColourIndex = colours.firstIndex(of: (existingHabit?.colour)!)!
            frequencyCount.text = "\(existingHabit?.frequency ?? 1)"
            frequencyDescription.text = existingHabit?.freqDescription
        } else {
            // initially hide the special habit selection
            specialHabit.isHidden = true
            specialHabitTitle.isHidden = true
            reminderView.isHidden = true
            reminderSwitch.isOn = false
            deleteHabitButton.isHidden = true
        }
        // set the input for the special habit as a picker view
        habitPicker.delegate = self
        habitPicker.dataSource = self
        specialHabit.inputView = habitPicker
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
    
    // MARK: - CollectionView methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colours.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_COLOUR, for: indexPath)
        cell.backgroundColor = UIColor(named: colours[indexPath.row])
        
        // add border if the colour cell is selected
        if selectedColourIndex == indexPath.row {
            cell.layer.borderColor = UIColor.systemGray.cgColor
            cell.layer.borderWidth = 3
        } else {
            cell.layer.borderWidth = 0
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedColourIndex = indexPath.row
        self.colourCollectionView.reloadData()
    }
    
    // MARK: - Methods to handle user actions
    
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
        // only change the frequency label if it's for a custom habit since special habits have their own labels
        if habitType.selectedSegmentIndex == 0 {
            if sender.selectedSegmentIndex == 0 {
                frequencyLabel.text = "How often each day?"
            } else {
                frequencyLabel.text = "How often each week?"
            }
        }
    }
    
    @IBAction func toggleReminder(_ sender: UISwitch) {
        if sender.isOn {
            reminderView.isHidden = false
        } else {
            reminderView.isHidden = true
        }
    }
    
    @IBAction func saveHabit(_ sender: Any) {
        /*
         @IBOutlet weak var frequencyDuration: UISegmentedControl!
         @IBOutlet weak var frequencyLabel: UILabel!
         @IBOutlet weak var frequencyCount: UITextField!
         @IBOutlet weak var frequencyDescription: UITextField!
         
         @IBOutlet weak var reminderDescription: UITextField!
         @IBOutlet weak var completedTaskMessage: UITextField!
         @IBOutlet weak var incompleteTaskMessage: UITextField!
         @IBOutlet weak var notificationCount: UITextField!
         @IBOutlet weak var notificationFrequency: UITextField!
         @IBOutlet weak var deleteHabitButton: UIButton!
         */
        var missingData = false
        var errorMsg = "Please populate the following fields:"
        
        // check whether data fields are missing
        if habitType.selectedSegmentIndex == 0 {
            if let name = habitName.text, !name.isEmpty {
                editedHabit!.name = name
                editedHabit!.type = "custom"
            } else {
                errorMsg += "\n- Habit name"
                missingData = true
            }
        } else {
            if let name = specialHabit.text, !name.isEmpty {
                editedHabit!.name = name
                editedHabit!.type = "special"
            } else {
                errorMsg += "\n- Habit name"
                missingData = true
            }
        }
        
        // set frequency duration
        if frequencyDuration.selectedSegmentIndex == 0 {
            editedHabit!.frequencyDuration = "daily"
        } else {
            editedHabit!.frequencyDuration = "weekly"
        }
        
        // check frequency data
        if let frequency = frequencyCount.text, let count = Int(frequency) {
            editedHabit!.frequency = Int64(count)
        } else {
            errorMsg += "\n- Frequency count"
            missingData = true
        }
        if let freqDescription = frequencyDescription.text, !freqDescription.isEmpty {
            editedHabit!.freqDescription = freqDescription
        } else {
            errorMsg += "\n- Frequency description"
            missingData = true
        }
        
        // set colour
        editedHabit?.colour = colours[selectedColourIndex]
        
        if missingData {
            displayErrorMessage(title: "Missing Data", message: errorMsg)
        } else {
            // save the habit and return back to the previous view
            if existingHabit == nil {
                let _ = databaseController?.createHabit(name: editedHabit!.name!, type: editedHabit!.type!, frequencyDuration: editedHabit!.frequencyDuration!, frequency: editedHabit!.frequency, freqDescription: editedHabit!.freqDescription!, colour: editedHabit!.colour!)
            }
            databaseController?.saveHabitEdit(habit: editedHabit!)
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func deleteHabit(_ sender: Any) {
        displayDeleteHabitAlert()
    }
    
    /// This function will display an alert when users attempt to delete a habit.
    func displayDeleteHabitAlert() {
        let alertController = UIAlertController(title: "Delete Habit", message: "Are you sure you wish to delete the habit \(existingHabit!.name!)?", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Delete", style: .default, handler: { alert in
            // delete the habit
            self.databaseController?.deleteHabit(habit: self.existingHabit!)
            // return to the previous view controller
            self.navigationController?.popViewController(animated: true)
        }))
        
        self.present(alertController, animated: true, completion: nil)
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
