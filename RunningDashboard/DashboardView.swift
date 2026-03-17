import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    if viewModel.isLoading {
                        ProgressView("Loading Health Data...")
                            .padding()
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                    
                    // MARK: - Overview Grid
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Overview")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            StatCard(title: "Last 7 Days",
                                     value: String(format: "%.1f", viewModel.totalDistanceLast1Week),
                                     unit: "km",
                                     color: .blue)
                            
                            StatCard(title: "Last Month",
                                     value: String(format: "%.1f", viewModel.totalDistanceLast1Month),
                                     unit: "km",
                                     color: .green)
                            
                            StatCard(title: "Last 3 Months",
                                     value: String(format: "%.0f", viewModel.totalDistanceLast3Months),
                                     unit: "km",
                                     color: .orange)
                            
                            StatCard(title: "Last Year",
                                     value: String(format: "%.0f", viewModel.totalDistanceLast1Year),
                                     unit: "km",
                                     color: .purple)
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Monthly Chart
                    MonthlyActivityChart(data: viewModel.monthlyData)
                        .padding(.horizontal)
                    
                    // MARK: - Custom Date Range
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Custom Range")
                            .font(.headline)
                        
                        VStack(spacing: 10) {
                            DatePicker("Start Date", selection: $viewModel.selectedCustomStartDate, displayedComponents: .date)
                            DatePicker("End Date", selection: $viewModel.selectedCustomEndDate, displayedComponents: .date)
                        }
                        .onChange(of: viewModel.selectedCustomStartDate) { viewModel.updateCustomRangeStats() }
                        .onChange(of: viewModel.selectedCustomEndDate) { viewModel.updateCustomRangeStats() }
                        
                        Divider()
                        
                        HStack {
                            Text("Total Distance")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.2f km", viewModel.customRangeTotal))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    
                }
                .padding(.vertical)
            }
            .navigationTitle("Running Stats")
            .onAppear {
                viewModel.requestAuthorizationAndFetchData()
            }
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
