//
//  HomeView.swift
//  FitnessTracker
//
//  (تم تعديله) لإصلاح منطق حساب الأهداف (Streaks) ليتم تقييمه مع كل حفظ
//

import SwiftUI

// enum لتتبع نمط الإدخال
enum CalorieInputMode {
    case auto, manual
}

struct HomeView: View {
    @Binding var selectedTab: Int
    
    @State private var selectedDate: Date = Date()

    @State private var weight: Int = 60
    @State private var height: Int = 170
    @State private var age: Int = 25
    @State private var gender: String = "Male"
    @State private var selectedActivity: ActivityLevel = .officeWork
    @State private var meals: [Meal] = []
    @State private var newMealCalories: String = ""
    
    @StateObject private var healthManager = HealthKitManager()
    
    @State private var calorieInputMode: CalorieInputMode = .auto
    @State private var manualCaloriesBurned: Int = 0
    
    
    @FocusState private var isMealFieldFocused: Bool

    let genders = ["Male", "Female"]

    var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    // persistent storage keys
    @AppStorage("lastWeight") private var savedWeight: Int = 0
    @AppStorage("lastHeight") private var savedHeight: Int = 0
    @AppStorage("lastBMI") private var savedBMI: Double = 0
    @AppStorage("lastCalories") private var savedCalories: Int = 0
    @AppStorage("lastBurned") private var savedBurned: Int = 0
    @AppStorage("lastIdeal") private var savedIdeal: Int = 0
    @AppStorage("mealsDictionary") private var mealsDictionaryData: Data = Data()
    @AppStorage("savedTargetWeight") private var savedTargetWeight: Double = 0.0
    @AppStorage("historyLog") private var historyLogData: Data = Data()

    // --- (هذا هو التعديل 1: متغيرات جديدة لتتبع الأهداف) ---
    // (يستخدم لتتبع "Daily Log Streak")
    @AppStorage("lastSavedDate") private var lastSavedDate: String = ""
    // (جديد) يستخدم لتتبع "Ideal calories reached"
    @AppStorage("lastWithinCalStreakDate") private var lastWithinCalStreakDate: String = ""
    // (جديد) يستخدم لتتبع "300+ kcal burned"
    @AppStorage("lastBurn300StreakDate") private var lastBurn300StreakDate: String = ""
    // --- (نهاية التعديل 1) ---

    // Goals / streaks
    @AppStorage("goal_idealReached") private var goalIdealReached: Bool = false
    @AppStorage("goal_dailyLogStreak") private var goalDailyLogStreak: Int = 0
    @AppStorage("goal_withinCalStreak") private var goalWithinCalStreak: Int = 0
    @AppStorage("goal_burn300Streak") private var goalBurn300Streak: Int = 0
    
    
    var selectedDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }

    
    var caloriesBurned: Double {
        switch calorieInputMode {
        case .auto:
            return healthManager.activeCalories
        case .manual:
            return Double(manualCaloriesBurned)
        }
    }
    
    var netCalories: Double { Double(totalCalories) - caloriesBurned }

    
    var idealCalories: Double {
        if gender == "Male" {
            return (10 * Double(weight) + 6.25 * Double(height) - 5 * Double(age) + 5) * selectedActivity.factor
        } else {
            return (10 * Double(weight) + 6.25 * Double(height) - 5 * Double(age) - 161) * selectedActivity.factor
        }
    }
    var remainingCalories: Double { idealCalories - netCalories }
    var bmi: Double {
        let h = Double(height) / 100.0
        guard h > 0 else { return 0 }
        return Double(weight) / (h * h)
    }
    var idealWeight: Double {
        let h = Double(height) / 100.0
        return 22.0 * h * h
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        WeeklyCalendarView(selectedDate: $selectedDate)
                            .padding(.top)
                            .padding(.horizontal)

                        
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                MetricInputCard(
                                    title: "Height",
                                    iconName: "ruler",
                                    unit: "cm",
                                    value: $height,
                                    range: 100...220,
                                    iconColor: .pastelBlue
                                )
                                
                                MetricInputCard(
                                    title: "Weight",
                                    iconName: "scalemass",
                                    unit: "kg",
                                    value: $weight,
                                    range: 30...200,
                                    iconColor: .pastelGreen
                                )
                            }
                            
                            MetricInputCard(
                                title: "Age",
                                iconName: "person.badge.clock",
                                unit: "years",
                                value: $age,
                                range: 10...100,
                                iconColor: .pastelPink
                            )
                        }
                        .padding(.horizontal)
                        
                        GenderInputCard(gender: $gender)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .font(.title3)
                                    .foregroundColor(.pastelGreen)
                                    .frame(width: 25)
                                Text("Meals for: \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.headline)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                            }
                            
                            ForEach(meals) { meal in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Meal \(meal.idNumber)")
                                            .fontWeight(.medium)
                                        Text("\(meal.calories) kcal").font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        meals.removeAll { $0.id == meal.id }
                                        updateMealNumbers()
                                        saveMealsForSelectedDate()
                                    } label: {
                                        Image(systemName: "trash").foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(10)
                            }

                            HStack {
                                TextField("Calories", text: $newMealCalories)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .focused($isMealFieldFocused)
                                    .submitLabel(.done)
                                    .onChange(of: newMealCalories) { _, newValue in
                                        newMealCalories = newValue.filter { $0.isNumber }
                                    }
                                    .onSubmit {
                                        addMeal()
                                        // إغلاق الكيبورد بعد الإضافة
                                        isMealFieldFocused = false
                                    }

                                Button(action: {
                                    addMeal()
                                    // إغلاق الكيبورد بعد الإضافة
                                    isMealFieldFocused = false
                                }) {
                                    Text("Add")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                        .background(Color.brandPrimary)
                                        .cornerRadius(10)
                                }
                                .disabled(newMealCalories.isEmpty)
                            }

                            Divider()
                                .padding(.top, 4)

                            HStack {
                                Text("Total Calories")
                                    .font(.headline)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Text("\(totalCalories) kcal")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.brandPrimary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        ActivityInputCard(
                            calorieInputMode: $calorieInputMode,
                            manualCalories: $manualCaloriesBurned,
                            autoCalories: healthManager.activeCalories,
                            selectedActivity: $selectedActivity,
                            onRefresh: {
                                healthManager.fetchActiveCalories(for: selectedDate)
                            }
                        )

                        Button(action: {
                            saveResults()
                            selectedTab = 1
                        }) {
                            Text("Calculate")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.brandPrimary)
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Calculator")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .opacity(0)
                            .disabled(true)
                    }
                }
                .onAppear {
                    healthManager.requestAuthorization()
                    loadMealsForSelectedDate()
                }
                .onChange(of: selectedDate) { _, _ in
                    loadMealsForSelectedDate()
                }
            }
        }
    }
    
     // --- دوال الحفظ ---
    
     func loadMealsForSelectedDate() {
        let decoder = JSONDecoder()
        guard let dictionary = try? decoder.decode([String: [Meal]].self, from: mealsDictionaryData) else {
            self.meals = []
            return
        }
        self.meals = dictionary[selectedDateKey] ?? []
        healthManager.fetchActiveCalories(for: selectedDate)
     }
    
     func saveMealsForSelectedDate() {
         let decoder = JSONDecoder()
         var dictionary = (try? decoder.decode([String: [Meal]].self, from: mealsDictionaryData)) ?? [:]
         dictionary[selectedDateKey] = self.meals
         
         let encoder = JSONEncoder()
         if let encodedDictionary = try? encoder.encode(dictionary) {
             mealsDictionaryData = encodedDictionary
         }
     }
    
     func addMeal() {
         guard let calories = Int(newMealCalories), calories > 0 else { return }
         let mealNumber = meals.count + 1
         let meal = Meal(idNumber: mealNumber, calories: calories)
         meals.append(meal)
         newMealCalories = ""
         saveMealsForSelectedDate()
     }

     func updateMealNumbers() {
         for i in 0..<meals.count {
             meals[i].idNumber = i + 1
         }
     }
     
     private func getDirection(_ value: Double) -> WeightEntry.ChangeDirection {
         if value > 0.1 { return .up }
         if value < -0.1 { return .down }
         return .none
     }
    
     private func formatChange(_ value: Double, unit: String) -> String {
         if abs(value) < 0.1 {
             return "0 Kcal"
         }
         let sign = value > 0.1 ? "+" : ""
         return String(format: "%@%.0f %@", sign, value, unit)
     }

     // --- (هذا هو التعديل 2: دالة الحفظ الرئيسية) ---
     private func saveResults() {
         
         // 1. حفظ بيانات شاشة "Result" (دائماً)
         savedWeight = weight
         savedHeight = height
         savedBMI = bmi
         savedTargetWeight = idealWeight
         savedCalories = totalCalories
         savedBurned = Int(caloriesBurned)
         savedIdeal = Int(idealCalories)

         let today = Date()
         let todayString = ISO8601DateFormatter().string(from: today)
         let calendar = Calendar.current

         // 2. تحديث الأهداف (Streaks) - (فقط إذا كان اليوم المختار هو "اليوم")
         if calendar.isDateInToday(selectedDate) {
             
             // --- 2.1 Daily Log Streak ---
             // (هذا العداد يزيد فقط *أول مرة* تحفظ فيها في اليوم)
             if lastSavedDate.isEmpty || !calendar.isDateInToday(dateFromISO8601(lastSavedDate)) {
                 goalDailyLogStreak += 1
                 lastSavedDate = todayString // Mark that we have saved today
             }

             // --- 2.2 Calorie Limit Streak (يتم تقييمه كل مرة) ---
             if remainingCalories >= 0 {
                 // المستخدم نجح اليوم
                 // هل هذه أول مرة ينجح فيها اليوم؟
                 if lastWithinCalStreakDate.isEmpty || !calendar.isDateInToday(dateFromISO8601(lastWithinCalStreakDate)) {
                     // هل كان نجاح الأمس مسجلاً؟ (للاستمرار في الـ streak)
                     if !lastWithinCalStreakDate.isEmpty && calendar.isDate(dateFromISO8601(lastWithinCalStreakDate), inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
                         goalWithinCalStreak += 1 // استمرار الـ streak
                     } else {
                         goalWithinCalStreak = 1 // streak جديد
                     }
                     lastWithinCalStreakDate = todayString // سجل نجاح اليوم
                 }
             } else {
                 // المستخدم فشل اليوم
                 goalWithinCalStreak = 0
                 lastWithinCalStreakDate = "" // مسح تاريخ النجاح (ليتمكن من المحاولة غداً)
             }

             // --- 2.3 Burn 300 Streak (يتم تقييمه كل مرة) ---
             if caloriesBurned >= 300 {
                 // المستخدم نجح اليوم
                 // هل هذه أول مرة ينجح فيها اليوم؟
                 if lastBurn300StreakDate.isEmpty || !calendar.isDateInToday(dateFromISO8601(lastBurn300StreakDate)) {
                     // هل كان نجاح الأمس مسجلاً؟
                     if !lastBurn300StreakDate.isEmpty && calendar.isDate(dateFromISO8601(lastBurn300StreakDate), inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
                         goalBurn300Streak += 1 // استمرار الـ streak
                     } else {
                         goalBurn300Streak = 1 // streak جديد
                     }
                     lastBurn300StreakDate = todayString // سجل نجاح اليوم
                 }
             } else {
                 // المستخدم فشل اليوم
                 goalBurn300Streak = 0
                 lastBurn300StreakDate = "" // مسح تاريخ النجاح
             }
             
             // 2.4 Ideal Weight Goal (يتم تقييمه كل مرة)
             if abs(Double(weight) - idealWeight) <= 1.0 {
                 goalIdealReached = true
             }
         }
         
         // 3. حفظ بيانات شاشة "History" (دائماً)
         let decoder = JSONDecoder()
         var currentEntries = (try? decoder.decode([WeightEntry].self, from: historyLogData)) ?? []
         
         if let index = currentEntries.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
             currentEntries.remove(at: index)
         }

         let previousEntry = currentEntries.first
         let previousWeightValue: Double
         if let lastWeightString = previousEntry?.weight {
             previousWeightValue = Double(lastWeightString.replacingOccurrences(of: " Kg", with: "")) ?? Double(weight)
         } else {
             previousWeightValue = Double(weight)
         }
         let weightChange = Double(weight) - previousWeightValue

         let calorieDifferenceValue = netCalories - idealCalories
         let differenceDirection = getDirection(calorieDifferenceValue)
         let calorieDifferenceString = formatChange(calorieDifferenceValue, unit: "Kcal")

         let newEntry = WeightEntry(
             date: selectedDate,
             weight: String(format: "%.1f Kg", Double(weight)),
             weightChange: formatChange(weightChange, unit: "Kg"),
             weightDirection: getDirection(weightChange),
             
             netCalories: String(format: "%.0f Kcal", netCalories),
             idealCalories: String(format: "%.0f Kcal", idealCalories),
             calorieDifference: calorieDifferenceString,
             calorieDirection: differenceDirection
         )
         
         currentEntries.insert(newEntry, at: 0)
         
         let encoder = JSONEncoder()
         if let encodedData = try? encoder.encode(currentEntries) {
             historyLogData = encodedData
         }
         
         saveMealsForSelectedDate()
     }
     // --- (نهاية التعديل) ---

     private func dateFromISO8601(_ iso: String) -> Date {
         ISO8601DateFormatter().date(from: iso) ?? Date.distantPast
     }
}

// MARK: - شريط الأسبوع (تم تعديل الألوان)

struct WeeklyCalendarView: View {
    @Binding var selectedDate: Date
    @State private var week: [Date] = []
    
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(week, id: \.self) { day in
                    DayCell(
                        day: day,
                        isSelected: isSameDay(day, selectedDate),
                        isToday: isSameDay(day, Date())
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedDate = day
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .frame(height: 70)
        .onAppear {
            self.week = generateWeek()
        }
    }
    
    func generateWeek() -> [Date] {
        var week: [Date] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in -3...3 {
             if let date = calendar.date(byAdding: .day, value: i, to: today) {
                week.append(date)
            }
        }
        return week
    }
}

struct DayCell: View {
    let day: Date
    let isSelected: Bool
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text(day.formatted(.dateTime.weekday(.short)))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : (isToday ? .brandPrimary : .textSecondary))
            
            Text(day.formatted(.dateTime.day()))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .textPrimary : .textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isSelected ? Color.brandPrimary : Color(.systemGray5).opacity(0.6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday && !isSelected ? Color.brandPrimary : Color.clear, lineWidth: 2)
        )
    }
}


// MARK: - البطاقات المخصصة لـ HomeView

struct MetricInputCard: View {
    let title: String
    let iconName: String
    let unit: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let iconColor: Color

    @State private var showSheet = false
    @State private var tempValue: Int = 0

    var body: some View {
        Button(action: {
            tempValue = value
            showSheet = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    //DELETE
                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundColor(iconColor)
                        .frame(width: 25)
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(unit)
                        .font(.headline)
                        .foregroundColor(.textSecondary)
                        .padding(.bottom, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 90)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showSheet) {
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        value = tempValue
                        showSheet = false
                    }
                    .padding()
                    .fontWeight(.bold)
                }

                Picker(selection: $tempValue, label: Text(title)) {
                    ForEach(range, id: \.self) { i in
                        Text("\(i)").tag(i)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .labelsHidden()
                Spacer()
            }
            .presentationDetents([.fraction(0.4)])
        }
    }
}


// EDIT VERSION
// ...

struct GenderInputCard: View {
    // 1. iconColor is kept but not used for the picker's background
    let iconColor: Color = Color(hex: "#D9D9D9")
    @Binding var gender: String
    // 2. We use the genders array defined in HomeView, but redefine here for self-containment
    let genders = ["Male", "Female"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.fill")
                    .font(.title3)
                    // You were using Color(hex: "#C3A5FF") for the icon, which is a purple/pastel theme
                    .foregroundColor(Color(hex: "#C3A5FF"))
                    .frame(width: 25)
                Text("Gender")
                    .font(.headline)
                    .foregroundColor(.textSecondary)
                Spacer()
            }
            
            // ⭐ MODIFIED: Replaced custom HStack/Buttons with Segmented Picker ⭐
            Picker("Gender Selection", selection: $gender.animation(.easeInOut(duration: 0.2))) {
                ForEach(genders, id: \.self) { g in
                    Text(g)
                }
            }
            .pickerStyle(.segmented)
            // ------------------------------------------------------------------
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}


// ... (ActivityInputCard remains unchanged)

struct ActivityInputCard: View {
    @Binding var calorieInputMode: CalorieInputMode
    @Binding var manualCalories: Int
    
    var autoCalories: Double
    @Binding var selectedActivity: ActivityLevel
    var onRefresh: () -> Void
    
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundColor(.brandPrimary)
                        .frame(width: 25)
                    Text("Calories Burned")
                        .font(.headline)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
                
                Picker("Input Mode", selection: $calorieInputMode.animation()) {
                    Text("Auto (Health)").tag(CalorieInputMode.auto)
                    Text("Manual").tag(CalorieInputMode.manual)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.bottom, 5)

                if calorieInputMode == .auto {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("\(Int(autoCalories))")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .animation(.easeInOut, value: autoCalories)
                        
                        Text("kcal")
                            .font(.headline)
                            .foregroundColor(.textSecondary)
                            .padding(.bottom, 4)
                        
                        Spacer()
                        
                        Button(action: onRefresh) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title3)
                                .foregroundColor(.brandPrimary)
                        }
                    }
                } else {
                    HStack(alignment: .bottom, spacing: 4) {
                        TextField("0", value: $manualCalories, format: .number)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .keyboardType(.numberPad)
                            .focused($isFocused)
                        
                        Text("kcal")
                            .font(.headline)
                            .foregroundColor(.textSecondary)
                            .padding(.bottom, 4)
                        
                        Spacer()
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "figure.walk.motion")
                        .font(.title3)
                        .foregroundColor(.pastelBlue)
                        .frame(width: 25)
                    Text("Activity Level")
                        .font(.headline)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
                
                
                
                Picker("Activity Level", selection: $selectedActivity) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        Text(level.description).tag(level)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.primary)
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
        .onTapGesture {
            isFocused = false
        }
    }
}
