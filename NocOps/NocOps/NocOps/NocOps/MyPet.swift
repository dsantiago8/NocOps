//
//  MyPet.swift
//  NocOps
//
//  Created by Diego Santiago on 12/3/24.
//

import SwiftUI

struct PetView: View {
    @State private var petHealth: Int = UserDefaults.standard.integer(forKey: "petHealth") // Load from UserDefaults
    @State private var timer: Timer? // Timer to decrease health
    @State private var isPetAlive = true // Check if the pet is still alive
    @EnvironmentObject var themeManager: ThemeManager  // Access the shared ThemeManager

    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: themeManager.gradientColors),
                           startPoint: .bottom,
                           endPoint: .top)
            .edgesIgnoringSafeArea(.all)
            VStack {
                Text("Pet Health")
                    .font(.largeTitle)
                    .padding()
                
                // Health Bar
                ProgressView(value: Double(petHealth), total: 100)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                    .frame(height: 20)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                
                Text("\(petHealth) HP")
                    .font(.title2)
                    .foregroundColor(isPetAlive ? .yellow : .red)
                    .padding()
                
                if !isPetAlive {
                    Text("Your pet has passed away!")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                }
                // Reset Button to restore pet health to 70
                Button(action: resetPetHealth) {
                    Text("Reset Pet Health")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 20)
                Spacer()
            }
            .onAppear {
                // Ensures the latest pet health value is loaded each time the view appears
                petHealth = UserDefaults.standard.integer(forKey: "petHealth")
                
                // Set the initial health value when the view appears
                if petHealth == 0 {
                    petHealth = 70 // Reset health if it's not already set
                }
                // Start the timer to decrease pet health daily
                startHealthDecrementTimer()
            }
            .onDisappear {
                // Stop the timer when the view disappears
                stopHealthDecrementTimer()
            }
        }
    }
    
    // Function to start the health decrement timer
    private func startHealthDecrementTimer() {
        // Decrease health every 24 hours
        timer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            decrementPetHealth()
        }
    }
    
    // Function to stop the health decrement timer
    private func stopHealthDecrementTimer() {
        timer?.invalidate()
    }
    
    // Function to decrement pet health
    private func decrementPetHealth() {
        if petHealth > 0 {
            petHealth -= 10 // Decrease health by 10 each day
        }
        
        if petHealth <= 0 {
            petHealth = 0
            isPetAlive = false
        }
        
        // Save the pet health to UserDefaults
        UserDefaults.standard.set(petHealth, forKey: "petHealth")
    }
    
    // Function to reset pet health to 70
    private func resetPetHealth() {
        petHealth = 70 // Reset the pet health
        isPetAlive = true // Set the pet alive status to true
        UserDefaults.standard.set(petHealth, forKey: "petHealth") // Save the updated health to UserDefaults
    }
}
