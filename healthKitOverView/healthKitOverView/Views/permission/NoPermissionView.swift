//
//  NoPermissionView.swift
//  healthKitOverView
//
//  Created by taeni on 7/15/25.
//

import SwiftUI

struct NoPermissionView: View {
    @Binding var hasPermission: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // 메인 일러스트레이션
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(.red.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red.gradient)
                    }
                    
                    VStack(spacing: 12) {
                        Text("권한이 필요합니다")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("HealthKit 데이터에 접근하려면\n건강 앱 권한이 필요합니다")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // 권한 정보 카드들
                VStack(spacing: 16) {
                    PermissionInfoCard(
                        icon: "book.fill",
                        title: "데이터 읽기",
                        description: "신장, 걸음수, 심박수 등의 건강 데이터를 안전하게 읽어옵니다",
                        color: .blue
                    )
                    
                    PermissionInfoCard(
                        icon: "pencil",
                        title: "데이터 쓰기",
                        description: "영양 정보를 건강 앱에 안전하게 저장합니다",
                        color: .green
                    )
                    
                    PermissionInfoCard(
                        icon: "lock.shield.fill",
                        title: "개인정보 보호",
                        description: "모든 데이터는 기기에만 저장되며 외부로 전송되지 않습니다",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 하단 액션 버튼들
                VStack(spacing: 12) {
                    Button(action: {
                        hasPermission = false // 권한 요청 화면으로 돌아가기
                    }) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                            Text("권한 설정하기")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.blue.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        openHealthAppSettings()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("설정에서 직접 변경")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    
                    Text("설정 > 개인정보 보호 및 보안 > 건강에서\n권한을 변경할 수 있습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func openHealthAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct PermissionInfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NoPermissionView(hasPermission: .constant(false))
}

#Preview("Dark Mode") {
    NoPermissionView(hasPermission: .constant(false))
        .preferredColorScheme(.dark)
}
