# NocOps: Sleep Better

NocOps is an iOS application designed to improve sleep quality and user engagement through personalized feedback and gamification. By combining HealthKit data with a fuzzy logic system, the app calculates a personalized sleep quality score and encourages users to maintain healthy sleep habits with challenges, pet care mechanics, and rewards.

---

## 📱 Features

- **Personalized Sleep Score** based on sleep duration, heart rate, and activity level using a Mamdani fuzzy logic system
- **Gamification** with daily sleep challenges, a pet health system, and rewards to increase user motivation
- **Data Visualization** for tracking trends in sleep and user engagement
- **Customizable Shop** for in-app purchases (with in-app points) to personalize the experience
- **HealthKit Integration** to automatically fetch and process sleep and activity data

---

## 💡 Problem Addressed

Many sleep tracking apps struggle to keep users engaged long-term. NocOps tackles this issue by providing actionable, personalized feedback and using game elements to maintain user interest and encourage healthy sleep habits.

---

## 🧠 Technical Overview

- **Language**: Swift 5.9
- **Architecture**: Modular MVC with reusable views
- **Data Sources**: Apple HealthKit (sleep, heart rate, activity)
- **Fuzzy Logic Engine**: Implements Mamdani system with defined fuzzy sets and rules
- **Deployment Target**: iOS 17+

---

## 🛠️ Setup Instructions

### 1. Prerequisites
- macOS Ventura or higher
- Xcode 15.0+
- iOS Simulator 17+ or physical device
- Git 2.40+ (optional: Homebrew for macOS)

### 2. Clone Repository
```bash
git clone https://github.com/dsantiago8/NocOps/tree/main
cd NocOps
```
### 3. Build and Run
Ensure the following packages are enabled:
- Combine (built-in)
- HealthKit Integration (built-in)

Set the deployment target to iOS 17.0.


## 📎 Related Files

- [`Comprehensive_Final_Paper.pdf`](./Comprehensive_Final_Paper.pdf): Full project report outlining the background, methods, results, and discussion.
