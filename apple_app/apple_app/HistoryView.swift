//
//  HistoryView.swift
//  FitnessTracker
//
//  (تم تعديله) ليستخدم ألوان الهوية الجديدة
//

import SwiftUI

struct HistoryView: View {
    
    enum DateFilter: String, CaseIterable {
        case allTime = "All Time"
        case week = "Last Week"
        case month = "Last Month"
        case year = "Last Year"
    }
    
    enum DisplayMode {
        case kilograms
        case calories
    }

    @State private var selectedFilter: DateFilter = .allTime
    @State private var selectedMode: DisplayMode = .kilograms
    
    // --- (جديد) إضافة متغيرات AppStorage للوصول لجميع البيانات ---
    @AppStorage("lastWeight") private var savedWeight: Int = 0
    @AppStorage("lastHeight") private var savedHeight: Int = 0
    @AppStorage("lastBMI") private var savedBMI: Double = 0
    @AppStorage("lastCalories") private var savedCalories: Int = 0
    @AppStorage("lastBurned") private var savedBurned: Int = 0
    @AppStorage("lastIdeal") private var savedIdeal: Int = 0
    @AppStorage("lastSavedDate") private var lastSavedDate: String = ""
    @AppStorage("goal_idealReached") private var goalIdealReached: Bool = false
    @AppStorage("goal_dailyLogStreak") private var goalDailyLogStreak: Int = 0
    @AppStorage("goal_withinCalStreak") private var goalWithinCalStreak: Int = 0
    @AppStorage("goal_burn300Streak") private var goalBurn300Streak: Int = 0
    @AppStorage("savedTargetWeight") private var targetWeight: Double = 0.0
    @AppStorage("historyLog") private var historyLogData: Data = Data()
    
    @State private var showingResetAlert = false
    
    var historyData: [WeightEntry] {
        let decoder = JSONDecoder()
        if let entries = try? decoder.decode([WeightEntry].self, from: historyLogData) {
            return entries
        }
        return []
    }
    
    var currentWeight: Double {
        guard let weightString = historyData.first?.weight else { return 0 }
        return Double(weightString.replacingOccurrences(of: " Kg", with: "")) ?? 0
    }
    
    var startWeight: Double {
        guard let weightString = historyData.last?.weight else { return 0 }
        return Double(weightString.replacingOccurrences(of: " Kg", with: "")) ?? 0
    }
    
    var progress: Double {
        guard startWeight != targetWeight else { return 0 }
        let totalToLose = startWeight - targetWeight
        guard totalToLose != 0 else { return 0 }
        
        let lostSoFar = startWeight - currentWeight
        return max(0, min(1, lostSoFar / totalToLose))
    }
    
    var totalToLose: Double {
        guard startWeight > 0, targetWeight > 0, currentWeight > 0 else { return 0 }
        return currentWeight - targetWeight
    }
    
    var filteredHistory: [WeightEntry] {
        let now = Date()
        let calendar = Calendar.current
        
        switch selectedFilter {
        case .allTime:
            return historyData
        case .week:
            let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return historyData.filter { $0.date >= oneWeekAgo }
        case .month:
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            return historyData.filter { $0.date >= oneMonthAgo }
        case .year:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
            return historyData.filter { $0.date >= oneYearAgo }
        }
    }
    
    private func deleteHistoryEntry(at offsets: IndexSet) {
        let decoder = JSONDecoder()
        var currentEntries = (try? decoder.decode([WeightEntry].self, from: historyLogData)) ?? []
        
        let entriesToDelete = offsets.map { filteredHistory[$0] }
        let idsToDelete = Set(entriesToDelete.map { $0.id })

        currentEntries.removeAll { idsToDelete.contains($0.id) }

        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(currentEntries) {
            historyLogData = encodedData
        }
    }
    
    private func resetAllData() {
        historyLogData = Data()
        
        savedWeight = 0
        savedHeight = 0
        savedBMI = 0
        savedCalories = 0
        savedBurned = 0
        savedIdeal = 0
        targetWeight = 0.0
        lastSavedDate = ""
        
        goalIdealReached = false
        goalDailyLogStreak = 0
        goalWithinCalStreak = 0
        goalBurn300Streak = 0
    }
    
    var body: some View {
            ZStack {
                Color.appBackground.edgesIgnoringSafeArea(.all) // (جديد)
                
                VStack(spacing: 20) {
                    
                    HStack {
                        Button(role: .destructive) {
                            showingResetAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.title2)
                                .foregroundColor(.brandPrimary) // (جديد)
                        }
                        
                        Spacer()
                        
                        Text("History")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Image(systemName: "trash")
                            .font(.title2)
                            .opacity(0)
                            .disabled(true)
                    }
                    .padding(.horizontal)
                    
                    if !historyData.isEmpty && targetWeight > 0 && startWeight > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Start Weight").font(.caption).foregroundColor(.gray)
                                    Text("\(startWeight, specifier: "%.1f") Kg").font(.title3).fontWeight(.semibold)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Target Weight").font(.caption).foregroundColor(.gray)
                                    Text("\(targetWeight, specifier: "%.1f") Kg").font(.title3).fontWeight(.semibold)
                                }
                            }
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .brandPrimary)) // (جديد)
                                .scaleEffect(x: 1, y: 2.5, anchor: .center)
                                .padding(.vertical, 5)
                            HStack {
                                Text("Current: \(currentWeight, specifier: "%.1f") Kg").font(.subheadline).fontWeight(.medium)
                                Spacer()
                                Text("\(abs(totalToLose), specifier: "%.1f") Kg to go").font(.subheadline).fontWeight(.medium).foregroundColor(.brandPrimary) // (جديد)
                            }
                        }
                        .padding()
                        .background(Color.cardBackground) // (جديد)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                    }
                    
                    ModeSegmentedControl(selectedMode: $selectedMode)
                    
                    HStack {
                        Text("Recent")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(DateFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    self.selectedFilter = filter
                                }) {
                                    if selectedFilter == filter {
                                        Label(filter.rawValue, systemImage: "checkmark")
                                    } else {
                                        Text(filter.rawValue)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedFilter.rawValue)
                                Image(systemName: "slider.horizontal.3")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.trailing, 30)
                    
                    if filteredHistory.isEmpty {
                        Spacer()
                        Text("Calculate Your Data To Show Your History")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredHistory) { entry in
                                HistoryEntryRow(entry: entry, mode: selectedMode)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                                    .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteHistoryEntry)
                        }
                        .listStyle(.plain)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("Are you sure you want to delete all history and goals? This action cannot be undone.")
            }
    }
}

// (أزرار التحكم في شاشة السجل)
struct ModeSegmentedControl: View {
    @Binding var selectedMode: HistoryView.DisplayMode
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMode = .kilograms
                }
            }) {
                Text("Kg")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedMode == .kilograms ? Color.cardBackground : Color.clear) // (جديد)
                    .foregroundColor(selectedMode == .kilograms ? .brandPrimary : .gray) // (جديد)
                    .cornerRadius(20)
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedMode = .calories
                }
            }) {
                Text("Kcal")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedMode == .calories ? Color.cardBackground : Color.clear) // (جديد)
                    .foregroundColor(selectedMode == .calories ? .brandPrimary : .gray) // (جديد)
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray5))
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}


// (صف السجل - تم إصلاحه)
struct HistoryEntryRow: View {
    let entry: WeightEntry
    let mode: HistoryView.DisplayMode
    
    var directionColor: Color {
        let direction = (mode == .kilograms) ? entry.weightDirection : entry.calorieDirection
        if direction == .none { return .gray }
        // (جديد) تمييز الهبوط/العجز باللون الأخضر الباستيل
        return direction == .up ? .brandPrimary : .pastelGreen
    }
    
    var directionIcon: String {
        let direction = (mode == .kilograms) ? entry.weightDirection : entry.calorieDirection
        if direction == .none { return "minus" }
        return direction == .up ? "arrow.up" : "arrow.down"
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: entry.date)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: directionIcon)
                .font(.headline)
                .foregroundColor(directionColor)
                .frame(width: 40, height: 40)
                .background(directionColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(dateString)
                    .font(.headline)
                Text(timeString)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(mode == .kilograms ? entry.weight : entry.netCalories)
                    .font(.headline)
                Text(mode == .kilograms ? entry.weightChange : entry.calorieDifference)
                    .font(.subheadline)
                    .foregroundColor(directionColor)
            }
            .animation(nil, value: mode)
        }
        .padding()
        .background(Color.cardBackground) // (جديد)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
