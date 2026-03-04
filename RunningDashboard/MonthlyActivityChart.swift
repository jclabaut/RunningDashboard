import SwiftUI
import Charts

struct MonthlyActivityChart: View {
    let data: [(date: Date, distance: Double)]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Monthly Activity")
                .font(.headline)
                .padding(.bottom, 5)
            
            if data.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            } else {
                Chart {
                    ForEach(data, id: \.date) { item in
                        BarMark(
                            x: .value("Month", item.date, unit: .month),
                            y: .value("Distance", item.distance)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(3)
                    }
                }
                .frame(height: 250)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine()
                        AxisTick()
                        if let date = value.as(Date.self) {
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
