//
//  StepsAndFloorsView.swift
//  healthKitOverView
//
//  Created by taeni on 7/15/25.
//

import SwiftUI
import Combine

struct StepsAndFloorsView: View {
    @StateObject private var healthManager = HealthDataManager()
    @State private var activityData: ActivityData?
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 헤더 아이콘
                Image(systemName: "figure.walk")
                    .font(.system(size: 60))
                    .foregroundStyle(.green.gradient)
                
                Text("오늘의 활동")
                    .font(.title)
                    .fontWeight(.bold)
                
                // 메인 컨텐츠
                if let data = activityData {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 활동 카드들
                            HStack(spacing: 16) {
                                ActivityCard(
                                    icon: "figure.walk",
                                    title: "걸음 수",
                                    value: "\(Int(data.steps))",
                                    unit: "걸음",
                                    color: .blue,
                                    progress: min(data.steps / 10000, 1.0) // 목표 10,000걸음
                                )
                                
                                ActivityCard(
                                    icon: "stairs",
                                    title: "계단",
                                    value: "\(Int(data.floors))",
                                    unit: "층",
                                    color: .orange,
                                    progress: min(data.floors / 10, 1.0) // 목표 10층
                                )
                            }
                            
                            // 목표 달성 상태
                            VStack(spacing: 12) {
                                Text("목표 달성 현황")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                GoalProgressRow(
                                    title: "걸음 수 목표",
                                    current: Int(data.steps),
                                    goal: 10000,
                                    unit: "걸음",
                                    color: .blue
                                )
                                
                                GoalProgressRow(
                                    title: "계단 목표",
                                    current: Int(data.floors),
                                    goal: 10,
                                    unit: "층",
                                    color: .orange
                                )
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            
                            // 격려 메시지
                            MotivationCard(steps: data.steps, floors: data.floors)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.walk.motion")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("활동 데이터가 없습니다")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("iPhone을 가지고 걸어보세요!\n활동 데이터가 자동으로 기록됩니다")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                
                // 액션 버튼
                Button(action: loadActivityData) {
                    HStack {
                        if healthManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(healthManager.isLoading ? "로딩 중..." : "데이터 새로고침")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.green.gradient)
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
                
                Spacer()
            }
            .padding()
            .navigationTitle("걸음수 & 계단")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadActivityData()
            }
        }
    }
    
    private func loadActivityData() {
        healthManager.setLoading(true)
        healthManager.clearMessages()
        
        healthManager.fetchTodayActivityData()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    healthManager.setLoading(false)
                    
                    switch completion {
                    case .finished:
                        healthManager.setSuccess("활동 데이터를 성공적으로 로드했습니다!")
                    case .failure(let error):
                        healthManager.setError("데이터 로드 실패: \(error.localizedDescription)")
                    }
                },
                receiveValue: { data in
                    activityData = data
                }
            )
            .store(in: &cancellables)
    }
}

struct ActivityCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color.gradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

struct GoalProgressRow: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(Double(current) / Double(goal), 1.0)
    }
    
    private var isGoalAchieved: Bool {
        current >= goal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    if isGoalAchieved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    Text("\(current)/\(goal) \(unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(color.gradient)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
    }
}

struct MotivationCard: View {
    let steps: Double
    let floors: Double
    
    private var motivationMessage: (String, String, Color) {
        let stepsGoal = 10000.0
        let floorsGoal = 10.0
        
        if steps >= stepsGoal && floors >= floorsGoal {
            return ("🎉", "훌륭해요! 오늘 목표를 모두 달성했습니다!", .green)
        } else if steps >= stepsGoal {
            return ("🚶‍♂️", "걸음 수 목표 달성! 계단도 조금 더 올라보세요!", .blue)
        } else if floors >= floorsGoal {
            return ("🏃‍♂️", "계단 목표 달성! 걸음 수도 늘려보세요!", .orange)
        } else {
            return ("💪", "조금 더 활동해보세요! 목표까지 얼마 남지 않았어요!", .purple)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(motivationMessage.0)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("오늘의 한마디")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(motivationMessage.1)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(motivationMessage.2.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    StepsAndFloorsView()
}
