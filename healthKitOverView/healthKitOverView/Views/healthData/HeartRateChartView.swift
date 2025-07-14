//
//  HeartRateChartView.swift
//  healthKitOverView
//
//  Created by taeni on 7/15/25.
//
import SwiftUI
import Charts
import Combine

struct HeartRateChartView: View {
    @StateObject private var healthManager = HealthDataManager()
    @State private var heartRateData: [HeartRateData] = []
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 헤더 아이콘
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.red.gradient)
                
                Text("주간 심박수 분석")
                    .font(.title)
                    .fontWeight(.bold)
                
                ScrollView {
                    VStack(spacing: 20) {
                        if heartRateData.isEmpty {
                            // 빈 상태
                            VStack(spacing: 16) {
                                Image(systemName: "heart.text.square")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("심박수 데이터가 없습니다")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Apple Watch를 착용하고 활동하면\n심박수 데이터가 자동으로 수집됩니다")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        } else {
                            // 통계 카드들
                            HStack(spacing: 16) {
                                HeartRateStatCard(
                                    icon: "heart.circle.fill",
                                    title: "평균",
                                    value: String(format: "%.0f", averageHeartRate),
                                    unit: "bpm",
                                    color: .red
                                )
                                
                                HeartRateStatCard(
                                    icon: "arrow.up.heart.fill",
                                    title: "최고",
                                    value: String(format: "%.0f", maxHeartRate),
                                    unit: "bpm",
                                    color: .orange
                                )
                                
                                HeartRateStatCard(
                                    icon: "arrow.down.heart.fill",
                                    title: "최저",
                                    value: String(format: "%.0f", minHeartRate),
                                    unit: "bpm",
                                    color: .blue
                                )
                            }
                            
                            // 메인 차트
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("주간 심박수 변화")
                                        .font(.headline)
                                    
                                    Text("지난 7일간의 심박수 패턴을 확인하세요")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Chart(heartRateData) { data in
                                    LineMark(
                                        x: .value("날짜", data.date),
                                        y: .value("심박수", data.heartRate)
                                    )
                                    .foregroundStyle(.red.gradient)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    .symbol(.circle)
                                    .symbolSize(60)
                                    
                                    AreaMark(
                                        x: .value("날짜", data.date),
                                        y: .value("심박수", data.heartRate)
                                    )
                                    .foregroundStyle(.red.opacity(0.15))
                                }
                                .frame(height: 280)
                                .chartYAxis {
                                    AxisMarks(position: .leading) { value in
                                        AxisValueLabel {
                                            if let bpm = value.as(Double.self) {
                                                Text("\(Int(bpm))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        AxisGridLine(stroke: .init(lineWidth: 0.5))
                                        AxisTick(stroke: .init(lineWidth: 0.5))
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(position: .bottom) { value in
                                        AxisValueLabel {
                                            if let date = value.as(Date.self) {
                                                Text(date, format: .dateTime.month().day())
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        AxisGridLine(stroke: .init(lineWidth: 0.5))
                                        AxisTick(stroke: .init(lineWidth: 0.5))
                                    }
                                }
                                .chartYScale(domain: chartYScale)
                                .chartBackground { chartProxy in
                                    Rectangle()
                                        .fill(.clear)
                                        .border(Color(.systemGray4), width: 0.5)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            
                            // 심박수 분석 카드
                            HeartRateAnalysisCard(
                                averageHeartRate: averageHeartRate,
                                dataCount: heartRateData.count
                            )
                            
                            // 건강 팁 카드
                            HeartRateHealthTipCard()
                        }
                    }
                }
                
                // 액션 버튼
                Button(action: loadHeartRateData) {
                    HStack {
                        if healthManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(healthManager.isLoading ? "데이터 로딩 중..." : "심박수 데이터 새로고침")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.red.gradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(healthManager.isLoading)
                
                // 상태 메시지
                if let errorMessage = healthManager.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                if let successMessage = healthManager.successMessage {
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("심박수 차트")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadHeartRateData()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var averageHeartRate: Double {
        guard !heartRateData.isEmpty else { return 0 }
        let total = heartRateData.reduce(0) { $0 + $1.heartRate }
        return total / Double(heartRateData.count)
    }
    
    private var maxHeartRate: Double {
        heartRateData.map(\.heartRate).max() ?? 0
    }
    
    private var minHeartRate: Double {
        heartRateData.map(\.heartRate).min() ?? 0
    }
    
    private var chartYScale: ClosedRange<Double> {
        guard !heartRateData.isEmpty else { return 60...100 }
        let min = minHeartRate
        let max = maxHeartRate
        let padding = (max - min) * 0.15
        return (min - padding)...(max + padding)
    }
    
    // MARK: - Methods
    
    private func loadHeartRateData() {
        healthManager.setLoading(true)
        healthManager.clearMessages()
        
        healthManager.fetchWeeklyHeartRate()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    healthManager.setLoading(false)
                    
                    switch completion {
                    case .finished:
                        if heartRateData.isEmpty {
                            healthManager.setError("심박수 데이터가 없습니다. Apple Watch를 착용하고 활동해보세요.")
                        } else {
                            healthManager.setSuccess("심박수 데이터를 성공적으로 로드했습니다!")
                        }
                    case .failure(let error):
                        healthManager.setError("데이터 로드 실패: \(error.localizedDescription)")
                    }
                },
                receiveValue: { data in
                    heartRateData = data
                }
            )
            .store(in: &cancellables)
    }
}

struct HeartRateStatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HeartRateAnalysisCard: View {
    let averageHeartRate: Double
    let dataCount: Int
    
    private var healthStatus: (String, String, Color) {
        switch averageHeartRate {
        case 60...100:
            return ("💚", "정상 범위의 심박수입니다", .green)
        case 101...120:
            return ("💛", "약간 높은 심박수입니다", .yellow)
        case 0..<60:
            return ("💙", "낮은 심박수입니다", .blue)
        default:
            return ("❤️", "높은 심박수입니다", .red)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(healthStatus.0)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("심박수 분석")
                        .font(.headline)
                    
                    Text(healthStatus.1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("데이터 요약")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("• 측정 횟수: \(dataCount)회")
                    Spacer()
                }
                
                HStack {
                    Text("• 평균 심박수: \(String(format: "%.0f", averageHeartRate)) bpm")
                    Spacer()
                }
                
                HStack {
                    Text("• 정상 범위: 60-100 bpm")
                    Spacer()
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(healthStatus.2.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HeartRateHealthTipCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.pink)
                
                Text("심박수 건강 팁")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• 규칙적인 유산소 운동은 심박수를 안정화시킵니다")
                Text("• 스트레스 관리는 심혈관 건강에 중요합니다")
                Text("• 충분한 수면은 정상 심박수 유지에 도움됩니다")
                Text("• 카페인과 알코올 섭취를 적당히 조절하세요")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.pink.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    HeartRateChartView()
}
