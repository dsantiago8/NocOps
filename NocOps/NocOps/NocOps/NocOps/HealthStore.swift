//
//  HealthStore.swift
//  NocOps
//
//  Created by Diego Santiago on 10/31/24.
//
import SwiftUI
import HealthKit
import Combine

class HealthStore: ObservableObject {
    private var healthStore: HKHealthStore?
    
    @Published var heartRate: Double?
    @Published var weight: Double?
    @Published var sleepData: [String: Double] = [:]  // Store sleep data with dates as keys
    @Published var lastNightHeartRate: (min: Double, max: Double, average: Double) = (0, 0, 0)
    @Published var weeklyHeartRate: (min: Double, max: Double, average: Double) = (0, 0, 0)
    @Published var monthlyHeartRate: (min: Double, max: Double, average: Double) = (0, 0, 0)


    //

    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        
        guard let healthStore = healthStore else {
            return completion(false)
        }
        
        healthStore.requestAuthorization(toShare: [], read: [heartRateType, bodyMassType, sleepAnalysisType]) { (success, error) in
            completion(success)
        }
        
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!

        healthStore.requestAuthorization(toShare: [], read: [sleepType]) { success, _ in
            completion(success)
        }

    }
    
    func getSleepData(completion: @escaping (Bool) -> Void) {
        let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Predicate for the last 7 days of sleep data
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { query, results, error in
            guard let results = results as? [HKCategorySample] else {
                
                
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            var newSleepData: [String: Double] = [:]
            for sample in results {
                let sleepStart = sample.startDate
                let sleepEnd = sample.endDate
                let duration = sleepEnd.timeIntervalSince(sleepStart) / 3600.0 // Duration in hours
                
                let dateKey = self.formattedDate(date: sleepStart)
                newSleepData[dateKey, default: 0] += duration
            }
        
            
            DispatchQueue.main.async {
                self.sleepData = newSleepData  // Update the sleep data
                completion(true)
            }
        }
        
        
        healthStore?.execute(query)
    }
    
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func getLatestHeartRate() {
          let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
          
          let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
          let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, results, error in
              guard let result = results?.first as? HKQuantitySample else {
                  DispatchQueue.main.async {
                      self.heartRate = nil
                  }
                  return
              }
              
              let heartRate = result.quantity.doubleValue(for: HKUnit(from: "count/min"))
              DispatchQueue.main.async {
                  print("Heart Rate: \(heartRate)")  // Add this line to verify the heart rate
                  self.heartRate = heartRate
              }
          }
          
          healthStore?.execute(query)
      }
      
    func getLatestWeight() {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, results, error in
            guard let result = results?.first as? HKQuantitySample else {
                DispatchQueue.main.async {
                    self.weight = nil
                }
                return
            }
            
            let weight = result.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            DispatchQueue.main.async {
                self.weight = weight
            }
        }
    }
    
    func getLastNightSleepCycles(completion: @escaping ([SleepStage]) -> Void) {
        let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { _, results, error in
            guard let results = results as? [HKCategorySample], error == nil else {
                completion([])
                return
            }
            
            let stages = results.map { sample -> SleepStage in
                let stage: String
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    stage = "REM"
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    stage = "Deep"
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    stage = "Light"
                default:
                    stage = "Unknown"
                }
                return SleepStage(startDate: sample.startDate, endDate: sample.endDate, stage: stage)
            }
            completion(stages)
        }
        
        healthStore?.execute(query)
    }
    
    private func fetchHeartRateData(for startDate: Date, endDate: Date, completion: @escaping (Double, Double, Double) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Corrected argument labels
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { query, results, error in
            guard let samples = results as? [HKQuantitySample], error == nil else {
                completion(0, 0, 0)
                return
            }
            
            let heartRates = samples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
            
            // Calculate min, max, and average
            let minHeartRate = heartRates.min() ?? 0
            let maxHeartRate = heartRates.max() ?? 0
            let avgHeartRate = heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / Double(heartRates.count)
            
            completion(minHeartRate, maxHeartRate, avgHeartRate)
        }
        
        healthStore?.execute(query)
    }

    func getLastNightHeartRate() {
        let calendar = Calendar.current
        let startOfLastNight = calendar.startOfDay(for: Date().addingTimeInterval(-24 * 60 * 60))  // Start of yesterday
        let endOfLastNight = calendar.startOfDay(for: Date())  // Start of today

        // Call fetchHeartRateData with corrected argument labels
        fetchHeartRateData(for: startOfLastNight, endDate: endOfLastNight) { min, max, average in
            DispatchQueue.main.async {
                self.lastNightHeartRate = (min, max, average)
            }
        }
    }

    func getWeeklyHeartRate() {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: Date())!

        // Call fetchHeartRateData with corrected argument labels
        fetchHeartRateData(for: startOfWeek, endDate: Date()) { min, max, average in
            DispatchQueue.main.async {
                self.weeklyHeartRate = (min, max, average)
            }
        }
    }

    func getMonthlyHeartRate() {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(byAdding: .day, value: -30, to: Date())!

        // Call fetchHeartRateData with corrected argument labels
        fetchHeartRateData(for: startOfMonth, endDate: Date()) { min, max, average in
            DispatchQueue.main.async {
                self.monthlyHeartRate = (min, max, average)
            }
        }
    }


}

class HealthStoreManager: ObservableObject {
    @Published var sleepData: [SleepStage] = []
    private var healthStore: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func getSleepData(completion: @escaping (Bool) -> Void) {
        guard let healthStore = healthStore else { return }
        let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { _, results, error in
            guard let results = results as? [HKCategorySample], error == nil else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Map results to SleepStage structs
            let stages = results.map { sample -> SleepStage in
                let stageName: String
                switch sample.value {
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    stageName = "REM Sleep"
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    stageName = "Deep Sleep"
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    stageName = "Light Sleep"
                default:
                    stageName = "Unknown"
                }
                
                return SleepStage(startDate: sample.startDate, endDate: sample.endDate, stage: stageName)
            }
            
            DispatchQueue.main.async {
                self.sleepData = stages  // Update published data
                completion(true)
            }
        }
        
        healthStore.execute(query)
    }
}
