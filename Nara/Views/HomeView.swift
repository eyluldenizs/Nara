//
//  HomeView.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color.appLightIceBlue
                .ignoresSafeArea()

            Text("Ana Sayfa")
                .font(AppFonts.titleFont())
                .foregroundColor(.appDarkBrown)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    HomeView()
}
