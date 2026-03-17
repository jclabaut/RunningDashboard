import Foundation
import HealthKit


class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let runningType = HKObjectType.workoutType()

        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }

        healthStore.requestAuthorization(toShare: nil, read: [runningType]) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    // MARK: - Data Fetching

    /// Fetches running workouts within a specific date range
    func fetchRunningWorkouts(startDate: Date, endDate: Date, completion: @escaping ([HKWorkout]?, Error?) -> Void) {
        let predicate = HKQuery.predicateForWorkouts(with: .running)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, datePredicate])

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: HKObjectType.workoutType(),
                                  predicate: compoundPredicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [sortDescriptor]) { _, samples, error in

            guard let workouts = samples as? [HKWorkout], error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }

            DispatchQueue.main.async {
                completion(workouts, nil)
            }
        }

        healthStore.execute(query)
    }

    /// Calculates total distance in Kilometers from a list of workouts
    func calculateTotalDistance(from workouts: [HKWorkout]) -> Double {
        return workouts.reduce(0.0) { result, workout in
            let distanceInMeters = workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?
                .sumQuantity()?.doubleValue(for: .meter()) ?? 0
            return result + (distanceInMeters / 1000.0)
        }
    }

    /// Groups workouts by month for charting
    /// Returns a dictionary where Key is the start of the month (Date) and Value is total distance (Double)
    func groupWorkoutsByMonth(workouts: [HKWorkout]) -> [(date: Date, distance: Double)] {
        var groups: [Date: Double] = [:]
        let calendar = Calendar.current

        for workout in workouts {
            let components = calendar.dateComponents([.year, .month], from: workout.startDate)
            if let startOfMonth = calendar.date(from: components) {
                let distanceInMeters = workout.statistics(for: HKQuantityType(.distanceWalkingRunning))?
                    .sumQuantity()?.doubleValue(for: .meter()) ?? 0
                let distanceInKm = distanceInMeters / 1000.0
                groups[startOfMonth, default: 0] += distanceInKm
            }
        }

        return groups.sorted { $0.key < $1.key }.map { (date: $0.key, distance: $0.value) }
    }
}
