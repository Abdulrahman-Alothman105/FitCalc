//
//  ContentView.swift
//  FitnessTracker
//
//  يحتوي هذا الملف على الـ TabView الرئيسي الذي يربط جميع الشاشات.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                HomeView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Calculator", systemImage: "plus.forwardslash.minus")
                    }
                    .tag(0)

                SummaryView()
                    .tabItem {
                        Label("result", systemImage: "chart.bar.fill")
                    }
                    .tag(1)

                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "list.bullet")
                    }
                    .tag(2)
            }
            // (توحيد اللون)
            .toolbarBackground(Color(.systemGroupedBackground), for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

// هذا هو الـ Preview الوحيد الذي تحتاجه للمشروع كاملاً
#Preview {
    ContentView()
}

