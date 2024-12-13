//
//  SideMenuView.swift
//  NocOps
//
//  Created by Diego Santiago on 10/31/24.
//

// Modified SideMenuView to include NavigationLink for navigation
import SwiftUI

struct SideMenuView: View {
    @Binding var showMenu: Bool
    var healthStore: HealthStore  // Add healthStore as a parameter
    @State private var dragOffset = CGSize.zero // For handling the drag gesture


    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                NavigationLink(destination: SleepTrackerView()) {
                    Text("Sleep tracker")
                        .font(.custom("OpenSans-Regular", size: 24))
                        .padding(.top, 100)
                        .foregroundColor(.white)
                }
                
                NavigationLink(destination: SleepView(healthStore: healthStore)) {
                    Text("Last Night's Sleep")
                        .font(.custom("OpenSans-Regular", size: 24))
                        .foregroundColor(.white)
                        .padding(.top, 20)
            
                }
                
                NavigationLink(destination: StatsView(healthStore: healthStore)) {
                    Text("Stats")
                        .font(.custom("OpenSans-Regular", size: 24))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
                
                NavigationLink(destination: ActivityView()) {
                    Text("Activity")
                        .font(.custom("OpenSans-Regular", size: 24))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
                NavigationLink(destination: ShopView()) {
                    Text("Shop")
                        .font(.custom("OpenSans-Regular", size: 24))
                        .padding(.top, 100)
                        .foregroundColor(.white)
                }
                NavigationLink(destination: ProfileView()) {
                    Text("Profile")
                        .font(.custom("OpenSans-Regular", size: 24))
                        .padding(.top, 20)
                        .foregroundColor(.white)
                }
                NavigationLink(destination: PetView()) {
                    Text("My Pet")
                        .font(.custom("OpenSans-Regular", size: 24))
                        .padding(.top, 20)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .frame(maxWidth: 250)
            .background(Color(.systemGray6))
            .offset(x: showMenu ? 0 : -250) // Slide the menu in and out


            Spacer()
        }
        .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Track the drag offset
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            // If the drag is towards the right, show the menu; else hide it
                            if dragOffset.width > 100 { // Threshold for showing the menu
                                withAnimation {
                                    showMenu = true
                                }
                            } else if dragOffset.width < -100 { // Threshold for hiding the menu
                                withAnimation {
                                    showMenu = false
                                }
                            }
                            // Reset drag offset
                            dragOffset = .zero
                        }
                )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showMenu = false
            }
        }
        .background(Color.black.opacity(showMenu ? 0.3 : 0))
        .animation(.easeInOut(duration: 0.3), value: showMenu)
    }
}
