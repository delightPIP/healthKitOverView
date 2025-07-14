//
//  HeartRateData.swift
//  healthKitOverView
//
//  Created by taeni on 7/15/25.
//

import Foundation

struct HeartRateData: Identifiable {
    let id = UUID()
    let date: Date
    let heartRate: Double
}
