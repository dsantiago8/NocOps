//
//  NocOpsApp.swift
//  NocOps
//
//  Created by Diego Santiago on 9/18/24.
//

import SwiftUI
import Sahha

@main
struct NocOpsApp: App {
    init() {
      let settings = SahhaSettings(
        environment: .sandbox // Required - .sandbox for testing
      )
        
      Sahha.configure(settings) {
        // SDK is ready to use
        print("SDK Ready")
      }
    }
    
    @StateObject private var themeManager = ThemeManager()

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
        }
    }
}



