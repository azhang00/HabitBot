//
//  AddOrEditHabitViewController.swift
//  HabitBot
//
//  Created by Anna Zhang on 23/4/21.
//

import UIKit
import TextFieldEffects

class AddOrEditHabitViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    weak var databaseController: DatabaseProtocol?
    
    var existingHabit: Habit?
    var editedHabit: Habit?
    
    let CELL_COLOUR = "colourCell"
    var selectedColourIndex = 0

    @IBOutlet weak var habitNameLabel: UILabel!
    @IBOutlet weak var habitName: IsaoTextField!
    @IBOutlet weak var habitType: UISegmentedControl!
    @IBOutlet weak var specialHabitTitle: UILabel!
    @IBOutlet weak var specialHabit: IsaoTextField!
    
    @IBOutlet weak var frequencyDuration: UISegmentedControl!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var frequencyCount: IsaoTextField!
    @IBOutlet weak var frequencyDescription: IsaoTextField!
    
    @IBOutlet weak var colourCollectionView: UICollectionView!
    
    @IBOutlet weak var reminderView: UIView!
    @IBOutlet weak var reminderDescription: IsaoTextField!
    @IBOutlet weak var completedTaskMessage: IsaoTextField!
    @IBOutlet weak var incompleteTaskMessage: IsaoTextField!
    @IBOutlet weak var notificationCount: IsaoTextField!
    @IBOutlet weak var notificationFrequency: IsaoTextField!
    @IBOutlet weak var notificationStartTime: IsaoTextField!
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
    var timePicker = UIDatePicker()
    
    let colours = ["RedColour", "OrangeColour", "YellowColour", "LightGreenColour", "DarkGreenColour", "LightBlueColour", "DarkBlueColour", "PurpleColour", "PinkColour"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    
        self.colourCollectionView.delegate = self
        self.colourCollectionView.dataSource = self
        
        // we want to get the Habit in the child context so that any changes the user makes
        // does not get saved to persistent storage before they click the Save button
        if existingHabit != nil {
            editedHabit = databaseController?.getChildContextHabit(habit: existingHabit!)
        }
        
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
                reminderDescription.text = existingHabit?.reminder?.msgDescription
                completedTaskMessage.text = existingHabit?.reminder?.completeMsg
                incompleteTaskMessage.text = existingHabit?.reminder?.incompleteMsg
                notificationFrequency.text = "\(existingHabit?.reminder?.frequency ?? 0)"
                notificationCount.text = "\(existingHabit?.reminder?.count ?? 0)"
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                notificationStartTime.text = formatter.string(from: (existingHabit?.reminder?.startTime)!)
            } else {
                reminderView.isHidden = true
                reminderSwitch.isOn = false
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
        
        setTimePicker()
    }
    
    /// This function sets the time picker for the notification start time field.
    func setTimePicker() {
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        
        // create a toolbar that allows the user to choose the time they have selected or dismiss the picker
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        let selectButton = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectTime))
        let spaceArea = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelTimePicker))

        toolbar.setItems([cancelButton, spaceArea, selectButton], animated: false)

        notificationStartTime.inputAccessoryView = toolbar
        notificationStartTime.inputView = timePicker
    }
    
    /// This function handles the action of users clicking on the 'Select' button when choosing a time from the time picker.
    @objc func selectTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        notificationStartTime.text = formatter.string(from: timePicker.date)
        self.view.endEditing(true)
    }
    
    /// This function handles the action of users clicking on the 'Cancel' button on the time picker.
    @objc func cancelTimePicker() {
        self.view.endEditing(true)
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
    
    /// This function will update the visibility of the reminder section based on the reminder switch state.
    /// - parameter sender: `UISwitch` that was toggled
    @IBAction func toggleReminder(_ sender: UISwitch) {
        if sender.isOn {
            reminderView.isHidden = false
            
            // there's a bug with IsaoTextField where the underline and placeholder
            // text doesn't appear so I've redrawn the display
            reminderDescription.setNeedsDisplay()
            completedTaskMessage.setNeedsDisplay()
            incompleteTaskMessage.setNeedsDisplay()
            notificationCount.setNeedsDisplay()
            notificationFrequency.setNeedsDisplay()
            notificationStartTime.setNeedsDisplay()
        } else {
            reminderView.isHidden = true
        }
    }
    
    /// This function saves the habit with the data entered by the user. It will display an error message if any required fields are empty.
    /// - parameter sender: button that was clicked on
    @IBAction func saveHabit(_ sender: Any) {
        var missingData = false
        var errorMsg = "Please populate the following fields:"
        
        var editedHabitName: String?
        var editedHabitType: String?
        var editedHabitFreqDuration: String?
        var editedHabitFrequency: Int64?
        var editedHabitFreqDescription: String?
        var reminderFrequency, reminderCount: Int64?
        var notifStartTime: Date?
        
        // check whether data fields are missing information
        if habitType.selectedSegmentIndex == 0 {
            if let name = habitName.text, !name.isEmpty {
                editedHabitName = name
                editedHabitType = "custom"
            } else {
                errorMsg += "\n- Habit name"
                missingData = true
            }
        } else {
            if let name = specialHabit.text, !name.isEmpty {
                editedHabitName = name
                editedHabitType = "special"
            } else {
                errorMsg += "\n- Habit name"
                missingData = true
            }
        }
        
        // get frequency duration
        if frequencyDuration.selectedSegmentIndex == 0 {
            editedHabitFreqDuration = "daily"
        } else {
            editedHabitFreqDuration = "weekly"
        }
        
        // check frequency data
        if let frequency = frequencyCount.text, let count = Int(frequency) {
            editedHabitFrequency = Int64(count)
        } else {
            errorMsg += "\n- Frequency count"
            missingData = true
        }
        if let freqDescription = frequencyDescription.text, !freqDescription.isEmpty {
            editedHabitFreqDescription = freqDescription
        } else {
            errorMsg += "\n- Frequency description"
            missingData = true
        }
        
        // get colour
        let editedHabitColour = colours[selectedColourIndex]
        
        // check reminder info if reminders is toggled on
        if !reminderView.isHidden {
            // check that reminder fields are filled
            if let reminderDesc = reminderDescription.text, reminderDesc.isEmpty {
                errorMsg += "\n- Reminder description"
                missingData = true
            }
            
            if let completeMessage = completedTaskMessage.text, completeMessage.isEmpty {
                errorMsg += "\n- Reminder completion message"
                missingData = true
            }
            
            if let incompleteMessage = incompleteTaskMessage.text, incompleteMessage.isEmpty {
                errorMsg += "\n- Reminder incomplete message"
                missingData = true
            }
            
            if let reminderFreqText = notificationFrequency.text, let _ = Int64(reminderFreqText) {
                reminderFrequency = Int64(reminderFreqText)
            } else {
                errorMsg += "\n- Reminder notification frequency"
                missingData = true
            }
            
            if let reminderCountText = notificationCount.text, let _ = Int64(reminderCountText) {
                reminderCount = Int64(reminderCountText)
            } else {
                errorMsg += "\n- Reminder notification count"
                missingData = true
            }
            
            if let startTimeText = notificationStartTime.text, startTimeText.isEmpty {
                errorMsg += "\n- Reminder start time"
                missingData = true
            } else {
                // get the start time for the reminder notification
                let calendar = Calendar.current
                var components = calendar.dateComponents([.hour, .minute], from: Date().dateOnly())
                components.hour = Int(String(notificationStartTime.text!.prefix(2)))
                components.minute = Int(String(notificationStartTime.text!.suffix(2)))
                
                notifStartTime = calendar.date(from: components)
            }
        } else {
            // delete the reminder if reminders is toggled off for existing habits
            if existingHabit != nil {
                databaseController?.deleteReminder(habit: existingHabit!)
            }
        }
        
        // show alert if there are fields missing data
        if missingData {
            displayErrorMessage(title: "Missing Data", message: errorMsg)
        } else {
            // save existing habit
            if editedHabit != nil {
                editedHabit!.name = editedHabitName
                editedHabit!.type = editedHabitType
                editedHabit!.frequencyDuration = editedHabitFreqDuration
                editedHabit!.frequency = editedHabitFrequency!
                editedHabit!.freqDescription = editedHabitFreqDescription
                editedHabit!.colour = editedHabitColour
                
                if !reminderView.isHidden {
                    databaseController?.setReminder(habit: editedHabit!, startTime: notifStartTime!, msgDescription: reminderDescription.text!, completeMsg: completedTaskMessage.text!, incompleteMsg: incompleteTaskMessage.text!, frequency: reminderFrequency!, count: reminderCount!)
                }
                databaseController?.saveHabitEdit(habit: editedHabit!)
            } else {
                // create new habit
                let newHabit = databaseController?.createHabit(name: editedHabitName!, type: editedHabitType!, frequencyDuration: editedHabitFreqDuration!, frequency: editedHabitFrequency!, freqDescription: editedHabitFreqDescription!, colour: editedHabitColour)
                
                if !reminderView.isHidden {
                    databaseController?.setReminder(habit: newHabit!, startTime: notifStartTime!, msgDescription: reminderDescription.text!, completeMsg: completedTaskMessage.text!, incompleteMsg: incompleteTaskMessage.text!, frequency: reminderFrequency!, count: reminderCount!)
                }
            }
            // return back to the previous view
            navigationController?.popViewController(animated: true)
        }
    }
    
    /// This function will display an alert when users attempt to delete a habit and will delete the
    /// habit if users select 'Delete'.
    /// - parameter sender: button that was clicked on
    @IBAction func deleteHabit(_ sender: Any) {
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

}
