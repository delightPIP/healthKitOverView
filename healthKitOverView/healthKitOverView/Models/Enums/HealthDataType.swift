//
//  HealthDataType.swift
//  healthKitOverView
//
//  Created by taeni on 7/14/25.
//

enum HealthDataType: String, CaseIterable {
    case steps = "걸음 수"
    case flights = "계단 오르기"
    case heartRate = "심박수"
    case nutrition = "영양 정보"
    case weight = "체중"
    case sleep = "수면"
    
    var icon: String {
        switch self {
        case .steps:
            return "figure.walk"
        case .flights:
            return "figure.stairs"
        case .heartRate:
            return "heart.fill"
        case .nutrition:
            return "leaf.fill"
        case .weight:
            return "scalemass"
        case .sleep:
            return "bed.double.fill"
        }
    }
    
    var unit: String {
        switch self {
        case .steps:
            return "걸음"
        case .flights:
            return "층"
        case .heartRate:
            return "BPM"
        case .nutrition:
            return "kcal"
        case .weight:
            return "kg"
        case .sleep:
            return "시간"
        }
    }
}
