//
//  HabitSummaryViewController.swift
//  HabitBot
//
//  Created by Anna Zhang on 19/5/21.
//

import UIKit
import Charts

class HabitSummaryViewController: UIViewController, ChartViewDelegate, DatabaseListener {

    @IBOutlet weak var chartUIView: UIView!
    @IBOutlet weak var habitNameLabel: UILabel!
    @IBOutlet weak var habitDescLabel: UILabel!
    @IBOutlet weak var longestStreakCountLabel: UILabel!
    @IBOutlet weak var currStreakCountLabel: UILabel!
    
    var barChart = BarChartView()
    var habit: Habit?
    
    weak var databaseController: DatabaseProtocol?
    var listenerType = ListenerType.all
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        // set chart delegate
        barChart.delegate = self
        
        habitNameLabel.text = habit!.name
        habitDescLabel.text = "\(habit!.frequencyDuration!.capitaliseFirstLetter()) Goal: \(habit!.frequency) \(habit!.freqDescription ?? "Times")"
        
        calculateStreaks()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    
    // MARK: - BarChart methods
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // set constraints for the bar chart
        barChart.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width - 32, height: self.chartUIView.frame.size.height)
        chartUIView.addSubview(barChart)
        
        // set data for bar chart
        setBarChartData()
        
        // customise grid line settings
        barChart.xAxis.drawGridLinesEnabled = false
        barChart.leftAxis.drawGridLinesEnabled = false
        barChart.rightAxis.drawLabelsEnabled = false
        
        // customise legend settings
        barChart.legend.enabled = false
        
        // customise user interation
        barChart.setScaleEnabled(false)
        
        // set axis
        barChart.setVisibleXRangeMaximum(7.0)
        barChart.leftAxis.axisMinimum = 0.0
        barChart.leftAxis.axisMaximum = Double(habit!.frequency + 1)
        barChart.leftAxis.granularityEnabled = true
        barChart.leftAxis.granularity = 1.0
    }
    
    /// This function sets the data for the bar chart.
    func setBarChartData() {
        let entries = getHabitDataEntries()
        
        let set = BarChartDataSet(entries: entries)
        set.colors = [NSUIColor(named: habit!.colour!)!]
        set.highlightEnabled = false
        
        let data = BarChartData(dataSet: set)
        barChart.data = data
    }
    
    /// This function returns an array of habit data entries for the bar chart. It also sets the x-axis labels.
    /// - returns an array of habit data entries
    func getHabitDataEntries() -> [BarChartDataEntry] {
        var entries = [BarChartDataEntry]()
        
        // sort habit data by date in ascending order
        let allHabitData = Array(habit!.habitData!).sorted(by: {
            $0.date?.date!.compare(($1.date?.date)!) == .orderedAscending
        })
        
        var i = 0
        for habitData in allHabitData {
            if habitData.habit?.frequencyDuration == "weekly" && i % 7 == 0 {
                entries.append(BarChartDataEntry(x: Double(i/7), y: Double(habitData.count)))
            } else if habitData.habit?.frequencyDuration == "daily" {
                entries.append(BarChartDataEntry(x: Double(i), y: Double(habitData.count)))
            }
            
            // date display limit: 7 days from today
            if habitData.date!.date! == Date().dateOnly().addingTimeInterval(60*60*24*7) {
                break
            }
            i += 1
        }
        
        // set custom x-axis labels
        let dateAxisFormatter = DateAxisValueFormatter()
        dateAxisFormatter.setDateStepType(stepType: habit!.frequencyDuration!)
        let initialDate = allHabitData[0].date!.date!
        dateAxisFormatter.setInitialDate(date: initialDate)
        barChart.xAxis.valueFormatter = dateAxisFormatter
        barChart.xAxis.labelPosition = Charts.XAxis.LabelPosition.bottom
        
        // set label count to 2 if the current week is the first week of data for a
        // weekly habit
        if (habit!.frequencyDuration == "weekly" && entries.count == 2) {
            barChart.xAxis.labelCount = 2
        }
        
        return entries
    }
    
    /// This function calculates the longest and current streak and updates the UI text labels.
    func calculateStreaks() {
        var longestStreak = 0
        var currentStreak = 0
        
        // sort habit data by date in ascending order
        let allHabitData = Array(habit!.habitData!).sorted(by: {
            $0.date?.date!.compare(($1.date?.date)!) == .orderedAscending
        })
        
        let goal = habit?.frequency
        var weekDayCount = 0
        
        for habitData in allHabitData {
            if habitData.habit?.frequencyDuration == "weekly" {
                // updating streak counts for weekly habits
                if weekDayCount == 0 {
                    if habitData.count == goal {
                        currentStreak += 1
                        if currentStreak > longestStreak {
                            longestStreak = currentStreak
                        }
                    } else {
                        currentStreak = 0
                    }
                    // reset week day count
                    weekDayCount = 6
                } else {
                    weekDayCount -= 1
                }
                
            } else {
                // updating streak counts for daily habits
                if habitData.count == goal {
                    currentStreak += 1
                    if currentStreak > longestStreak {
                        longestStreak = currentStreak
                    }
                } else {
                    currentStreak = 0
                }
            }
            
            // don't use future dates for streak calculation
            if habitData.date!.date! == Date().dateOnly() {
                break
            }
        }
        
        var streakDescriptor = "day"
        if habit?.frequencyDuration == "weekly" {
            streakDescriptor = "week"
        }
        
        if longestStreak == 1 {
            longestStreakCountLabel.text = "\(longestStreak) \(streakDescriptor)"
        } else {
            longestStreakCountLabel.text = "\(longestStreak) \(streakDescriptor)s"
        }
        
        if currentStreak == 1 {
            currStreakCountLabel.text = "\(currentStreak) \(streakDescriptor)"
        } else {
            currStreakCountLabel.text = "\(currentStreak) \(streakDescriptor)s"
        }
    }
    
    
    // MARK: - DatabaseListener methods
    
    func onHabitDataForADateChange(change: DatabaseChange, habitData: [HabitData]) {
        // update the bar chart data and streaks
        setBarChartData()
        calculateStreaks()
    }
    
    func onHabitDateChange(change: DatabaseChange, habitDate: [HabitDate]) {
        // we don't need to do anything here
    }
    
    func onHabitChange(change: DatabaseChange, habit: [Habit]) {
        // we don't need to do anything here
    }

}
