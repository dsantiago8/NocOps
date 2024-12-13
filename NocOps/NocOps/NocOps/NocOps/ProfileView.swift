//
//  ProfileView.swift
//  NocOps
//
//  Created by Diego Santiago on 11/30/24.
//
import SwiftUI

struct ProfileView: View {
    @State private var sleepGoal: Double = UserDefaults.standard.double(forKey: "sleepGoal") // Load from UserDefaults
    @EnvironmentObject var themeManager: ThemeManager  // Access the shared ThemeManager
    @State private var unlockedThemes: [String] = [] // Unlocked themes array
    @State private var selectedTheme: String = "" // State variable for selected theme

    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: themeManager.gradientColors),
                           startPoint: .bottom,
                           endPoint: .top)
            .edgesIgnoringSafeArea(.all)
            
            ScrollView{
                VStack {
                    Text("Profile")
                        .font(.largeTitle)
                        .padding()
                    
                    // Sleep Goal Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sleep Goal")
                            .font(.headline)
                        Text("\(sleepGoal, specifier: "%.1f") hours")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Slider(value: $sleepGoal, in: 4...12, step: 0.5) {
                            Text("Adjust Sleep Goal")
                        }
                        .padding()
                        .onChange(of: sleepGoal) { newValue in
                            // Save the new sleep goal value to UserDefaults
                            UserDefaults.standard.set(newValue, forKey: "sleepGoal")
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding()
                    
                    // Theme Selection Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Theme")
                            .font(.headline)
                        
                        // Theme Picker - only showing unlocked themes
                        Picker("Select Theme", selection: $selectedTheme) {
                            ForEach(filteredUnlockedThemes(), id: \.self) { theme in
                                Text(theme).tag(theme)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        .onChange(of: selectedTheme) { newTheme in
                            // Update the selected theme in the ThemeManager
                            themeManager.setTheme(to: newTheme)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        .onAppear {
            // Ensure sleep goal is loaded when the view appears
            sleepGoal = UserDefaults.standard.double(forKey: "sleepGoal")
            // Load unlocked themes from UserDefaults when the view appears
            unlockedThemes = UserDefaults.standard.stringArray(forKey: "unlockedRewards") ?? []

        }
    }
    // Function to filter out "Treat(+10HP)" from the unlocked themes list
    private func filteredUnlockedThemes() -> [String] {
        return unlockedThemes.filter { $0 != "Treat(+10HP)" }
    }
}
