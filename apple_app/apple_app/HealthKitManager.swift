//
//  HealthKitManager.swift
//  FitnessTracker
//
//  (تم تعديله) ليجلب البيانات لتاريخ محدد
//

import Combine
import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    
    let healthStore = HKHealthStore()
    @Published var activeCalories: Double = 0
    
    init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit غير مدعوم على هذا الجهاز.")
            return
        }
    }
    
    /// 1. طلب الإذن من المستخدم
    func requestAuthorization() {
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if let error = error {
                print("خطأ في طلب إذن HealthKit: \(error.localizedDescription)")
                return
            }
            
            if success {
                print("تم الحصول على إذن HealthKit بنجاح.")
                // (لن نقوم بالجلب تلقائياً، HomeView سيطلب ذلك)
            } else {
                print("لم يتم منح إذن HealthKIt.")
            }
        }
    }
    
    // --- (هذا هو التعديل الرئيسي) ---
    /// 2. جلب بيانات السعرات الحرارية المحروقة "ليوم محدد"
    func fetchActiveCalories(for date: Date) { // (أصبح يستقبل تاريخ)
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            print("نوع بيانات السعرات الحرارية النشطة غير متاح.")
            return
        }
        
        // إنشاء نطاق زمني "لليوم المحدد" (من 12 ص حتى 12 ص اليوم التالي)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        // (إصلاح) يجب أن يكون حتى نهاية اليوم (بداية اليوم التالي)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        // إنشاء الاستعلام (Query)
        let query = HKStatisticsQuery(quantityType: energyType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { [weak self] (_, result, error) in
            
            if let error = error {
                print("خطأ في جلب بيانات السعرات: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.activeCalories = 0 // تصفير العداد عند الخطأ
                }
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("لم يتم العثور على بيانات سعرات لهذا اليوم: \(date.formatted())")
                DispatchQueue.main.async {
                    self?.activeCalories = 0 // تصفير العداد إذا لا توجد بيانات
                }
                return
            }
            
            // تحويل النتيجة إلى "سعرة حرارية" (kcal)
            let calories = sum.doubleValue(for: .kilocalorie())
            
            // تحديث المتغير المنشور
            DispatchQueue.main.async {
                self?.activeCalories = calories
                print("تم التحديث: \(calories) سعرة حرارية محروقة.")
            }
        }
        
        healthStore.execute(query)
    }
    // --- (نهاية التعديل) ---
}
