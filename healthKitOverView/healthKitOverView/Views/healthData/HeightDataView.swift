//
//  HeightDataView.swift
//  healthKitOverView
//
//  Created by taeni on 7/15/25.
//

import SwiftUI
import Combine

struct HeightDataView: View {
    @StateObject private var healthManager = HealthDataManager()
    @State private var height: Double?
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 헤더 아이콘
                Image(systemName: "ruler")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue.gradient)
                
                Text("신장 데이터")
                    .font(.title)
                    .fontWeight(.bold)
                
                // 메인 컨텐츠
                if let height = height {
                    VStack(spacing: 16) {
                        // 신장 표시 카드
                        VStack(spacing: 8) {
                            Text("현재 신장")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("\(height, specifier: "%.1f")")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(.blue.gradient)
                                
                                Text("cm")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)
                        
                        // 추가 정보
                        VStack(spacing: 12) {
                            InfoRow(
                                icon: "checkmark.circle.fill",
                                title: "데이터 상태",
                                value: "최신",
                                color: .green
                            )
                            
                            InfoRow(
                                icon: "clock.fill",
                                title: "마지막 업데이트",
                                value: "건강 앱에서 확인",
                                color: .orange
                            )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("신장 데이터가 없습니다")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("건강 앱에서 신장 정보를 추가해주세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                
                // 액션 버튼
                Button(action: loadHeightData) {
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
                    .background(.blue.gradient)
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
            .navigationTitle("신장 데이터")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadHeightData()
            }
        }
    }
    
    private func loadHeightData() {
        healthManager.setLoading(true)
        healthManager.clearMessages()
        
        healthManager.fetchHeight()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    healthManager.setLoading(false)
                    
                    switch completion {
                    case .finished:
                        if height != nil {
                            healthManager.setSuccess("신장 데이터를 성공적으로 로드했습니다!")
                        }
                    case .failure(let error):
                        healthManager.setError("데이터 로드 실패: \(error.localizedDescription)")
                    }
                },
                receiveValue: { heightValue in
                    height = heightValue
                }
            )
            .store(in: &cancellables)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    HeightDataView()
}

