import SwiftUI

// Tüm uygulamada kullanacağımız standart yazı tipleri
struct AppFonts {
    
    /// Ana başlıklar için (Örn: "Aramıza Hoş Geldin!")
    static func titleFont() -> Font {
        return Font.system(size: 28, weight: .heavy, design: .rounded)
    }
    
    /// Alt başlıklar için (Örn: "Güvenli Kaydı Tamamla")
    static func subtitleFont() -> Font {
        return Font.system(size: 20, weight: .bold, design: .rounded)
    }
    
    /// Normal metinler ve açıklamalar için (Örn: Aydınlatma metni)
    static func bodyFont() -> Font {
        return Font.system(size: 19, weight: .regular, design: .serif)
    }
    
    /// Küçük detaylar ve uyarılar için (Örn: "2 aktif ilan var")
    static func captionFont() -> Font {
        return Font.system(size: 13, weight: .regular, design: .rounded)
    }
}

// SwiftUI'da kullanımı kolaylaştırmak için küçük bir eklenti (Extension)
extension View {
    /// Başlık stilini uygular ve Koyu Kahve rengini verir
    func titleStyle() -> some View {
        self.font(AppFonts.titleFont())
            .foregroundColor(.appDarkBrown)
    }
    
    /// Normal metin stilini uygular
    func bodyStyle() -> some View {
        self.font(AppFonts.bodyFont())
            .foregroundColor(.appDarkestBrown)
    }
}
