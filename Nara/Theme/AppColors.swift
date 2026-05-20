import SwiftUI

// Tüm renk paletimiz
extension Color {
    /// Ana aksiyon rengimiz (Ana butonlar, SOS ikonu, vurgular)
    static let appCopper = Color(hex: "C85A3C")
    
    /// Başlıklar ve önemli metinler için (Koyu Kahve)
    static let appDarkBrown = Color(hex: "3E2723")
    
    /// Daha koyu metinler ve vurgular için (Çok Koyu Kahve/Antrasit)
    static let appDarkestBrown = Color(hex: "2C2624")
    
    /// Harita detayları ve su hatırlatıcısı için (Yumuşak Su Yeşili)
    static let appSoftTeal = Color(hex: "A2C8C3")
    
    /// İkincil butonlar ve pasif durumlar için (Soluk Gül/Kiremit)
    static let appMutedRose = Color(hex: "AD8177")
    
    /// Ferah alanlar ve hafif vurgular için (Açık Buz Mavisi)
    static let appLightIceBlue = Color(hex: "CFE8F0")
    
    /// Uygulama genel ekran arka planı (Krem/Kırık Beyaz)
    static let appBackground = Color(hex: "F7F5F0")
}

// SwiftUI için HEX kod okuyucu araç
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
