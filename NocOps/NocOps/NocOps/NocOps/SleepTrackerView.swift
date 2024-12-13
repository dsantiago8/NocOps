import SwiftUI

struct SleepTrackerView: View {
    @EnvironmentObject var themeManager: ThemeManager  // Access the shared ThemeManager
    @ObservedObject var healthStore = HealthStore()  // Reference to HealthStore
    @State private var selectedDate = Date()
    @State private var sleepDuration: Double = 8.0  // Stores the sleep duration for the selected date
    @State private var useHealthKitData = true      // Toggle to choose between HealthKit and manual input
    @State private var manualSleepData: [String: Double] = [:]  // Dictionary to store manually entered sleep data per date

    var body: some View {
        ZStack{
            LinearGradient(gradient: Gradient(colors: themeManager.gradientColors),
                           startPoint: .bottom,
                           endPoint: .top)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Calendar Date Picker
                DatePicker("Select a day", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .accentColor(.yellow)
                    .onChange(of: selectedDate) { _ in
                        updateSleepDuration(for: selectedDate)
                    }
                
                // Toggle between HealthKit data and manual entry
                Toggle(isOn: $useHealthKitData) {
                    Text("Use Health App Data")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .onChange(of: useHealthKitData) { _ in
                    updateSleepDuration(for: selectedDate)
                }
                
                // Show sleep duration either from HealthKit or manual input
                if useHealthKitData {
                    Text("Sleep Duration: \(sleepDuration, specifier: "%.1f") hours")
                        .font(.title2)
                        .foregroundColor(.white)
                } else {
                    // Manual Sleep duration picker (using a Stepper)
                    VStack {
                        Text("Manually Entered Sleep Duration:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Stepper(value: $sleepDuration, in: 0...24, step: 0.5) {
                            Text("\(sleepDuration, specifier: "%.1f") hours")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .onChange(of: sleepDuration) { _ in
                            saveManualSleepData(for: selectedDate, duration: sleepDuration)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Sleep Tracker")
            .onAppear {
                loadManualSleepData()
                healthStore.requestAuthorization { success in
                    if success {
                        healthStore.getSleepData { _ in
                            updateSleepDuration(for: selectedDate)
                        }
                    }
                }
            }
        }
    }

    // Update the sleep duration for the selected date based on manual input or HealthKit data
    private func updateSleepDuration(for date: Date) {
        let dateKey = formattedDate(date: date)
        if useHealthKitData {
            // Use HealthKit data if available, defaulting to zero if no data is found
            sleepDuration = healthStore.sleepData[dateKey] ?? 0.0
        } else {
            // Use manually entered data if available, defaulting to zero if no data is found
            sleepDuration = manualSleepData[dateKey] ?? 0.0
        }
    }

    // Save manually entered sleep data to UserDefaults
    private func saveManualSleepData(for date: Date, duration: Double) {
        let dateKey = formattedDate(date: date)
        manualSleepData[dateKey] = duration
        UserDefaults.standard.set(manualSleepData, forKey: "manualSleepData")
    }

    // Load manually entered sleep data from UserDefaults
    private func loadManualSleepData() {
        if let savedData = UserDefaults.standard.dictionary(forKey: "manualSleepData") as? [String: Double] {
            manualSleepData = savedData
        }
    }

    // Helper function to format the date as a string for use as a dictionary key
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"  // Use this format to store dates as strings
        return formatter.string(from: date)
    }
}
