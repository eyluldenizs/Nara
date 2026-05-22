//
//  OTPView.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//

import SwiftUI
import Combine
import Supabase

struct OTPView: View {
    let phoneNumber: String

    @State private var otpCode = ""
    @State private var timeRemaining = 165   // 2:45
    @State private var goToHome = false
    @State private var goToRegister = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isOTPFocused: Bool

    private let otpTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var timerText: String {
        let m = timeRemaining / 60
        let s = timeRemaining % 60
        return String(format: "%02d.%02d", m, s)
    }

    private var isComplete: Bool { otpCode.count == 6 }

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

                Text("Onay Kodunu Gir")
                    .font(AppFonts.bodyFont())
                    .foregroundColor(.appDarkBrown)

                Spacer().frame(height: 32)

                // OTP kutuları — gizli TextField üzerinde
                ZStack {
                    TextField("", text: $otpCode)
                        .keyboardType(.numberPad)
                        .frame(width: 1, height: 1)
                        .opacity(0.001)
                        .focused($isOTPFocused)
                        .onChange(of: otpCode) { newValue in
                            let digits = newValue.filter { $0.isNumber }
                            otpCode = String(digits.prefix(6))
                        }

                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .frame(width: 46, height: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                index == otpCode.count
                                                    ? Color.appCopper
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )

                                if index < otpCode.count {
                                    let charIndex = otpCode.index(otpCode.startIndex, offsetBy: index)
                                    Text(String(otpCode[charIndex]))
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(.appDarkestBrown)
                                }
                            }
                            .onTapGesture { isOTPFocused = true }
                        }
                    }
                }
                .padding(.horizontal, 28)
                .onTapGesture { isOTPFocused = true }

                Spacer().frame(height: 20)

                // Geri sayım pill
                Text(timerText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appDarkBrown)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.appSoftTeal.opacity(0.55))
                    .cornerRadius(20)

                Spacer()

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.appCopper)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 12)
                }

                Button(action: {
                    guard isComplete else { return }
                    Task { await verifyOTP() }
                }) {
                    ZStack {
                        Text("Kodu Onayla")
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
                    .background(isComplete ? Color.appCopper : Color.appMutedRose)
                    .cornerRadius(18)
                    .animation(.easeInOut(duration: 0.2), value: isComplete)
                }
                .disabled(!isComplete || isLoading)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { isOTPFocused = true }
        .onReceive(otpTimer) { _ in
            if timeRemaining > 0 { timeRemaining -= 1 }
        }
        .navigationDestination(isPresented: $goToHome) {
            HomeView()
        }
        .navigationDestination(isPresented: $goToRegister) {
            RegisterView()
        }
    }

    private func verifyOTP() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.auth.verifyOTP(
                phone: phoneNumber,
                token: otpCode,
                type: .sms
            )
            // Kullanıcının public.users kaydı var mı?
            let hasProfile = try await KYCRepository.hasProfile()
            if hasProfile {
                goToHome = true
            } else {
                goToRegister = true
            }
        } catch {
            errorMessage = "Kod doğrulanamadı: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        OTPView(phoneNumber: "+905551234567")
    }
}
