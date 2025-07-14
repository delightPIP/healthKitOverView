//
//  MainTabView.swift
//  healthKitOverView
//
//  Created by taeni on 7/15/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("신장 데이터", systemImage: "ruler") {
                HeightDataView()
            }

            Tab("걸음수/계단", systemImage: "figure.walk") {
                StepsAndFloorsView()
            }

            Tab("영양 데이터", systemImage: "leaf.fill") {
                NutritionDataView()
            }

            Tab("심박수 차트", systemImage: "heart.fill") {
                HeartRateChartView()
            }
        }
    }
}
