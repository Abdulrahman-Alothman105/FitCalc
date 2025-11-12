//
//  Color+Extensions.swift
//  FitnessTracker
//
//  هذا الملف يحتوي على ألوان الهوية الخاصة بالتطبيق
//

import SwiftUI

extension Color {
    
    // MARK: - Brand Colors (ألوان الهوية)
    
    /// لون الهوية الأساسي (البرتقالي المحفز)
    /// FF6B4A
    static let brandPrimary = Color(hex: "#FF9178")
    
    
    //MUST TRY: 557FE9
    
    // MARK: - Accent Colors (الألوان الثانوية)
    
    /// (من شاشة النتائج)
    static let pastelPink = Color(hex: "#FC9CB1")
    /// (من شاشة النتائج)
    static let pastelBlue = Color(hex: "#8CC4EA")
    /// (من شاشة النتائج)
    static let pastelPurple = Color(hex: "#C3A5FF")
    /// (من شاشة النتائج)
    static let pastelGreen = Color(hex: "#8BE2E2")
    
    /// (من شاشة النتائج - للـ BMI)
    static let bmiNormal = Color(hex: "#E7F0D5")
    static let bmiOverweight = Color(hex: "#F7C59F")
    static let bmiUnderweight = Color(hex: "#AFC8FF")

    /// (من شاشة النتائج - خلفية البطاقة التحفيزية)
    static let babyPink = Color(hex: "#F6E1DE")
    static let babyPurple = Color(hex: "#F0DEF0")
    static let Blackk = Color(hex: "#18181A")


    
    // MARK: - Standard UI Colors (ألوان الواجهة القياسية)

    /// لون الخلفية العام للتطبيق
    static let appBackground = Color(.systemGroupedBackground)
    
    /// لون خلفية البطاقات (أبيض)
    static let cardBackground = Color.white
    
    /// لون النص الأساسي (أسود أو داكن)
    static let textPrimary = Color.primary
    
    /// لون النص الثانوي (رمادي)
    static let textSecondary = Color.secondary
    
    /// لون نص داكن خاص (من شاشة النتائج)
    static let textDark = Color(hex: "#302626")
    
    /// لون رمادي خاص (من شاشة النتائج)
    static let textGrey = Color(hex: "#ACAFB7")
}


// (هذه الدالة المساعدة لترجمة كود الهيكس إلى لون)
extension Color {
    init(hex: String, opacity: Double = 1.0) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 { var x = ""; for c in s { x.append(String(repeating: c, count: 2)) }; s = x }
        var v: UInt64 = 0; Scanner(string: s).scanHexInt64(&v)
        let r,g,b,a: Double
        if s.count == 8 { a = Double((v>>24)&0xFF)/255; r = Double((v>>16)&0xFF)/255; g = Double((v>>8)&0xFF)/255; b = Double(v&0xFF)/255 }
        else { a = opacity; r = Double((v>>16)&0xFF)/255; g = Double((v>>8)&0xFF)/255; b = Double(v&0xFF)/255 }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
