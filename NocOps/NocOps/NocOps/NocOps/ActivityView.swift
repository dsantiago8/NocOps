//
//  ActivityView.swift
//  NocOps
//
//  Created by Diego Santiago on 10/31/24.
//

import SwiftUI
import HealthKit

struct ActivityView: View {
    @State private var activitySummary: HKActivitySummary?

    private let healthStore = HKHealthStore()

    var body: some View {
        VStack {
            if let summary = activitySummary {
                // If activity summary is available, show the data
                VStack {
                    Text("Activity Rings")
                        .font(.title)
                        .padding(.bottom, 20)

                    HStack(spacing: 30) {
                        RingView(value: summary.activeEnergyBurned.doubleValue(for: .kilocalorie()), total: summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()), color: .red)
                        RingView(value: summary.appleExerciseTime.doubleValue(for: .minute()), total: summary.appleExerciseTimeGoal.doubleValue(for: .minute()), color: .green)
                        RingView(value: summary.appleStandHours.doubleValue(for: .count()), total: summary.appleStandHoursGoal.doubleValue(for: .count()), color: .blue)
                    }

                    // Legend for the actual data
                    HStack {
                        Text("Red: Active Energy")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Text("Green: Exercise Time")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Text("Blue: Stand Hours")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                }
            } else {
                // Show loading or sample data if activity summary is unavailable
                Text("Loading activity data...")
                    .onAppear(perform: loadActivitySummary)

                // Show sample data if activity data is unavailable
                VStack {
                    Text("Activity Rings (Sample Data)")
                        .font(.title)
                        .padding(.bottom, 20)

                    HStack(spacing: 30) {
                        RingView(value: 300, total: 500, color: .red) // Sample data
                        RingView(value: 30, total: 60, color: .green) // Sample data
                        RingView(value: 8, total: 12, color: .blue) // Sample data
                    }

                    // Legend for the sample data
                    HStack {
                        Text("Red: Active Energy")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        Text("Green: Exercise Time")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Text("Blue: Stand Hours")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding()
    }

    private func loadActivitySummary() {
        let activityType = HKObjectType.activitySummaryType()
        
        healthStore.requestAuthorization(toShare: nil, read: [activityType]) { success, error in
            if success {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                
                // Initialize dateComponents with the calendar
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
                dateComponents.calendar = calendar

                // Updated predicate for a single day
                let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)

                let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, _ in
                    if let summaries = summaries, !summaries.isEmpty {
                        self.activitySummary = summaries.first
                    } else {
                        // Set the activitySummary to nil if no data is available
                        self.activitySummary = nil
                    }
                }
                
                healthStore.execute(query)
            }
        }
    }
}

struct RingView: View {
    var value: Double
    var total: Double
    var color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .foregroundColor(color.opacity(0.3))
            Circle()
                .trim(from: 0, to: CGFloat(value / total))
                .stroke(color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((value / total) * 100))%")
                .font(.headline)
        }
        .frame(width: 100, height: 100)
    }
}
