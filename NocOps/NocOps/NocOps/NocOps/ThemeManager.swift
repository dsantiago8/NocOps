//
//  ThemeManager.swift
//  NocOps
//
//  Created by Diego Santiago on 11/29/24.
//

import SwiftUI

class ThemeManager: ObservableObject {
    @Published var gradientColors: [Color] = [Color.purple.opacity(0.8), Color.purple.opacity(0.1)]

    init() {
        // Load saved theme
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") {
            setTheme(to: savedTheme)
        }
    }

    func setTheme(to theme: String) {
        switch theme {
        case "New Theme":
            gradientColors = [Color.blue.opacity(0.8), Color.green.opacity(0.1)]
        case "Custom Graph Colors":
            gradientColors = [Color.orange.opacity(0.8), Color.pink.opacity(0.1)]
        default:
            gradientColors = [Color.purple.opacity(0.8), Color.purple.opacity(0.1)]
        }

        // Save theme to UserDefaults
        UserDefaults.standard.set(theme, forKey: "selectedTheme")
    }
}
