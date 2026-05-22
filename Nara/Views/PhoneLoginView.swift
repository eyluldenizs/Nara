//
//  PhoneLoginView.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//

import SwiftUI
import Supabase

struct PhoneLoginView: View {
    @State private var phoneNumber = ""
    @State private var goToOTP = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isPhoneFocused: Bool

    private var isValid: Bool { phoneNumber.count >= 10 }

    var body: some View {
        ZStack {
            Color.appLightIceBlue
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("mainIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                Spacer().frame(height: 40)

                Text("Numaranı Gir")
                    .font(AppFonts.bodyFont())
                    .foregroundColor(.appDarkBrown)

                Spacer().frame(height: 24)

                // Telefon numarası alanı
                HStack(spacing: 4) {
                    Text("+90")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.appDarkestBrown)
                        .padding(.leading, 20)

                    TextField("555 55 55", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.appDarkestBrown)
                        .focused($isPhoneFocused)
                        .onChange(of: phoneNumber) { newValue in
                            let digits = newValue.filter { $0.isNumber }
                            phoneNumber = String(digits.prefix(10))
                        }
                        .padding(.leading, 8)
                    Spacer()
                }
                .frame(height: 56)
                .background(Color.white.opacity(0.9))
                .cornerRadius(16)
                .padding(.horizontal, 32)

                Spacer().frame(height: 28)

                Text("Sana tek kullanımlık bir onay kodu göndereceğiz")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.appDarkBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.appCopper)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }

                Spacer()

                Button(action: {
                    guard isValid else { return }
                    Task { await sendOTP() }
                }) {
                    Text("Kodu Gönder")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isValid ? Color.appCopper : Color.appMutedRose)
                        .cornerRadius(18)
                        .animation(.easeInOut(duration: 0.2), value: isValid)
                }
                .disabled(!isValid || isLoading)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onTapGesture { isPhoneFocused = false }
        .navigationDestination(isPresented: $goToOTP) {
            OTPView(phoneNumber: "+90\(phoneNumber)")
        }
    }

    private func sendOTP() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.auth.signInWithOTP(phone: "+90\(phoneNumber)")
            goToOTP = true
        } catch {
            errorMessage = "Kod gönderilemedi: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        PhoneLoginView()
    }
}
