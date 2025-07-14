//
//  ContentView.swift
//  healthKitOverView
//
//  Created by taeni on 7/13/25.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    
    @StateObject private var healthManager = HealthDataManager()
    @State private var showPermissionRequest = true
    @State private var isCheckingPermission = true
    
    var body: some View {
        if isCheckingPermission {
            PermissionCheckingView()
                .onAppear {
                    checkPermissionStatus()
                }
        } else if !healthManager.hasAllPermissions && showPermissionRequest {
            PermissionRequestView(hasPermission: $healthManager.hasAllPermissions)
                .onReceive(healthManager.$hasAllPermissions) { hasPermission in
                    if hasPermission {
                        showPermissionRequest = false
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    checkPermissionStatus()
                }
        } else if !healthManager.hasAllPermissions {
            NoPermissionView(hasPermission: $showPermissionRequest)
        } else {
            MainTabView()
        }
    }

    
    private func checkPermissionStatus() {
        isCheckingPermission = true
        
        // HealthDataManager의 checkAllPermissions 사용
        healthManager.checkAllPermissions()
        
        // 잠시 후 로딩 상태 해제 (권한 체크 완료)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCheckingPermission = false
        }
    }
    
    struct PermissionCheckingView: View {
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red.gradient)
                
                Text("권한 확인 중...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("HealthKit 권한 상태를 확인하고 있습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    ContentView()
}

