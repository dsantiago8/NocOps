//
//  SleepView.swift
//  NocOps
//
//  Created by Diego Santiago on 10/31/24.
//

import SwiftUI
import Combine
import Charts
import HealthKit

struct SleepStage: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let stage: String
}

struct SleepView: View {
    @EnvironmentObject var themeManager: ThemeManager  // Access the shared ThemeManager
    @ObservedObject var healthStore = HealthStore()
    @ObservedObject var healthStoreManager = HealthStoreManager()
    @State private var authorizationStatus: Bool = false
    @State private var timer: AnyCancellable?
    @State private var sleepStages: [SleepStage] = [] // Stores last night's sleep stages

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: themeManager.gradientColors),
                           startPoint: .bottom,
                           endPoint: .top)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    List(healthStoreManager.sleepData) { stage in
                        VStack(alignment: .leading) {
                            Text("Stage: \(stage.stage)")
                                .font(.headline)
                            Text("Start: \(formattedDate(stage.startDate))")
                            Text("End: \(formattedDate(stage.endDate))")
                        }
                        .padding()
                    }
                    Button("Fetch Sleep Data") {
                        healthStoreManager.getSleepData { success in
                            if success {
                                print("Sleep data fetched successfully")
                            } else {
                                print("Failed to fetch sleep data")
                            }
                        }
                    }
                    
                    if authorizationStatus {
                        // Display heart rate
                        if let heartRate = healthStore.heartRate {
                            Text("Last Fetched Heart Rate: \(String(format: "%.1f", heartRate)) BPM")
                                .font(.title)
                                .foregroundColor(.purple)
                        } else {
                            Text("Heart Rate: N/A")
                                .font(.title)
                                .foregroundColor(.red)
                        }
                        
                        if !sleepStages.isEmpty {
                            Chart(sleepStages) { stage in
                                BarMark(
                                    x: .value("Time", stage.startDate),
                                    y: .value("Stage", stage.stage)
                                )
                                .foregroundStyle(stageColor(stage: stage.stage)) // Correctly link the color styling


                            }
                            .frame(height: 300)
                            .padding()
                        }else {
                            // Default visualization when there are no sleep cycles
                            VStack {
                                Text("No sleep cycle data available")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                Chart {
                                    BarMark(
                                        x: .value("Time", "00:00"),
                                        y: .value("Stage", "Sample Data")
                                    )
                                    BarMark(
                                        x: .value("Time", "04:00"),
                                        y: .value("Stage", "Sample Data")
                                    )
                                    BarMark(
                                        x: .value("Time", "08:00"),
                                        y: .value("Stage", "Sample Data")
                                    )
                                }
                                .frame(height: 300)
                                .padding()
                                .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("Health Data Access Denied")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    requestHealthKitAuthorization()
                    startTimer() // Start the timer to fetch data
                    
                    sleepStages = [
                        SleepStage(startDate: Date().addingTimeInterval(-3600 * 7), endDate: Date().addingTimeInterval(-3600 * 6), stage: "REM"),
                        SleepStage(startDate: Date().addingTimeInterval(-3600 * 6), endDate: Date().addingTimeInterval(-3600 * 5), stage: "Deep"),
                        SleepStage(startDate: Date().addingTimeInterval(-3600 * 5), endDate: Date().addingTimeInterval(-3600 * 4), stage: "Light"),
                        SleepStage(startDate: Date().addingTimeInterval(-3600 * 4), endDate: Date().addingTimeInterval(-3600 * 3), stage: "REM")
                    ]
                    
                }
                .onDisappear {
                    stopTimer() // Stop the timer when the view disappears
                }
                .navigationTitle("Last Night's Sleep")
            }
            .refreshable {
                healthStore.getLatestHeartRate()
                fetchLastNightSleepCycles() // Fetch the latest sleep cycle data
            }
        }
    }

    private func requestHealthKitAuthorization() {
        healthStore.requestAuthorization { success in
            DispatchQueue.main.async {
                authorizationStatus = success
                if success {
                    print("Authorization succeeded")
                    healthStore.getLatestHeartRate()
                    fetchLastNightSleepCycles()
                } else {
                    print("Authorization failed")
                }
            }
        }
    }

    private func startTimer() {
        // Refresh every 5 seconds
        timer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                healthStore.getLatestHeartRate()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func fetchLastNightSleepCycles() {
        healthStore.getLastNightSleepCycles { stages in
            DispatchQueue.main.async {
                self.sleepStages = stages
                print("Fetched Sleep Stages: \(stages)") // Debugging statement
            }
        }
    }
    // Helper function to format dates
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper function to assign color based on stage
    private func stageColor(stage: String) -> Color {
        switch stage {
        case "REM":
            return .purple
        case "Deep":
            return .blue
        case "Light":
            return .green
        default:
            return .gray
        }
    }
}
