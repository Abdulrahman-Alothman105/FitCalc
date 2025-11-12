//
//  ResultView.swift
//  FitnessTracker
//
//  (تم تعديله) ليستخدم ألوان الهوية الجديدة + شريط متغير اللون
//

import SwiftUI

// 1: شاشة "الجسر" التي تربط البيانات
struct SummaryView: View {
    @AppStorage("lastWeight") private var savedWeight: Int = 0
    @AppStorage("lastHeight") private var savedHeight: Int = 0
    @AppStorage("lastCalories") private var savedCalories: Int = 0
    @AppStorage("lastBurned") private var savedBurned: Int = 0
    @AppStorage("lastIdeal") private var savedIdeal: Int = 0
    
    @AppStorage("goal_dailyLogStreak") private var goalDailyLogStreak: Int = 0
    @AppStorage("goal_withinCalStreak") private var goalWithinCalStreak: Int = 0
    @AppStorage("goal_burn300Streak") private var goalBurn300Streak: Int = 0

    var body: some View {
        if savedWeight == 0 && savedHeight == 0 {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack {
                    Spacer()
                    Text("Calculate Your Data To Show Your Result")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
            }
        } else {
            ResultView(
                consumed: savedCalories,
                burned: savedBurned,
                idealCalories: savedIdeal,
                weightKg: savedWeight,
                heightCm: savedHeight,
                daysCaloriesTracked: goalDailyLogStreak,
                daysIdealCaloriesReached: goalWithinCalStreak,
                daysBurn300: goalBurn300Streak
            )
        }
    }
}


// MARK: - Updated Pastel Theme & Helpers
// (تم حذف تعريفات الألوان المكررة من هنا)

struct WhiteCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
    }
}

// MARK: - Main Result Screen
struct ResultView: View {
    // Inputs
    var consumed: Int
    var burned: Int
    var idealCalories: Int
    var weightKg: Int
    var heightCm: Int

    // Goal counters
    var daysCaloriesTracked: Int
    var daysIdealCaloriesReached: Int
    var daysBurn300: Int

    // Derived
    private var remaining: Int { idealCalories - (consumed - burned) }
    private var netConsumed: Int { consumed - burned }
    
    private var gaugeProgress: Double {
        let maxLimit = Double(max(idealCalories, 1)) // (إصلاح) منع القسمة على صفر
        let currentAmount = Double(netConsumed)
        let val = currentAmount / maxLimit
        return min(max(val, 0.0), 1.2) // (إصلاح) اسمح له بتجاوز 1.0 قليلاً
    }
    
    private var gaugeEndAngle: Angle {
        // (إصلاح) تأكد أن القيمة لا تتجاوز 1.0 هنا
        return .degrees(180 + 180 * min(gaugeProgress, 1.0))
    }
    
    // --- (هذا هو التعديل 1: إضافة متغير لون الشريط) ---
    private var gaugeColor: Color {
        if gaugeProgress < 0.9 {
            return .pastelGreen // جيد
        }
        if gaugeProgress <= 1.0 {
            return .orange // تحذير (يمكن تغييره إلى .brandPrimary إذا أردت)
        }
        return .brandPrimary // تجاوز (لون الهوية)
    }
    // --- (نهاية التعديل 1) ---
    
    private var bmiValue: Double {
        let h = max(0.01, Double(heightCm)) / 100.0
        return Double(weightKg) / (h * h)
    }
    private var bmiClass: String {
        switch bmiValue {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }
    private var idealWeight: Double {
        let h = Double(heightCm)/100.0
        return 22.0 * h * h
    }
    
    private var bmiColor: Color {
        switch bmiClass {
        case "Underweight": return .bmiUnderweight
        case "Normal": return .bmiNormal
        case "Overweight": return .bmiOverweight
        case "Obese": return .red.opacity(0.8)
        default: return .gray
        }
    }

    
    // MARK: - New Subview for Counter Rows with a Colored Dot
    struct CounterRowWithDot: View {
        var title: String
        var value: Int
        var dotColor: Color
        
        var body: some View {
            HStack {
                Circle()
                    .fill(dotColor)
                    .frame(width: 10, height: 10)
                Text(title).font(.subheadline)
                Spacer()
                Text("\(value)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(dotColor)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Motivational Card Subview
    
    static let b1 = Color(hex: "#FFC9BD")
    static let b2 = Color(hex: "#FFF6C9")


    // MARK: - Motivational Card Subview (Static with Border, using System Color)
    struct MotivationalCard: View {
        let motivation: String
        
        var body: some View {
            VStack {
                Text(motivation)
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(gradient: Gradient(colors: [b1, b2]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            )
            .overlay(
                // Using .primary for a subtle border color
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
    }
    
    
    private var motivation: String {
            if remaining >= 200 {
                return "You’re under your goal, keep it up and stay on track!🚀"
            } else if remaining >= 0 {
                return "You’ve reached your goal for today, excellent balance and control!✅"
            } else if remaining >= -300 {
                return "You’re slightly over, a little activity can help even things out!🤍"
            } else {
                return "You’re over the limit today, take it easy and start fresh tomorrow!💪"
            }
        }


    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Result")
                    .font(.system(size: 32, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)

                // Calories Card
                WhiteCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "fork.knife.circle.fill")
                                .foregroundStyle(Color.textGrey)
                                .font(.title3)
                            Text("Calories")
                                .font(.headline)
                        }
                        Divider()
                        Text("")
                        
                        VStack(spacing: 12) {
                            
                            // 1. Chart
                            ZStack {
                                Arc(start: .degrees(180), end: .degrees(360))
                                    .stroke(Color.gray.opacity(0.15), style: StrokeStyle(lineWidth: 18, lineCap: .round))

                                // --- (هذا هو التعديل 2) ---
                                // استخدام اللون المتغير
                                Arc(start: .degrees(180), end: gaugeEndAngle)
                                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                                // --- (نهاية التعديل 2) ---

                                // Center Text
                                VStack {
                                    // --- (هذا هو التعديل 3) ---
                                    // استخدام اللون المتغير
                                    Text("\(max(0, remaining))")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(gaugeColor)
                                    // --- (نهاية التعديل 3) ---
                                    
                                    Text("Kcal Remaining")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .offset(y: 20)
                                
                            }
                            .frame(height: 160)
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                            // 2. Summary Row (Consumed, Ideal, Burned)
                            HStack {
                                Spacer()
                                VStack {
                                    Text("\(consumed) Kcal").font(.headline).foregroundStyle(Color.pastelPink)
                                    Text("Consumed").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack {
                                    Text("\(idealCalories) Kcal").font(.headline).foregroundStyle(Color.brandPrimary)
                                    Text("Ideal").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack {
                                    Text("\(burned) Kcal").font(.headline).foregroundStyle(Color.pastelGreen)
                                    Text("Burned").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }
                    }
                }

                // BMI Card
                WhiteCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundStyle(Color.textGrey)
                                .font(.title3)
                            Text("Body Mass Index")
                                .font(.headline)
                        }
                        Divider()
                        
                        HStack {
                            Text(String(format: "%.1f", bmiValue))
                                .font(.system(size: 25, weight: .semibold))
                                .foregroundStyle(.primary)

                            Spacer()
                            
                            Text(bmiClass)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(bmiColor.opacity(0.8))
                                )
                                .foregroundStyle(Color.textDark)
                        }
                        
                        Spacer()
                    }
                }
                
                // Ideal Weight Card
                WhiteCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "scalemass.fill")
                                .foregroundStyle(Color.textGrey)
                                .font(.title3)
                            Text("Ideal Weight")
                                .font(.headline)
                        }
                        
                        Divider()

                        VStack(alignment: .center, spacing: 6) {
                            Text(String(format: "%.1f kg", idealWeight))
                                .font(.system(size: 25, weight: .semibold))

                        
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                // Motivational statement
                MotivationalCard(motivation: motivation)
                
                // Goals Tracker
                WhiteCard {
                    VStack(alignment: .center, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(Color.white)
                            Text("Goals Tracker")
                                .font(.headline)
                                .bold()
                                .foregroundStyle(Color.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.textGrey)
                        )
                        
                        VStack(spacing: 16) {
                            CounterRowWithDot(title: "Calories tracked", value: daysCaloriesTracked, dotColor: .pastelPurple)
                            CounterRowWithDot(title: "Ideal calories reached", value: daysIdealCaloriesReached, dotColor: .brandPrimary)
                            CounterRowWithDot(title: "300+ kcal burned", value: daysBurn300, dotColor: .pastelGreen)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}


// Simple arc shape for the calories gauge
struct Arc: Shape {
    var start: Angle
    var end: Angle
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let radius = min(rect.midX, rect.midY) * 0.95
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                 radius: radius,
                 startAngle: start,
                 endAngle: end,
                 clockwise: false)
        return p
    }
}
