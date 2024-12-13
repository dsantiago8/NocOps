import Foundation

// Sleep Duration Membership Function
func sleepDurationMembership(duration: Double) -> (short: Double, medium: Double, long: Double) {
    let short = max(0, min(1, (8 - duration) / 2))  // if duration < 8 hours, the short membership increases
    let medium = max(0, min(1, (duration - 6) / 2))  // if duration is between 6 and 8 hours, medium membership increases
    let long = max(0, min(1, (duration - 7) / 3))  // if duration > 7 hours, long membership increases
    
    // Debugging: Log the membership values
    print("Sleep Duration - Short: \(short), Medium: \(medium), Long: \(long)")
    
    return (short, medium, long)
}


// Heart Rate Membership Function
func heartRateMembership(min_: Double, avg: Double, max_: Double) -> (low: Double, normal: Double, high: Double) {
    let low = max(0, min(1, (60 - avg) / 20))  // if average heart rate < 60, low membership increases
    let normal = max(0, min(1, (avg - 60) / 20))  // if average heart rate is near 60, normal membership increases
    let high = max(0, min(1, (avg - 80) / 20))  // if average heart rate > 80, high membership increases
    
    // Debugging: Log the membership values
    print("Heart Rate - Low: \(low), Normal: \(normal), High: \(high)")
    
    return (low, normal, high)
}

func activityLevelMembership(level: Double) -> (low: Double, moderate: Double, high: Double) {
    let low = max(0, min(1, (5 - level) / 2))  // if activity level < 5, low membership increases
    let moderate = max(0, min(1, (level - 3) / 2))  // if activity level is between 3 and 5, moderate increases
    let high = max(0, min(1, (level - 6) / 2))  // if activity level > 6, high membership increases
    
    // Debugging: Log the membership values
    print("Activity Level - Low: \(low), Moderate: \(moderate), High: \(high)")
    
    return (low, moderate, high)
}


// Fuzzy Rules (Balanced Weights)
func fuzzyRules(sleepDuration: (short: Double, medium: Double, long: Double),
                heartRate: (low: Double, normal: Double, high: Double),
                activityLevel: (low: Double, moderate: Double, high: Double),
                sleepGoal: Double) -> Double {
    var sleepQuality: Double = 0
    
    // Rule 1: Poor quality (Short sleep duration, high heart rate)
    let poorQuality = min(sleepDuration.short, heartRate.high) * 30  // Reduce the weight for poor quality
    sleepQuality += poorQuality
    
    // Rule 2: Good quality (Long sleep duration, moderate activity)
    let goodQuality = min(sleepDuration.long, activityLevel.moderate) * 120 // Reduce the weight for good quality
    sleepQuality += goodQuality
    
    // Rule 3: Goal quality (Sleep goal is met, heart rate is normal)
    if sleepGoal - sleepDuration.long <= 1.0 {
        let goalProximityScore = min(heartRate.normal, 1.0) * 50  // Moderate weight for goal quality
        sleepQuality += goalProximityScore
    }
    
    // Rule 4: Moderate Normal Quality (Moderate sleep duration, normal heart rate)
    let moderateNormal = min(sleepDuration.medium, heartRate.normal) * 50  // Reduced weight for moderate quality
    sleepQuality += moderateNormal
    
    // Rule 5: Short High Activity (Short sleep duration, high activity level)
    let shortHighActivity = min(sleepDuration.short, activityLevel.high) * 30 // Reduced weight for short sleep with high activity
    sleepQuality += shortHighActivity
    
    // Rule 6: Long Low Heart Rate (Long sleep duration, low heart rate)
    let longLowHeartRate = min(sleepDuration.long, heartRate.low) * 30 // Reduce the weight for long sleep with low heart rate
    sleepQuality += longLowHeartRate
    
    // Rule 7: Very Short Sleep Duration (less than 4 hours) -> Strong Penalty
    let veryShortSleep = min(sleepDuration.short, 1.0) * 100  // Keep a strong penalty for very short sleep
    sleepQuality += veryShortSleep
    
    // Rule 8: High Activity with Short Sleep Duration -> Poor Quality
    let highActivityShortSleep = min(sleepDuration.short, activityLevel.high) * 40  // High activity but short sleep
    sleepQuality += highActivityShortSleep
    
    // Rule 9: Long Sleep Duration with High Heart Rate -> Potential Sleep Issues
    let longHighHeartRate = min(sleepDuration.long, heartRate.high) * 30  // Long duration but high heart rate, slight penalty
    sleepQuality += longHighHeartRate
    
    // Rule 10: Low Activity with Short Sleep Duration -> Very Poor Quality
    let lowActivityShortSleep = min(sleepDuration.short, activityLevel.low) * 60  // Low activity and short sleep, large penalty
    sleepQuality += lowActivityShortSleep
    
    // Rule 11: Moderate Activity with Short Sleep Duration -> Slight Penalty
    let moderateActivityShortSleep = min(sleepDuration.short, activityLevel.moderate) * 30
    sleepQuality += moderateActivityShortSleep
    
    // Rule 12: Moderate Activity with Long Sleep Duration -> Slight Bonus
    let moderateActivityLongSleep = min(sleepDuration.long, activityLevel.moderate) * 50
    sleepQuality += moderateActivityLongSleep
    
    // Rule 13: Moderate Activity with Normal Heart Rate -> Moderate Bonus
    let moderateNormalActivity = min(activityLevel.moderate, heartRate.normal) * 30
    sleepQuality += moderateNormalActivity
    
    // Rule 14: Moderate Activity with High Heart Rate -> Slight Penalty
    let moderateHighActivity = min(activityLevel.moderate, heartRate.high) * 20
    sleepQuality += moderateHighActivity
    
    // Penalty for not meeting the sleep goal (if sleep duration is less than the goal)
    let penaltyForNotMeetingGoal = max(0, sleepGoal - sleepDuration.long) * 1.25  // Penalty if sleep duration is less than the goal
    sleepQuality -= penaltyForNotMeetingGoal  // Subtract penalty
    
    
    print("Final Sleep Quality: \(sleepQuality)") // Debugging output
    
    return sleepQuality
}




// Defuzzification (Convert fuzzy output to a crisp value)
func defuzzify(sleepQuality: Double) -> Double {
    let finalScore = min(max(sleepQuality, 0), 100)
    print("Defuzzified Score: \(finalScore)")
    return finalScore
}

// Main function to calculate sleep quality
func calculateSleepQuality(duration: Double, minHeartRate: Double, avgHeartRate: Double, maxHeartRate: Double, activityLevel: Double, sleepGoal: Double) -> Double {
    // Get membership values for each input
    let sleepDuration = sleepDurationMembership(duration: duration)
    let heartRate = heartRateMembership(min_: minHeartRate, avg: avgHeartRate, max_: maxHeartRate)
    let activity = activityLevelMembership(level: activityLevel)
    
    // Apply fuzzy rules to calculate sleep quality
    let fuzzyScore = fuzzyRules(sleepDuration: sleepDuration, heartRate: heartRate, activityLevel: activity, sleepGoal: sleepGoal)
    
    // Return the defuzzified score
    return defuzzify(sleepQuality: fuzzyScore)
}
