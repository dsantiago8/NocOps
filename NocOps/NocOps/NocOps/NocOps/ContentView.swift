//
//  ContentView.swift
//  NocOps
//
//  Created by Diego Santiago on 9/18/24.
//

import HealthKit
import SwiftUI
import Combine
import Charts
import UserNotifications
import Sahha

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager  // Access the shared ThemeManager
    @State private var showMenu = false
    @StateObject private var healthStore = HealthStore()  // Initialize HealthStore here
    @State private var isTrackingSleep = false
    @State private var sleepStartTime: Date? = nil
    
    @State private var sleepDuration: Double = 0.0
    
    @State private var sleepGoal: Double = UserDefaults.standard.double(forKey: "sleepGoal") // Retrieve the sleep goal
    
    @State private var formattedSleepDuration: String = "00:00:00"  // For displaying duration in HH:MM:SS format
    @State private var timerSubscription: AnyCancellable?  // Subscription to the timer
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    @State private var authenticationMessage: String = ""
    @State private var dragOffset = CGSize.zero // For handling the drag gesture
    @State private var sleepQualityScore: Double = 0.0  // Declare the sleep quality score


    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: themeManager.gradientColors),
                               startPoint: .bottom,
                               endPoint: .top)
                    .edgesIgnoringSafeArea(.all)
                
                // Main content
                VStack(spacing: 30) {
                    Button(action: authenticateUser) {
                        Text("Authenticate with Sahha")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Text(authenticationMessage)
                        .font(.headline)
                        .foregroundColor(.purple)
                        .padding()

                    
                    // Display the formatted sleep duration
                    Text("Sleep Duration: \(formattedSleepDuration)")
                        .font(.title2)
                        .foregroundColor(.white)

                    // Start/Stop Sleep Timer Button
                    Button(action: {
                        if isTrackingSleep {
                            stopSleepTimer()
                        } else {
                            startSleepTimer()
                        }
                    }) {
                        Text(isTrackingSleep ? "Stop Sleep Timer" : "Start Sleep Timer")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isTrackingSleep ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                    
                    // Display the sleep quality score
                    Text("Sleep Quality Score: \(sleepQualityScore, specifier: "%.1f")")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                }
                .navigationTitle("NocOps")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showMenu.toggle()
                            }
                        }) {
                            Image(systemName: "line.horizontal.3")
                                .imageScale(.large)
                                .foregroundColor(.white)
                        }
                    }
                }

                // Side menu overlay
                SideMenuView(showMenu: $showMenu, healthStore: healthStore)
                    .offset(x: showMenu ? 0 : -250) // Slide in/out based on `showMenu`
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                // Show menu if dragged more than a threshold from the left
                                if dragOffset.width > 100 {
                                    withAnimation {
                                        showMenu = true
                                    }
                                } else if dragOffset.width < -100 { // Hide menu if dragged from the right
                                    withAnimation {
                                        showMenu = false
                                    }
                                }
                                dragOffset = .zero // Reset the drag offset
                            }
                    )
                    .animation(.easeInOut(duration: 0.3), value: showMenu) // Animations for smooth sliding
            }
            .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    // Show menu if dragged more than a threshold from the left
                                    if dragOffset.width > 100 {
                                        withAnimation {
                                            showMenu = true
                                        }
                                    } else if dragOffset.width < -100 { // Hide menu if dragged from the right
                                        withAnimation {
                                            showMenu = false
                                        }
                                    }
                                    dragOffset = .zero // Reset the drag offset
                                }
                        )
            .onAppear {
                requestNotificationPermission()
                // Fetch the sleep goal from UserDefaults (or use a default if not set)
                let sleepGoal = UserDefaults.standard.double(forKey: "sleepGoal") // Default to 8 if no value is found
                
                // Call fuzzy logic to calculate sleep quality
                sleepQualityScore = calculateSleepQuality(
                    duration: 7.5,  // Sleep duration in hours
                    minHeartRate: 55,  // Minimum heart rate during sleep
                    avgHeartRate: 70,  // Average heart rate during sleep
                    maxHeartRate: 90,  // Maximum heart rate during sleep
                    activityLevel: 6,  // Activity level during the day
                    sleepGoal: sleepGoal  // Sleep goal in hours
                )
                
                // Restore the start time if the app was closed and reopened
                if let savedStartTime = UserDefaults.standard.object(forKey: "sleepStartTime") as? Date {
                    sleepStartTime = savedStartTime
                    isTrackingSleep = true
                    // Recalculate the duration
                    updateLiveDuration()
                }
                
                // Observe for app background and foreground events
                NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
                    startBackgroundTask()
                }
                NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
                    // Update timer when returning to the foreground
                    if isTrackingSleep {
                        updateLiveDuration()
                    }
                }
            }
            .onDisappear {
                // Remove observers when the view disappears
                NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
            }
        }
    }
    
    
     func authenticateUser() {
        let appId = "ZVeQcLTnF9FUcgWMADvBTMGQKeU2zfRJ"
        let appSecret = "VaB55u3Ls7tdcK9hGiLDYvu4u9c0evm2YanBlCGiGF11tkEAZpG5pQqjOZkAGgtn"
        let externalId = "testid01"

         Sahha.authenticate(appId: appId, appSecret: appSecret, externalId: externalId) { error, success in
             DispatchQueue.main.async {
                 if let error = error {
                     authenticationMessage = "Authentication failed: \(error)"
                 } else if success {
                     authenticationMessage = "User authenticated successfully!"
                 } else {
                     authenticationMessage = "Unknown authentication issue occurred."
                 }
             }
         }
    }
    
    

    private func startSleepTimer() {
        sleepStartTime = Date()
        UserDefaults.standard.set(sleepStartTime, forKey: "sleepStartTime")  // Save start time
        isTrackingSleep = true
        formattedSleepDuration = "00:00:00"  // Reset display
        
        // Start a timer that fires every second
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateLiveDuration()
            }
        
        // Begin background task to allow some extra time in the background
        startBackgroundTask()
    }

   

    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SleepTimer") {
            // End the task if time expires.
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
    }

    private func stopSleepTimer() {
        guard let start = sleepStartTime else { return }
        let end = Date()
        let durationInSeconds = end.timeIntervalSince(start)
        sleepDuration = durationInSeconds / 3600.0  // Duration in hours
        isTrackingSleep = false
        
        // Stop the timer and clean up background task
        timerSubscription?.cancel()
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
        
        // Final update of formatted duration
        formattedSleepDuration = formatDuration(durationInSeconds)
        
        saveSleepData(for: end, duration: sleepDuration)
        
        // Clear start time from UserDefaults
        UserDefaults.standard.removeObject(forKey: "sleepStartTime")
    }

    
    // Update the live duration while the timer is running
    private func updateLiveDuration() {
        guard let start = sleepStartTime else { return }
        let elapsedTime = Date().timeIntervalSince(start)
        formattedSleepDuration = formatDuration(elapsedTime)
    }


    // Helper function to format duration as HH:MM:SS
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00:00"
    }

    // Save the sleep data for the specific day
    private func saveSleepData(for date: Date, duration: Double) {
        let dateKey = formattedDate(date: date)
        var manualSleepData = UserDefaults.standard.dictionary(forKey: "manualSleepData") as? [String: Double] ?? [:]
        manualSleepData[dateKey] = duration
        UserDefaults.standard.set(manualSleepData, forKey: "manualSleepData")
    }
    
    // Helper function to format the date as a string for use as a dictionary key
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }



// Define a reusable view for the line graph
struct LineGraphView: View {
    var data: [(String, Double)]  // Data array containing (date, value) tuples
    var title: String
    var color: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding(.top)

            Chart {
                ForEach(data, id: \.0) { entry in
                    LineMark(
                        x: .value("Date", entry.0),
                        y: .value("Hours Slept", entry.1)
                    )
                    .foregroundStyle(color)
                    .symbol(Circle()) // Add circle markers to the line
                }
            }
            .frame(height: 200)  // Set a fixed height for the line chart
            .padding()
        }
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }
}

//FIXME sleep tracker: test out data transfer from watch to sleep tracker.

#Preview {
    ContentView()
}
