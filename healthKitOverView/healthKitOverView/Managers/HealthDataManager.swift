//
//  HealthDataManager.swift
//  healthKitOverView
//
//  Created by taeni on 7/15/25.
//

import Foundation
import HealthKit
import Combine

final class HealthDataManager: ObservableObject {
    let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var hasAllPermissions = false
    
    // MARK: - HealthKit 권한 요청 (모든 권한 통합)
    
    func requestAllAuthorizations() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self, HKHealthStore.isHealthDataAvailable() else {
                promise(.failure(HealthError.healthDataNotAvailable))
                return
            }
            
            let readTypes: Set<HKObjectType> = [
                HKQuantityType.quantityType(forIdentifier: .height)!,
                HKQuantityType.quantityType(forIdentifier: .stepCount)!,
                HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
                HKQuantityType.quantityType(forIdentifier: .heartRate)!
            ]
            
            let writeTypes: Set<HKSampleType> = [
                HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
                HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            ]
            
            self.healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                if let error = error {
                    promise(.failure(error))
                } else if !success {
                    promise(.failure(HealthError.healthDataNotAvailable))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func checkAllPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async {
                self.hasAllPermissions = false
            }
            return
        }
        
        let readTypes: [HKQuantityTypeIdentifier] = [
            .height,
            .stepCount,
            .flightsClimbed,
            .heartRate
        ]
        
        let writeTypes: [HKQuantityTypeIdentifier] = [
            .dietaryEnergyConsumed,
            .dietaryProtein
        ]
        
        var hasAllReadPermissions = true
        var hasAllWritePermissions = true
        
        // 읽기 권한 체크
        for identifier in readTypes {
            guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            let status = healthStore.authorizationStatus(for: quantityType)
            
            if status != .sharingAuthorized {
                hasAllReadPermissions = false
                break
            }
        }
        
        // 쓰기 권한 체크
        for identifier in writeTypes {
            guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            let status = healthStore.authorizationStatus(for: quantityType)
            
            if status != .sharingAuthorized {
                hasAllWritePermissions = false
                break
            }
        }
        
        DispatchQueue.main.async {
            self.hasAllPermissions = hasAllReadPermissions && hasAllWritePermissions
        }
    }
    
    
    // MARK: - 데이터 읽기
    
    func fetchHeight() -> AnyPublisher<Double?, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(HealthError.healthDataNotAvailable))
                return
            }
            
            let type = HKQuantityType.quantityType(forIdentifier: .height)!
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    promise(.failure(error))
                } else if let sample = samples?.first as? HKQuantitySample {
                    let cm = sample.quantity.doubleValue(for: HKUnit.meterUnit(with: .centi))
                    promise(.success(cm))
                } else {
                    promise(.success(nil))
                }
            }
            
            self.healthStore.execute(query)
        }
        .eraseToAnyPublisher()
    }
    
    func fetchTodaySteps() -> AnyPublisher<Double, Error> {
        fetchSumQuantity(
            identifier: .stepCount,
            unit: .count(),
            start: Calendar.current.startOfDay(for: Date()),
            end: Date()
        )
    }
    
    func fetchTodayFloors() -> AnyPublisher<Double, Error> {
        fetchSumQuantity(
            identifier: .flightsClimbed,
            unit: .count(),
            start: Calendar.current.startOfDay(for: Date()),
            end: Date()
        )
    }
    
    func fetchWeeklyHeartRate() -> AnyPublisher<[HeartRateData], Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(HealthError.healthDataNotAvailable))
                return
            }
            
            let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -7, to: end)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let results = samples?.compactMap { sample -> HeartRateData? in
                        guard let s = sample as? HKQuantitySample else { return nil }
                        let bpm = s.quantity.doubleValue(for: HKUnit(from: "count/min"))
                        return HeartRateData(date: s.startDate, heartRate: bpm)
                    } ?? []
                    promise(.success(results))
                }
            }
            self.healthStore.execute(query)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 데이터 쓰기
    
    func saveNutritionData(calories: Double, protein: Double) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(HealthError.healthDataNotAvailable))
                return
            }
            
            let now = Date()
            let caloriesSample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
                quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                start: now,
                end: now
            )
            
            let proteinSample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!,
                quantity: HKQuantity(unit: .gram(), doubleValue: protein),
                start: now,
                end: now
            )
            
            self.healthStore.save([caloriesSample, proteinSample]) { success, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 결합 데이터
    
    func fetchTodayActivityData() -> AnyPublisher<ActivityData, Error> {
        Publishers.Zip(fetchTodaySteps(), fetchTodayFloors())
            .map { ActivityData(steps: $0, floors: $1) }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 상태 관리
    
    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
    
    func setError(_ message: String?) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }
    
    func setSuccess(_ message: String?) {
        DispatchQueue.main.async {
            self.successMessage = message
        }
    }
    
    func clearMessages() {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }
    }
    
    // MARK: - 헬퍼: 합계 통계 쿼리
    
    private func fetchSumQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        start: Date,
        end: Date
    ) -> AnyPublisher<Double, Error> {
        Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(HealthError.healthDataNotAvailable))
                return
            }
            let type = HKQuantityType.quantityType(forIdentifier: identifier)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                    promise(.success(value))
                }
            }
            self.healthStore.execute(query)
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - 편의 메서드 (Authorization + Fetch)

extension HealthDataManager {
    func requestAuthorizationAndFetchHeight() -> AnyPublisher<Double?, Error> {
        requestAllAuthorizations()
            .flatMap { [weak self] _ in
                self?.fetchHeight() ?? Fail(error: HealthError.healthDataNotAvailable).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func requestAuthorizationAndFetchActivity() -> AnyPublisher<ActivityData, Error> {
        requestAllAuthorizations()
            .flatMap { [weak self] _ in
                self?.fetchTodayActivityData() ?? Fail(error: HealthError.healthDataNotAvailable).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func requestAuthorizationAndFetchHeartRate() -> AnyPublisher<[HeartRateData], Error> {
        requestAllAuthorizations()
            .flatMap { [weak self] _ in
                self?.fetchWeeklyHeartRate() ?? Fail(error: HealthError.healthDataNotAvailable).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
