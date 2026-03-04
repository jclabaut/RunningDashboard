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
    
    init() {
        // Initialize custom range to "This Month" by default
        let calendar = Calendar.current
        let now = Date()
        selectedCustomStartDate = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        selectedCustomEndDate = now
    }
    
    func requestAuthorizationAndFetchData() {
        isLoading = true
        healthManager.requestAuthorization { [weak self] success in
            guard success else {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "HealthKit access denied or unavailable."
                }
                return
            }
            self?.fetchAllStats()
        }
    }
    
    func fetchAllStats() {
        let now = Date()
        let calendar = Calendar.current
        
        // Helper to calculate date by subtracting components
        func date(byAdding component: Calendar.Component, value: Int) -> Date {
            return calendar.date(byAdding: component, value: value, to: now) ?? now
        }
        
        let oneYearAgo = date(byAdding: .year, value: -1)
        let threeMonthsAgo = date(byAdding: .month, value: -3)
        let oneMonthAgo = date(byAdding: .month, value: -1)
        let oneWeekAgo = date(byAdding: .day, value: -7)
        
        // 1. Fetch 1 Year Data (Use this for the annual total AND the monthly chart)
        healthManager.fetchRunningWorkouts(startDate: oneYearAgo, endDate: now) { [weak self] workouts, error in
            guard let self = self, let workouts = workouts else { return }
            
            let total1Year = self.healthManager.calculateTotalDistance(from: workouts)
            let chartData = self.healthManager.groupWorkoutsByMonth(workouts: workouts)
            
            // Filter locally for smaller ranges to avoid excessive queries (optimization)
            let total3Months = self.filterAndSum(workouts: workouts, since: threeMonthsAgo)
            let total1Month = self.filterAndSum(workouts: workouts, since: oneMonthAgo)
            let total1Week = self.filterAndSum(workouts: workouts, since: oneWeekAgo)
            
            DispatchQueue.main.async {
                self.totalDistanceLast1Year = total1Year
                self.monthlyData = chartData
                self.totalDistanceLast3Months = total3Months
                self.totalDistanceLast1Month = total1Month
                self.totalDistanceLast1Week = total1Week
                self.isLoading = false
            }
        }
        
        // Initial custom range calculation
        updateCustomRangeStats()
    }
    
    func updateCustomRangeStats() {
        healthManager.fetchRunningWorkouts(startDate: selectedCustomStartDate, endDate: selectedCustomEndDate) { [weak self] workouts, _ in
            guard let self = self, let workouts = workouts else { return }
            let total = self.healthManager.calculateTotalDistance(from: workouts)
            DispatchQueue.main.async {
                self.customRangeTotal = total
            }
        }
    }
    
    private func filterAndSum(workouts: [HKWorkout], since date: Date) -> Double {
        let filtered = workouts.filter { $0.startDate >= date }
        return healthManager.calculateTotalDistance(from: filtered)
    }
}
