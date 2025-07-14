//
//  PermissionRequestView.swift
//  healthKitOverView
//
//  Created by taeni on 7/15/25.
//

import SwiftUI
import Combine

struct PermissionRequestView: View {
    @StateObject private var healthManager = HealthDataManager()
    @State private var cancellables = Set<AnyCancellable>()
    @Binding var hasPermission: Bool
    
    private let permissions = [
        PermissionInfo(
            icon: "ruler",
            title: "신장 데이터",
            description: "키 정보를 읽어와 건강 상태를 확인합니다",
            type: .read
        ),
        PermissionInfo(
            icon: "figure.walk",
            title: "걸음 수",
            description: "일일 활동량과 걸음 수를 추적합니다",
            type: .read
        ),
        PermissionInfo(
            icon: "stairs",
            title: "계단 오르기",
            description: "오른 계단 수를 통해 활동 강도를 측정합니다",
            type: .read
        ),
        PermissionInfo(
            icon: "heart.fill",
            title: "심박수",
            description: "심혈관 건강 상태를 모니터링합니다",
            type: .read
        ),
        PermissionInfo(
            icon: "leaf.fill",
            title: "영양 정보",
            description: "칼로리와 단백질 섭취량을 기록합니다",
            type: .write
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 헤더
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.red.gradient)
                    
                    VStack(spacing: 8) {
                        Text("HealthKit 권한 요청")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("건강 데이터를 안전하게 관리하기 위해\n다음 권한들이 필요합니다")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // 권한 목록
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(permissions, id: \.title) { permission in
                            PermissionRow(permission: permission)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // 하단 버튼 영역
                VStack(spacing: 16) {
                    if healthManager.isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.9)
                            Text("권한 요청 중...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 50)
                    } else {
                        Button(action: requestAllPermissions) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                Text("모든 권한 허용")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.blue.gradient)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(healthManager.isLoading)
                    }
                    
                    if let errorMessage = healthManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if let successMessage = healthManager.successMessage {
                        Text(successMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Text("권한은 iOS 설정 > 개인정보 보호 및 보안 > 건강에서\n언제든지 변경할 수 있습니다")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func requestAllPermissions() {
        healthManager.setLoading(true)
        healthManager.clearMessages()
        
        healthManager.requestAllAuthorizations()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    healthManager.setLoading(false)
                    
                    switch completion {
                    case .finished:
                        healthManager.setSuccess("모든 권한이 성공적으로 설정되었습니다!")
                        hasPermission = true
                        
                        // 2초 후 자동으로 메인 화면으로 이동
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            hasPermission = true
                        }
                        
                    case .failure(let error):
                        healthManager.setError("권한 요청 실패: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
}

struct PermissionRow: View {
    let permission: PermissionInfo
    
    var body: some View {
        HStack(spacing: 16) {
            // 아이콘
            ZStack {
                Circle()
                    .fill(permission.type == .read ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: permission.icon)
                    .font(.title2)
                    .foregroundColor(permission.type == .read ? .blue : .green)
            }
            
            // 설명
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(permission.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(permission.type.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(permission.type == .read ? Color.blue.opacity(0.2) : Color.green.opacity(0.2))
                        .foregroundColor(permission.type == .read ? .blue : .green)
                        .cornerRadius(4)
                }
                
                Text(permission.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PermissionInfo {
    let icon: String
    let title: String
    let description: String
    let type: PermissionType
}

enum PermissionType {
    case read, write
    
    var displayName: String {
        switch self {
        case .read: return "읽기"
        case .write: return "쓰기"
        }
    }
}

#Preview {
    PermissionRequestView(hasPermission: .constant(false))
}
