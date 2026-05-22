//
//  RegisterView.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Document Picker

struct DocumentPickerView: UIViewControllerRepresentable {
    let onPicked: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPicked: (URL) -> Void
        init(onPicked: @escaping (URL) -> Void) { self.onPicked = onPicked }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPicked(url)
        }
    }
}

// MARK: - View

struct RegisterView: View {
    @AppStorage("hasRegistered") private var hasRegistered = false
    @StateObject private var viewModel = RegisterViewModel()
    @State private var isAgreed = false
    @State private var goToProfile = false

    var body: some View {
        ZStack {
            Color.appLightIceBlue
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Image("mainIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(.top, 32)

                        Spacer().frame(height: 28)

                        Text("ARAMIZA HOŞ GELDİN!")
                            .font(AppFonts.titleFont())
                            .foregroundColor(.appDarkestBrown)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Spacer().frame(height: 24)

                        Text("Topluluğumuzun güvenliği için e-Devlet Nüfus Kayıt Örneği ile cinsiyetini doğrulamamız gerekiyor. İşlem anında biter ve belgen sistemden kalıcı olarak silinir.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.appDarkBrown)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 32)

                        Spacer().frame(height: 28)

                        // Onay kutusu
                        Button(action: { isAgreed.toggle() }) {
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(isAgreed ? Color.appCopper : Color.white)
                                        .frame(width: 22, height: 22)
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.appMutedRose, lineWidth: 1.5)
                                        .frame(width: 22, height: 22)
                                    if isAgreed {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                Text("Aydınlatma metnini okudum ve onaylıyorum.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(.appDarkBrown)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                            .padding(.horizontal, 32)
                        }
                        .buttonStyle(.plain)

                        Spacer().frame(height: 32)

                        // Dosya yükle butonu
                        Button(action: { viewModel.showDocumentPicker = true }) {
                            HStack(spacing: 10) {
                                Text(viewModel.uploadedFileName ?? "Dosya yükle")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(.appDarkestBrown)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Image(systemName: viewModel.uploadedFileName != nil
                                      ? "checkmark.circle.fill"
                                      : "square.and.arrow.up")
                                    .font(.system(size: 17))
                                    .foregroundColor(viewModel.uploadedFileName != nil
                                                     ? .appCopper
                                                     : .appDarkestBrown)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(18)
                        }
                        .padding(.horizontal, 32)
                        .disabled(viewModel.isProcessing)

                        // Hata mesajı
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(Color(hex: "C0392B"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.top, 12)
                        }

                        Spacer().frame(height: 32)
                    }
                }

                // Alt CTA butonu — sabit
                Button(action: {
                    guard isAgreed, !viewModel.isProcessing else { return }
                    if viewModel.uploadedFileName != nil {
                        // PDF zaten işlendi, başarıyla tamamlandıysa profil ekranına geç
                        if case .success = viewModel.state {
                            goToProfile = true
                        }
                    } else {
                        viewModel.showDocumentPicker = true
                    }
                }) {
                    ZStack {
                        Text("Doğrula ve Aramıza Katıl")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(viewModel.isProcessing ? 0 : 1)

                        if viewModel.isProcessing {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isAgreed ? Color.appCopper : Color.appMutedRose)
                    .cornerRadius(18)
                    .animation(.easeInOut(duration: 0.2), value: isAgreed)
                }
                .disabled(!isAgreed || viewModel.isProcessing)
                .padding(.horizontal, 32)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }

            // İşlem yüklenme overlay'i
            if viewModel.isProcessing {
                Color.black.opacity(0.25).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(.appCopper)
                    Text("Belge doğrulanıyor…")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.appDarkBrown)
                }
                .padding(32)
                .background(Color.appBackground.opacity(0.95))
                .cornerRadius(20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            DocumentPickerView { url in
                viewModel.handleSelectedPDF(url: url)
            }
        }
        .onChange(of: viewModel.state) { newState in
            if case .success = newState {
                goToProfile = true
            }
        }
        .navigationDestination(isPresented: $goToProfile) {
            ProfileSetupView()
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
    }
}
