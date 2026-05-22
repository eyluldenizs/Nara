//
//  ProfileSetupView.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//

import SwiftUI
import LocalAuthentication
import Supabase

// MARK: - Emergency Contact Model

struct EmergencyContactEntry {
    var name: String = ""
    var phone: String = ""
}

// MARK: - View

struct ProfileSetupView: View {

    @AppStorage("hasRegistered") private var hasRegistered = false

    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var faceIDEnabled = false

    @State private var contacts: [EmergencyContactEntry] = [
        EmergencyContactEntry(),
        EmergencyContactEntry(),
        EmergencyContactEntry()
    ]

    @State private var isLoading    = false
    @State private var errorMessage: String?
    @State private var goToHome     = false

    @FocusState private var focusedField: ProfileField?

    enum ProfileField: Hashable {
        case firstName, lastName
        case contactName(Int), contactPhone(Int)
    }

    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // -------------------------------------------------------------------------
    // MARK: Body
    // -------------------------------------------------------------------------

    var body: some View {
        ZStack {
            Color.appLightIceBlue.ignoresSafeArea()

            VStack(spacing: 0) {

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {

                        // Header
                        Image("mainIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 140, height: 140)
                            .padding(.top, 40)

                        Spacer().frame(height: 20)

                        Text("PROFİLİNİ TAMAMLA")
                            .font(AppFonts.titleFont())
                            .foregroundColor(.appDarkestBrown)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer().frame(height: 8)

                        Text("Son birkaç adım ve topluluğa katılıyorsun.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.appDarkBrown)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        // --- İsim & Soyisim ---
                        Spacer().frame(height: 36)

                        sectionLabel("İsim & Soyisim")
                        Spacer().frame(height: 10)

                        inputField(
                            placeholder: "Adın",
                            text: $firstName,
                            field: .firstName
                        )

                        Spacer().frame(height: 12)

                        inputField(
                            placeholder: "Soyadın",
                            text: $lastName,
                            field: .lastName
                        )

                        // --- Face ID ---
                        Spacer().frame(height: 28)

                        faceIDRow

                        // --- Acil Durum Kişileri ---
                        Spacer().frame(height: 28)

                        sectionLabel("Acil Durum Kişileri")
                        Spacer().frame(height: 6)

                        Text("SOS gönderdiğinde bu kişilere bildirim gider.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.appMutedRose)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 14)

                        // Kişi 1 her zaman görünür; sonrakiler sırayla açılır
                        VStack(spacing: 0) {
                            emergencyContactRow(index: 0)

                            if !contacts[0].name.trimmingCharacters(in: .whitespaces).isEmpty {
                                Spacer().frame(height: 16)
                                emergencyContactRow(index: 1)

                                if !contacts[1].name.trimmingCharacters(in: .whitespaces).isEmpty {
                                    Spacer().frame(height: 16)
                                    emergencyContactRow(index: 2)
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.35), value: contacts[0].name.isEmpty)
                        .animation(.easeInOut(duration: 0.35), value: contacts[1].name.isEmpty)

                        // Error
                        if let error = errorMessage {
                            Spacer().frame(height: 16)
                            Text(error)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.appCopper)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Spacer().frame(height: 100)
                    }
                }

                // Sabit alt buton
                VStack(spacing: 0) {
                    Button(action: {
                        focusedField = nil
                        Task { await save() }
                    }) {
                        ZStack {
                            Text("Topluluğa Katıl")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .opacity(isLoading ? 0 : 1)
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isValid ? Color.appCopper : Color.appMutedRose)
                        .cornerRadius(18)
                        .animation(.easeInOut(duration: 0.2), value: isValid)
                    }
                    .disabled(!isValid || isLoading)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                    .background(Color.appLightIceBlue)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .simultaneousGesture(TapGesture().onEnded { focusedField = nil })
        .navigationDestination(isPresented: $goToHome) {
            HomeView()
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Alt Bileşenler
    // -------------------------------------------------------------------------

    @ViewBuilder
    private func sectionLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.appMutedRose)
                .kerning(1.4)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    @ViewBuilder
    private func inputField(
        placeholder: String,
        text: Binding<String>,
        field: ProfileField
    ) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(.appDarkestBrown)
            .focused($focusedField, equals: field)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(Color.white.opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal, 32)
    }

    private var faceIDRow: some View {
        Button(action: toggleFaceID) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(faceIDEnabled
                              ? Color.appCopper.opacity(0.12)
                              : Color.white.opacity(0.6))
                        .frame(width: 48, height: 48)
                    Image(systemName: "faceid")
                        .font(.system(size: 22))
                        .foregroundColor(faceIDEnabled ? .appCopper : .appMutedRose)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Face ID ile Giriş")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appDarkestBrown)
                    Text(faceIDEnabled
                         ? "Aktif — hızlı ve güvenli"
                         : "Bir sonraki girişte seni tanıyalım")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.appMutedRose)
                }

                Spacer()

                // Toggle pill
                Capsule()
                    .fill(faceIDEnabled ? Color.appCopper : Color.appMutedRose.opacity(0.3))
                    .frame(width: 46, height: 26)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 20, height: 20)
                            .offset(x: faceIDEnabled ? 10 : -10)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: faceIDEnabled)
                    )
                    .animation(.easeInOut(duration: 0.2), value: faceIDEnabled)
            }
            .padding(.horizontal, 20)
            .frame(height: 72)
            .background(Color.white.opacity(0.9))
            .cornerRadius(16)
            .padding(.horizontal, 32)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func emergencyContactRow(index: Int) -> some View {
        VStack(spacing: 10) {
            // Kişi etiketi
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.appMutedRose.opacity(0.18))
                        .frame(width: 26, height: 26)
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.appMutedRose)
                }
                Text("Kişi \(index + 1)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.appMutedRose)
                    .kerning(1.2)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 32)

            // Ad Soyad
            TextField("Ad Soyad", text: $contacts[index].name)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.appDarkestBrown)
                .focused($focusedField, equals: .contactName(index))
                .padding(.horizontal, 20)
                .frame(height: 52)
                .background(Color.white.opacity(0.9))
                .cornerRadius(14)
                .padding(.horizontal, 32)

            // Telefon numarası
            HStack(spacing: 0) {
                Text("+90")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.appDarkestBrown)
                    .padding(.leading, 20)

                TextField("Telefon numarası", text: $contacts[index].phone)
                    .keyboardType(.numberPad)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.appDarkestBrown)
                    .focused($focusedField, equals: .contactPhone(index))
                    .onChange(of: contacts[index].phone) { newValue in
                        let digits = newValue.filter { $0.isNumber }
                        contacts[index].phone = String(digits.prefix(10))
                    }
                    .padding(.leading, 8)
                Spacer()
            }
            .frame(height: 52)
            .background(Color.white.opacity(0.9))
            .cornerRadius(14)
            .padding(.horizontal, 32)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Eylemler
    // -------------------------------------------------------------------------

    private func toggleFaceID() {
        if faceIDEnabled {
            withAnimation { faceIDEnabled = false }
            return
        }
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Face ID'yi Nara için etkinleştir"
            ) { success, _ in
                DispatchQueue.main.async {
                    withAnimation { self.faceIDEnabled = success }
                }
            }
        } else {
            // Cihaz biyometriği desteklemiyor; tercih yine de kaydedilir
            withAnimation { faceIDEnabled = true }
        }
    }

    private func save() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.session
            let userId  = session.user.id

            // 1. İsim güncelle
            struct ProfileUpdate: Encodable {
                let first_name: String
                let last_name: String
            }
            try await supabase
                .from("users")
                .update(ProfileUpdate(
                    first_name: firstName.trimmingCharacters(in: .whitespaces),
                    last_name:  lastName.trimmingCharacters(in: .whitespaces)
                ))
                .eq("id", value: userId.uuidString)
                .execute()

            // 2. Dolu acil durum kişilerini kaydet
            struct ContactInsert: Encodable {
                let user_id: UUID
                let name: String
                let phone: String
                let position: Int
            }

            let filled: [ContactInsert] = contacts
                .enumerated()
                .compactMap { i, entry in
                    let trimmedName = entry.name.trimmingCharacters(in: .whitespaces)
                    guard !trimmedName.isEmpty else { return nil }
                    return ContactInsert(
                        user_id:  userId,
                        name:     trimmedName,
                        phone:    "+90\(entry.phone)",
                        position: i + 1
                    )
                }

            if !filled.isEmpty {
                try await supabase
                    .from("emergency_contacts")
                    .insert(filled)
                    .execute()
            }

            // 3. Face ID tercihini kaydet
            UserDefaults.standard.set(faceIDEnabled, forKey: "faceIDEnabled")

            // 4. Kaydı tamamla
            hasRegistered = true
            goToHome = true

        } catch {
            errorMessage = "Kaydedilemedi: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSetupView()
    }
}
