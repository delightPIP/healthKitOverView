//
//  HealthError.swift
//  healthKitOverView
//
//  Created by taeni on 7/14/25.
//

import Foundation

enum HealthError: Error, LocalizedError {
    case healthDataNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .healthDataNotAvailable:
            return "건강 데이터를 사용할 수 없습니다."
        }
    }
}
