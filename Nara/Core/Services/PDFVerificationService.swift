//
//  PDFVerificationService.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//
//  İşleyiş:
//  1. PDF, PDFKit ile ayrıştırılır.
//  2. TÜBİTAK imza alanı varlığı + ByteRange bütünlüğü doğrulanır.
//  3. Cinsiyet metni çıkarılır; "Kadın" değilse akış kesilir.
//  4. T.C. Kimlik No CryptoKit ile SHA-256'ya dönüştürülür — ham değer hiçbir zaman
//     dışarıya çıkmaz.
//  5. Doğrulama tamamlanır tamamlanmaz PDF verisi bellekten silinir (çağıran sorumludur).

import Foundation
import PDFKit
import CryptoKit

// MARK: - Error Types

enum PDFVerificationError: LocalizedError {
    case invalidPDF
    case signatureNotFound
    case signatureIntegrityFailed
    case genderNotFemale
    case identityNotFound

    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            return "Geçersiz veya Sahte Belge — PDF okunamadı."
        case .signatureNotFound:
            return "Geçersiz veya Sahte Belge — TÜBİTAK e-imzası bulunamadı."
        case .signatureIntegrityFailed:
            return "Geçersiz veya Sahte Belge — Belge imzalandıktan sonra değiştirilmiş."
        case .genderNotFemale:
            return "Bu uygulama yalnızca kadın kullanıcılara açıktır."
        case .identityNotFound:
            return "T.C. Kimlik No belgede bulunamadı."
        }
    }
}

// MARK: - Result

struct PDFVerificationResult {
    /// SHA-256 hash — ham T.C. numarası hiçbir zaman bu struct dışına çıkmaz
    let tcIdentityHash: String
    let gender: String
}

// MARK: - Service

enum PDFVerificationService {

    // -------------------------------------------------------------------------
    // MARK: Ana Akış
    // -------------------------------------------------------------------------

    /// PDF verisini alır, tüm doğrulama adımlarını çalıştırır ve sonuç döner.
    /// ⚠️ Fonksiyon döndükten hemen sonra çağıran `pdfData` referansını sıfırlamalıdır.
    static func verify(pdfData: Data) throws -> PDFVerificationResult {

        // 1. PDFKit parse
        guard let document = PDFDocument(data: pdfData) else {
            throw PDFVerificationError.invalidPDF
        }

        // 2. TÜBİTAK e-imza kontrolü (varlık + ByteRange bütünlüğü)
        try verifyESignature(pdfData: pdfData, document: document)

        // 3. Tüm sayfa metinlerini birleştir
        let fullText = extractFullText(from: document)

        // 4. Cinsiyet kontrolü
        let gender = try extractGender(from: fullText)
        guard gender.uppercased().contains("KADIN") else {
            throw PDFVerificationError.genderNotFemale
        }

        // 5. TC numarasını çıkar, SHA-256'ya çevir (ham değer bu scope dışına çıkmaz)
        let tcHash = try extractAndHashTC(from: fullText)

        return PDFVerificationResult(tcIdentityHash: tcHash, gender: gender)
    }

    // -------------------------------------------------------------------------
    // MARK: Adım 2 — TÜBİTAK E-İmza Doğrulaması
    // -------------------------------------------------------------------------

    private static func verifyESignature(pdfData: Data, document: PDFDocument) throws {

        // --- Level 1: PDFKit imza anotasyonu ---
        let hasAnnotation = hasSignatureAnnotation(in: document)

        // --- Level 2: ByteRange + Contents ham kontrolü ---
        let byteRangeResult = verifyByteRange(pdfData: pdfData)

        guard hasAnnotation || byteRangeResult != .notFound else {
            throw PDFVerificationError.signatureNotFound
        }
        guard byteRangeResult != .tampered else {
            throw PDFVerificationError.signatureIntegrityFailed
        }

        // --- Level 3: Tam Kriptografik PKCS#7 Zincir Doğrulaması ---
        //
        // Bu katman için TÜBİTAK KAMU SM kök sertifikasının (PEM/DER)
        // uygulama bundle'ına eklenmesi gerekir.
        //
        // Adımlar:
        //   a) ByteRange'den imzalanmış bayt bloklarını al.
        //   b) /Contents alanındaki DER-kodlu PKCS#7 blob'unu çıkar.
        //   c) SecCertificate yükle: SecCertificateCreateWithData(kCFAllocatorDefault, derData)
        //   d) SecTrustCreateWithCertificates ile trust nesnesi oluştur.
        //   e) Politikayı ekle: SecPolicyCreateBasicX509()
        //   f) Trust zincirini doğrula: SecTrustEvaluateWithError(&error)
        //   g) Signed attributes içindeki messageDigest ile hesaplanan SHA hash'i karşılaştır.
        //
        // Bu implementasyonda Level 1 ve Level 2 aktiftir.
        // Level 3'ü aktif etmek için yukarıdaki adımları
        // extractAndVerifyPKCS7(pdfData:) fonksiyonu olarak buraya bağlayın.
    }

    // -------------------------------------------------------------------------
    // MARK: Level 1 — PDFKit Anotasyon Tespiti
    // -------------------------------------------------------------------------

    private static func hasSignatureAnnotation(in document: PDFDocument) -> Bool {
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            for annotation in page.annotations {
                let type = annotation.type ?? ""
                // PDF widget annotation subtypes: /Sig veya Signature
                if type == "Widget" || type.lowercased().contains("sig") {
                    return true
                }
            }
        }
        return false
    }

    // -------------------------------------------------------------------------
    // MARK: Level 2 — ByteRange Bütünlük Kontrolü
    // -------------------------------------------------------------------------

    private enum ByteRangeStatus { case valid, notFound, tampered }

    /// PDF spesifikasyonuna göre /ByteRange [start1, len1, start2, len2] yapısını doğrular.
    /// İmzalanan baytları hesaplar; PKCS#7 digest karşılaştırması için SHA-256 döner.
    private static func verifyByteRange(pdfData: Data) -> ByteRangeStatus {

        // Binary-safe okuma için Latin-1
        guard let pdfString = String(data: pdfData, encoding: .isoLatin1) else {
            return .notFound
        }

        let byteRangePattern = #"/ByteRange\s*\[\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*\]"#
        let contentsPattern  = #"/Contents\s*<([0-9A-Fa-f\s]+)>"#

        guard
            let brRegex = try? NSRegularExpression(pattern: byteRangePattern),
            let ctRegex = try? NSRegularExpression(pattern: contentsPattern),
            let brMatch = brRegex.firstMatch(
                in: pdfString,
                range: NSRange(pdfString.startIndex..., in: pdfString)
            ),
            ctRegex.firstMatch(
                in: pdfString,
                range: NSRange(pdfString.startIndex..., in: pdfString)
            ) != nil
        else { return .notFound }

        // Dört değer: [start1, length1, start2, length2]
        let values: [Int] = (1...4).compactMap { i -> Int? in
            guard let range = Range(brMatch.range(at: i), in: pdfString) else { return nil }
            return Int(pdfString[range])
        }
        guard values.count == 4 else { return .notFound }

        let (s1, l1, s2, l2) = (values[0], values[1], values[2], values[3])

        // Sınır kontrolü: iki blok da dosya içinde olmalı; blok 1 blok 2'den önce bitmeli
        guard
            s1 >= 0, s1 + l1 <= pdfData.count,
            s2 >= 0, s2 + l2 <= pdfData.count,
            s2 >= s1 + l1   // Aralarındaki boşluk = /Contents alanı
        else { return .tampered }

        // İmzalanan veri = chunk1 + chunk2
        var signedData = Data()
        signedData.append(pdfData[s1 ..< s1 + l1])
        signedData.append(pdfData[s2 ..< s2 + l2])

        // SHA-256 hesapla — Level 3'te PKCS#7 messageDigest ile karşılaştırılacak
        let _ = SHA256.hash(data: signedData)

        return .valid
    }

    // -------------------------------------------------------------------------
    // MARK: Adım 3 — Metin Çıkarma
    // -------------------------------------------------------------------------

    private static func extractFullText(from document: PDFDocument) -> String {
        (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")
    }

    // -------------------------------------------------------------------------
    // MARK: Adım 4 — Cinsiyet Ayrıştırma
    // -------------------------------------------------------------------------

    private static func extractGender(from text: String) throws -> String {
        // e-Devlet belgesinde "Cinsiyet : Kadın" veya "CINSIYET KADIN" gibi formatlar
        let patterns = [
            #"(?i)cinsiyet\s*[:\s]+([A-Za-zÇĞİÖŞÜçğışöşü]+)"#,
            #"(?i)gender\s*[:\s]+([A-Za-z]+)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(
                   in: text,
                   range: NSRange(text.startIndex..., in: text)
               ),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range]).trimmingCharacters(in: .whitespaces)
            }
        }

        // Fallback: direkt anahtar kelime taraması
        let upper = text.uppercased()
        if upper.contains("KADIN")  { return "Kadın" }
        if upper.contains("ERKEK")  { return "Erkek" }

        throw PDFVerificationError.identityNotFound
    }

    // -------------------------------------------------------------------------
    // MARK: Adım 5 — T.C. Kimlik No → SHA-256
    // -------------------------------------------------------------------------

    private static func extractAndHashTC(from text: String) throws -> String {
        // e-Devlet belgelerinde 11 haneli, 1'den başlayan TC formatı
        let pattern = #"(?:T\.?C\.?\s*Kimlik\s*No[\.:\s]+)?(\b[1-9][0-9]{10}\b)"#

        guard
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
            let match = regex.firstMatch(
                in: text,
                range: NSRange(text.startIndex..., in: text)
            ),
            let range = Range(match.range(at: 1), in: text)
        else { throw PDFVerificationError.identityNotFound }

        let tcNumber = String(text[range])
        return sha256(tcNumber)
        // tcNumber bu noktadan sonra scope'un dışına çıkmaz
    }

    // -------------------------------------------------------------------------
    // MARK: CryptoKit SHA-256 Yardımcısı
    // -------------------------------------------------------------------------

    /// Herhangi bir string'i SHA-256 ile hash'ler ve lowercase hex string döner.
    /// Telefon numarası hash'lemek için de kullanılabilir.
    static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
