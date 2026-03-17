import Foundation
import HealthKit
import Combine

class DashboardViewModel: ObservableObject {
    @Published var totalDistanceLast1Year: Double = 0.0
    @Published var totalDistanceLast3Months: Double = 0.0
    @Published var totalDistanceLast1Month: Double = 0.0
    @Published var totalDistanceLast1Week: Double = 0.0

    @Published var monthlyData: [(date: Date, distance: Double)] = []

    @Published var selectedCustomStartDate = Date()
    @Published var selectedCustomEndDate = Date()
    @Published var customRangeTotal: Double = 0.0

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let healthManager = HealthKitManager.shared
    private var debounceTask: Task<Void, Never>?

    init() {
        let calendar = Calendar.current
        let now = Date()
        selectedCustomStartDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        selectedCustomEndDate = now
    }

    func requestAuthorizationAndFetchData() {
        isLoading = true
        healthManager.requestAuthorization { [weak self] success in
            // Callback is already on the main thread
            guard success else {
                self?.isLoading = false
                self?.errorMessage = "HealthKit access denied or unavailable."
                return
            }
            self?.fetchAllStats()
        }
    }

    func fetchAllStats() {
        let now = Date()
        let calendar = Calendar.current

        func date(byAdding component: Calendar.Component, value: Int) -> Date {
            return calendar.date(byAdding: component, value: value, to: now) ?? now
        }

        let oneYearAgo = date(byAdding: .year, value: -1)
        let threeMonthsAgo = date(byAdding: .month, value: -3)
        let oneMonthAgo = date(byAdding: .month, value: -1)
        let oneWeekAgo = date(byAdding: .day, value: -7)

        // Fetch 1 year of data and derive all sub-ranges locally
        healthManager.fetchRunningWorkouts(startDate: oneYearAgo, endDate: now) { [weak self] workouts, error in
            // Callback is already on the main thread
            guard let self else { return }

            if let error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }

            let workouts = workouts ?? []
            self.totalDistanceLast1Year = self.healthManager.calculateTotalDistance(from: workouts)
            self.monthlyData = self.healthManager.groupWorkoutsByMonth(workouts: workouts)
            self.totalDistanceLast3Months = self.filterAndSum(workouts: workouts, since: threeMonthsAgo)
            self.totalDistanceLast1Month = self.filterAndSum(workouts: workouts, since: oneMonthAgo)
            self.totalDistanceLast1Week = self.filterAndSum(workouts: workouts, since: oneWeekAgo)
            self.isLoading = false
        }

        updateCustomRangeStats()
    }

    /// Debounced entry point called on date picker changes
    func updateCustomRangeStats() {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled, let self else { return }
            self.fetchCustomRangeStats()
        }
    }

    private func fetchCustomRangeStats() {
        healthManager.fetchRunningWorkouts(startDate: selectedCustomStartDate, endDate: selectedCustomEndDate) { [weak self] workouts, error in
            // Callback is already on the main thread
            guard let self else { return }
            if let error {
                self.errorMessage = "Custom range: \(error.localizedDescription)"
                return
            }
            self.customRangeTotal = self.healthManager.calculateTotalDistance(from: workouts ?? [])
        }
    }

    private func filterAndSum(workouts: [HKWorkout], since date: Date) -> Double {
        let filtered = workouts.filter { $0.startDate >= date }
        return healthManager.calculateTotalDistance(from: filtered)
    }
}
