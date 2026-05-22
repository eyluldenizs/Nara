//
//  LoginView.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//

import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @AppStorage("hasRegistered") private var hasRegistered = false
    @State private var goToHome = false
    @State private var goToPhoneLogin = false

    var body: some View {
        ZStack {
            Color.appLightIceBlue
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("mainIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)

                Spacer().frame(height: 48)

                Text("Dayanışma sesinle başlar")
                    .font(AppFonts.bodyFont())
                    .foregroundColor(.appDarkBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                Button(action: handleStart) {
                    Text("BAŞLA")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .kerning(1.5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.appCopper)
                        .cornerRadius(18)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .navigationDestination(isPresented: $goToHome) {
            HomeView()
        }
        .navigationDestination(isPresented: $goToPhoneLogin) {
            PhoneLoginView()
        }
    }

    private func handleStart() {
        if hasRegistered {
            authenticateWithBiometrics()
        } else {
            goToPhoneLogin = true
        }
    }

    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Nara'ya giriş yapmak için kimliğini doğrula"
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        goToHome = true
                    } else {
                        goToPhoneLogin = true
                    }
                }
            }
        } else {
            // Biyometrik mevcut değil — telefon girişine yönlendir
            goToPhoneLogin = true
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
    }
}
