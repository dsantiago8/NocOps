//
//  StatsView.swift
//  NocOps
//
//  Created by Diego Santiago on 10/31/24.
//
import SwiftUI
import HealthKit
import Charts

struct StatsView: View {
    @EnvironmentObject var themeManager: ThemeManager  // Access the shared ThemeManager
    @State private var lastNightSleep: Double = 0.0  // Last night's sleep duration
    @State private var weeklyAverage: Double = 0.0   // Weekly average sleep duration
    @State private var monthlyAverage: Double = 0.0  // Monthly average sleep duration
    @State private var sleepData: [String: Double] = [:]  // Dictionary to store sleep data per date
    @State private var manualSleepData: [String: Double] = [:]  // Manually entered sleep data per date
    @ObservedObject var healthStore: HealthStore  // Observe changes in HealthStore

    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: themeManager.gradientColors),
                           startPoint: .bottom,
                           endPoint: .top)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView{
                VStack(spacing: 30) {
                    // Display last night's sleep
                    Text("Last Night: \(String(format: "%.1f", lastNightSleep)) hours")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    // Display weekly average sleep
                    Text("Weekly Average: \(String(format: "%.1f", weeklyAverage)) hours")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    // Display monthly average sleep
                    Text("Monthly Average: \(String(format: "%.1f", monthlyAverage)) hours")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    // Swipable Line Graph Views
                    TabView {
                        // Weekly Sleep Line Graph
                        VStack {
                            Text("Weekly Sleep Duration")
                                .font(.headline)
                                .foregroundColor(.white)

                            Chart(getWeeklyData(), id: \.0) { entry in
                                LineMark(
                                    x: .value("Date", entry.0),
                                    y: .value("Sleep Duration", entry.1)
                                )
                                .foregroundStyle(Color.blue)
                            }
                            .chartXAxis {
                                AxisMarks {
                                    AxisGridLine()
                                        .foregroundStyle(.white.opacity(0.5))
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
                                }
                            }
                            .chartYAxis {
                                AxisMarks {
                                    AxisGridLine()
                                        .foregroundStyle(.white.opacity(0.5))
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding()
                        }
                        .background(
                            Color.black.opacity(0.3)  // Slightly transparent black background
                        )
                        .cornerRadius(10)
                        .shadow(radius: 5)

                        // Monthly Sleep Line Graph
                        VStack {
                            Text("Monthly Sleep Duration")
                                .font(.headline)
                                .foregroundColor(.white)

                            Chart(getMonthlyData(), id: \.0) { entry in
                                LineMark(
                                    x: .value("Date", entry.0),
                                    y: .value("Sleep Duration", entry.1)
                                )
                                .foregroundStyle(Color.orange)
                            }
                            .chartXAxis {
                                AxisMarks {
                                    AxisGridLine()
                                        .foregroundStyle(.white.opacity(0.5))
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
                                }
                            }
                            .chartYAxis {
                                AxisMarks {
                                    AxisGridLine()
                                        .foregroundStyle(.white.opacity(0.5))
                                    AxisValueLabel()
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding()
                        }
                        .background(
                            Color.black.opacity(0.3)  // Slightly transparent black background
                        )
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())

                    
                    Spacer()
                    
                    // Display Last Night's Heart Rate
                    Text("Last Night's Heart Rate - Min: \(String(format: "%.1f", healthStore.lastNightHeartRate.min)) bpm, Max: \(String(format: "%.1f", healthStore.lastNightHeartRate.max)) bpm, Avg: \(String(format: "%.1f", healthStore.lastNightHeartRate.average)) bpm")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    // Display Weekly Average Heart Rate
                    Text("Weekly Heart Rate - Min: \(String(format: "%.1f", healthStore.weeklyHeartRate.min)) bpm, Max: \(String(format: "%.1f", healthStore.weeklyHeartRate.max)) bpm, Avg: \(String(format: "%.1f", healthStore.weeklyHeartRate.average)) bpm")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    // Display Monthly Average Heart Rate
                    Text("Monthly Heart Rate - Min: \(String(format: "%.1f", healthStore.monthlyHeartRate.min)) bpm, Max: \(String(format: "%.1f", healthStore.monthlyHeartRate.max)) bpm, Avg: \(String(format: "%.1f", healthStore.monthlyHeartRate.average)) bpm")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .padding()
            }
            .navigationTitle("Stats")
            .onAppear {
                loadAllSleepData()
                calculateMetrics()
                
                // Check if last night's sleep is below weekly average and send notification
                if lastNightSleep < weeklyAverage {
                    sendSleepDipNotification()
                }
            }
        }
    }
    
    private func sendSleepDipNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Sleep Alert"
        content.body = "Your sleep last night was below your weekly average. Consider getting more rest!"
        content.sound = .default

        // Set a trigger to deliver the notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        // Create the request
        let request = UNNotificationRequest(identifier: "sleepDipNotification", content: content, trigger: trigger)

        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }


    // Helper function to get weekly data formatted for the line chart
    private func getWeeklyData() -> [(String, Double)] {
        let today = Date()
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        return weekDates.map { (formattedDate(date: $0), sleepData[formattedDate(date: $0)] ?? 0.0) }
    }

    // Helper function to get monthly data formatted for the line chart
    private func getMonthlyData() -> [(String, Double)] {
        let today = Date()
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: today)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let monthDates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth) }
        return monthDates.map { (formattedDate(date: $0), sleepData[formattedDate(date: $0)] ?? 0.0) }
    }

    // Load all sleep data from UserDefaults and HealthKit combined
    private func loadAllSleepData() {
        // 1. Load HealthKit sleep data as a baseline
        if let savedHealthKitData = UserDefaults.standard.dictionary(forKey: "sleepData") as? [String: Double] {
            sleepData = savedHealthKitData
        }
        
        // 2. Load manually entered sleep data
        if let savedManualData = UserDefaults.standard.dictionary(forKey: "manualSleepData") as? [String: Double] {
            manualSleepData = savedManualData
        }

        // 3. Merge data, prioritizing manual entries over HealthKit, unless manual entry is 0
        for (date, duration) in manualSleepData {
            if duration != 0 {
                // Use manual data if it’s non-zero
                sleepData[date] = duration
            } else {
                // If manual data is 0, fallback to HealthKit data if available
                if let healthKitDuration = sleepData[date] {
                    sleepData[date] = healthKitDuration
                }
            }
        }
        
        // Debug print to check final combined data
        print("Final combined sleepData:", sleepData)
    }



    // Calculate last night's sleep, weekly, and monthly average including manual data
    private func calculateMetrics() {
        let today = Date()
        let calendar = Calendar.current

        // 1. Calculate last night's sleep
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            let yesterdayKey = formattedDate(date: yesterday)
            lastNightSleep = sleepData[yesterdayKey] ?? 0.0
        }

        // 2. Calculate weekly average sleep (only include dates with data)
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekDates = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
        let weeklyData = weekDates.compactMap { sleepData[formattedDate(date: $0)] }  // Only dates with data
        weeklyAverage = !weeklyData.isEmpty ? weeklyData.reduce(0, +) / Double(weeklyData.count) : 0.0

        // 3. Calculate monthly average sleep (only include dates with data)
        let range = calendar.range(of: .day, in: .month, for: today)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let monthDates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth) }
        let monthlyData = monthDates.compactMap { sleepData[formattedDate(date: $0)] }  // Only dates with data
        monthlyAverage = !monthlyData.isEmpty ? monthlyData.reduce(0, +) / Double(monthlyData.count) : 0.0
    }


    // Helper function to format the date as a string for use as a dictionary key
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"  // Use this format to store dates as strings
        return formatter.string(from: date)
    }
}
