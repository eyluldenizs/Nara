//
//  RegisterViewModel.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - State

enum RegistrationState: Equatable {
    case idle
    case processing
    case success
    case failure(String)
}

// MARK: - ViewModel

@MainActor
final class RegisterViewModel: ObservableObject {

    @Published var state: RegistrationState = .idle
    @Published var showDocumentPicker = false
    @Published var uploadedFileName: String?

    // -------------------------------------------------------------------------
    // MARK: Belge Seçildi
    // -------------------------------------------------------------------------

    func handleSelectedPDF(url: URL) {
        Task { await processPDF(url: url) }
    }

    // -------------------------------------------------------------------------
    // MARK: Ana İşlem Akışı
    // -------------------------------------------------------------------------

    private func processPDF(url: URL) async {
        state = .processing

        // Sandboxed dosyaya güvenli erişim aç
        guard url.startAccessingSecurityScopedResource() else {
            state = .failure("Dosyaya erişim izni alınamadı.")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            // 1. PDF verisini RAM'e yükle
            var pdfData = try Data(contentsOf: url)

            // 2. e-imza + cinsiyet + TC hash doğrulama
            let result = try PDFVerificationService.verify(pdfData: pdfData)

            // 3. PDF'i bellekten kalıcı olarak sil (KVKK)
            //    Data türünün Swift runtime'daki kopyalanma semantiği göz önüne alınarak
            //    referansı sıfırlamak yeterlidir; ARC nesneyi serbest bırakır.
            pdfData = Data()

            // 4. Supabase'e kayıt — id ve phone_hash session'dan alınır
            try await KYCRepository.registerUser(tcHash: result.tcIdentityHash)

            uploadedFileName = url.lastPathComponent
            state = .success

        } catch let error as PDFVerificationError {
            state = .failure(error.localizedDescription)
        } catch let error as KYCError {
            state = .failure(error.localizedDescription)
        } catch {
            state = .failure("Beklenmeyen bir hata oluştu.")
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Yardımcılar
    // -------------------------------------------------------------------------

    var isProcessing: Bool { state == .processing }

    var errorMessage: String? {
        if case .failure(let msg) = state { return msg }
        return nil
    }
}
