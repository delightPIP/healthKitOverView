//
//  NutritionDataView.swift
//  healthKitOverView
//
//  Created by taeni on 7/15/25.
//

import SwiftUI
import Combine

struct NutritionDataView: View {
    @StateObject private var healthManager = HealthDataManager()
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var cancellables = Set<AnyCancellable>()
    @State private var savedEntries: [NutritionEntry] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 헤더 아이콘
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green.gradient)
                
                Text("영양 데이터 입력")
                    .font(.title)
                    .fontWeight(.bold)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 입력 폼
                        VStack(spacing: 16) {
                            Text("오늘 섭취한 영양소를 기록해보세요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            NutritionInputField(
                                icon: "flame.fill",
                                title: "칼로리",
                                placeholder: "예: 500",
                                unit: "kcal",
                                text: $calories,
                                color: .red
                            )
                            
                            NutritionInputField(
                                icon: "drop.fill",
                                title: "단백질",
                                placeholder: "예: 25",
                                unit: "g",
                                text: $protein,
                                color: .blue
                            )
                            
                            Button(action: saveNutritionData) {
                                HStack {
                                    if healthManager.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    Text(healthManager.isLoading ? "저장 중..." : "영양 데이터 저장")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isFormValid ? .green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!isFormValid || healthManager.isLoading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        
                        // 오늘의 영양 요약 (모의 데이터)
                        if !savedEntries.isEmpty {
                            VStack(spacing: 16) {
                                Text("오늘 기록된 영양소")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 20) {
                                    NutritionSummaryCard(
                                        icon: "flame.fill",
                                        title: "총 칼로리",
                                        value: "\(totalCalories)",
                                        unit: "kcal",
                                        color: .red
                                    )
                                    
                                    NutritionSummaryCard(
                                        icon: "drop.fill",
                                        title: "총 단백질",
                                        value: String(format: "%.1f", totalProtein),
                                        unit: "g",
                                        color: .blue
                                    )
                                }
                                
                                // 최근 기록 목록
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("최근 기록")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    ForEach(savedEntries.reversed().prefix(3), id: \.id) { entry in
                                        NutritionEntryRow(entry: entry)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        
                        // 팁 카드
                        NutritionTipCard()
                    }
                }
                
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
            .navigationTitle("영양 데이터")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private var isFormValid: Bool {
        !calories.isEmpty && !protein.isEmpty &&
        Double(calories) != nil && Double(protein) != nil
    }
    
    private var totalCalories: Int {
        savedEntries.reduce(0) { $0 + Int($1.calories) }
    }
    
    private var totalProtein: Double {
        savedEntries.reduce(0) { $0 + $1.protein }
    }
    
    private func saveNutritionData() {
        guard let caloriesValue = Double(calories),
              let proteinValue = Double(protein) else {
            healthManager.setError("올바른 숫자를 입력해주세요")
            return
        }
        
        healthManager.setLoading(true)
        healthManager.clearMessages()
        
        healthManager.saveNutritionData(calories: caloriesValue, protein: proteinValue)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    healthManager.setLoading(false)
                    
                    switch completion {
                    case .finished:
                        let entry = NutritionEntry(
                            calories: caloriesValue,
                            protein: proteinValue,
                            timestamp: Date()
                        )
                        savedEntries.append(entry)
                        
                        healthManager.setSuccess("영양 데이터가 성공적으로 저장되었습니다!")
                        calories = ""
                        protein = ""
                        hideKeyboard()
                        
                    case .failure(let error):
                        healthManager.setError("데이터 저장 실패: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}

struct NutritionInputField: View {
    let icon: String
    let title: String
    let placeholder: String
    let unit: String
    @Binding var text: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .cornerRadius(4)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
        }
    }
}

struct NutritionSummaryCard: View {
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
                    .font(.title2)
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

struct NutritionEntryRow: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(entry.calories))kcal · \(entry.protein, specifier: "%.1f")g")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(entry.timestamp, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

struct NutritionTipCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("영양 기록 팁")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• 식사 후 바로 기록하면 정확도가 높아집니다")
                Text("• 포장 식품의 영양 정보를 참고하세요")
                Text("• 규칙적인 기록으로 건강한 식습관을 만들어보세요")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

struct NutritionEntry: Identifiable {
    let id = UUID()
    let calories: Double
    let protein: Double
    let timestamp: Date
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NutritionDataView()
}
