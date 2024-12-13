//
//  ShopView.swift
//  NocOps
//
//  Created by Diego Santiago on 11/29/24.
//

import SwiftUI

struct ShopView: View {
    @EnvironmentObject var themeManager: ThemeManager  // Access the shared ThemeManager
    @State private var points: Int = 0                 // Total user points
    @State private var streak: Int = 0                 // Current streak of consecutive days
    @State private var lastActiveDate: String = ""     // Tracks the last date of activity
    @State private var rewards: [String] = ["New Theme", "New Theme(2)", "Treat(+10HP)"]  // Available rewards
    @State private var unlockedRewards: [String] = []  // User's unlocked rewards
    @State private var petHealth: Int = UserDefaults.standard.integer(forKey: "petHealth")  // Load pet health from UserDefaults


    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: themeManager.gradientColors),
                           startPoint: .bottom,
                           endPoint: .top)
                .edgesIgnoringSafeArea(.all)


            ScrollView {
                VStack(spacing: 30) {
                    // Display points
                    Text("Your Points: \(points)")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                    
                    // Display current streak
                    Text("Streak: \(streak) Days")
                        .font(.title2)
                        .foregroundColor(.white)

                    // Streak multiplier explanation
                    if streak > 1 {
                        Text("Multiplier: \(streak)x points")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    } else {
                        Text("Log sleep to start a streak!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    // Rewards Shop
                    Text("Items")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    ForEach(rewards, id: \.self) { reward in
                        HStack {
                            Text(reward)
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                redeemReward(reward: reward)
                            }) {
                                Text(unlockedRewards.contains(reward) || reward == "Treat(+10HP)" ? "Unlocked" : "Redeem (50)")
                                    .font(.subheadline)
                                    .padding(10)
                                    .background(canPurchase(reward: reward) ? Color.blue : Color.gray) // Disable if not enough points
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(reward != "Treat(+10HP)" && (unlockedRewards.contains(reward) || points < 50)) // Disable button if not enough points or already unlocked
                            .opacity(reward != "Treat(+10HP)" && unlockedRewards.contains(reward) ? 0.5 : 1) // Grayed-out if unlocked

                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Display Pet Health
                    Text("Pet's Health: \(petHealth) HP")
                        .font(.title2)
                        .foregroundColor(petHealth > 0 ? .white : .red)
                    
                    Spacer()

                    Button(action: {
                        resetStreak()
                    }) {
                        Text("Reset Streak")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .onAppear {
                loadUserData()
                points = 200
                checkStreak()
                
            }
        }
        .navigationTitle("Shop")
    }
    
    // MARK: - Helper Functions

    /// Check and update streak based on last activity
    private func checkStreak() {
        let today = formattedDate(date: Date())
        if today == lastActiveDate {
            return // Streak already counted today
        }
        
        if let lastDate = formattedDate(dateString: lastActiveDate), Calendar.current.isDateInYesterday(lastDate) {
            streak += 1 // Continue the streak
        } else {
            streak = 1 // Reset streak
        }
        
        points += 10 * streak // Award points with streak multiplier
        lastActiveDate = today
        saveUserData()
    }

    /// Redeem a reward
    private func redeemReward(reward: String) {
        guard points >= 50 else { return }
        points -= 50
        unlockedRewards.append(reward)
        
        // Update the theme via ThemeManager
        if reward == "New Theme" || reward == "New Theme(2)" {
            print("New Theme Purchased -$$")
            themeManager.setTheme(to: reward)
        }else if reward == "Treat(+10HP)" {
            print("+10HP")
            petHealth += 10 // Increase pet's health by 10
            if petHealth > 100 { petHealth = 100 } // Cap health at 100
        }
        
        saveUserData()
    }
    
    /// Check if a reward can be purchased
    private func canPurchase(reward: String) -> Bool {
        if reward == "Treat(+10HP)" {
            return points >= 50 // Can always buy if the user has enough points
        } else {
            return !unlockedRewards.contains(reward) && points >= 50 // Only allow buying "New Theme" rewards if they haven't been unlocked yet
        }
    }

    /// Reset the streak
    private func resetStreak() {
        streak = 0
        saveUserData()
    }

    /// Save user data to UserDefaults
    private func saveUserData() {
        UserDefaults.standard.set(points, forKey: "userPoints")
        UserDefaults.standard.set(streak, forKey: "userStreak")
        UserDefaults.standard.set(lastActiveDate, forKey: "lastActiveDate")
        UserDefaults.standard.set(unlockedRewards, forKey: "unlockedRewards")
        UserDefaults.standard.set(petHealth, forKey: "petHealth")  // Save pet health to UserDefaults

    }

    /// Load user data from UserDefaults
    private func loadUserData() {
        points = UserDefaults.standard.integer(forKey: "userPoints")
        streak = UserDefaults.standard.integer(forKey: "userStreak")
        lastActiveDate = UserDefaults.standard.string(forKey: "lastActiveDate") ?? ""
        unlockedRewards = UserDefaults.standard.stringArray(forKey: "unlockedRewards") ?? []
        petHealth = UserDefaults.standard.integer(forKey: "petHealth") // Load pet health from UserDefaults
    }

    /// Format a date as a string for comparison
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// Convert string to Date for comparison
    private func formattedDate(dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}
