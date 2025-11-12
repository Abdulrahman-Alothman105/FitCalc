//
//  Models.swift
//  FitnessTracker
//
//  يحتوي هذا الملف على نماذج البيانات المشتركة مثل الوجبات وإدخالات السجل.
//

import Foundation

// نموذج بيانات السجل
struct WeightEntry: Identifiable, Codable {
    var id = UUID()
    let date: Date
    
    // --- بيانات الكيلوجرام ---
    let weight: String
    let weightChange: String
    let weightDirection: ChangeDirection
    
    // --- بيانات السعرات ---
    let netCalories: String
    let idealCalories: String
    let calorieDifference: String
    let calorieDirection: ChangeDirection

    enum ChangeDirection: Codable {
        case up, down, none
    }
}

// --- (هذا هو الإصلاح) ---
// نموذج بيانات الوجبة
struct Meal: Identifiable, Codable { // (أضفنا Codable هنا)
    let id = UUID()
    var idNumber: Int
    var calories: Int
}
// --- (نهاية الإصلاح) ---

// نموذج بيانات مستوى النشاط
enum ActivityLevel: String, CaseIterable {
    case officeWork = "Low Activity"
    case lightExercise = "1–3 Days per Week"
    case moderateExercise = "3–5 Days per Week"
    case intenseExercise = "6–7 Days per Week"
    case veryIntense = "Very Intense Physical Work"

    var description: String { rawValue }
    var factor: Double {
        switch self {
        case .officeWork: return 1.2
        case .lightExercise: return 1.375
        case .moderateExercise: return 1.55
        case .intenseExercise: return 1.725
        case .veryIntense: return 1.9
        }
    }
}
