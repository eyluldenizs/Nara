//
//  HomeView.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//

import SwiftUI
import MapKit
import CoreLocation

struct HomeView: View {
    
    @State private var showSOSSheet = false
    @State private var isSOSActive = false
    @State private var selectedTab = 0
    @State private var showExpandedMap = false
    @State private var cameraPosition: MapCameraPosition = .region(
    MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)
    )
)


   var body: some View {
    ZStack {
        Color.appLightIceBlue
            .ignoresSafeArea()

        VStack(spacing: 0) {
            headerView

             Spacer().frame(height: 18)

    mapPlaceholder

    nearbyNetworkView

    Spacer()

    bottomNavigation
        }

        

        if showSOSSheet {
            sosSheet
        }
    }
    .toolbar(.hidden, for: .navigationBar)
    .onAppear {
    CLLocationManager().requestWhenInUseAuthorization()
}
.sheet(isPresented: $showExpandedMap) {
    expandedMapView
}
}
private var headerView: some View {
    VStack(spacing: 8) {
        Text(isSOSActive ? "Güvenlik modu aktif" : "Yalnız değilsin")
            .font(AppFonts.titleFont())
            .foregroundColor(.appDarkestBrown)

        Text(isSOSActive ? "Kontrol döngüsü sessizce çalışıyor" : "Yakındaki dayanışma ağı hazır")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.appDarkBrown)
    }
    .padding(.top, 56)
    .padding(.horizontal, 24)
}
private var mapPlaceholder: some View {
    ZStack(alignment: .topLeading) {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        VStack {
    HStack {
        Spacer()

        Button(action: {
            showExpandedMap = true
        }) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appDarkestBrown)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
        }
        .padding(14)
    }

    Spacer()
}
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))

        VStack(alignment: .leading, spacing: 6) {
            Text("Yakındaki ağ hazır")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.appDarkestBrown)

            Text("Konumun haritada gösteriliyor")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.appDarkBrown)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.88))
        .cornerRadius(14)
        .padding(14)
    }
    .frame(height: 300)
    .padding(.horizontal, 24)
}
private var expandedMapView: some View {
    ZStack(alignment: .topTrailing) {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea()

        Button(action: {
            showExpandedMap = false
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.appDarkestBrown)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.92))
                .clipShape(Circle())
        }
        .padding(.top, 18)
        .padding(.trailing, 18)
    }
}
private var nearbyNetworkView: some View {
    VStack(alignment: .leading, spacing: 14) {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Yakındaki Dayanışma")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.appDarkestBrown)

                Text("5 km içinde anonim destek ağı")
                    .font(.system(size: 13))
                    .foregroundColor(.appDarkBrown)
            }

            Spacer()

            Text("12 kişi")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.appCopper)
                .cornerRadius(14)
        }

        HStack(spacing: 10) {
            nearbyChip(distance: "450 m", label: "en yakın")
            nearbyChip(distance: "1.2 km", label: "destekçi")
            nearbyChip(distance: "2.8 km", label: "destekçi")
        }
    }
    .padding(18)
    .background(Color.white.opacity(0.72))
    .cornerRadius(22)
    .padding(.horizontal, 24)
    .padding(.top, 16)
}
private func nearbyChip(distance: String, label: String) -> some View {
    VStack(spacing: 6) {
        Circle()
            .fill(Color.appCopper.opacity(0.85))
            .frame(width: 10, height: 10)

        Text(distance)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.appDarkestBrown)

        Text(label)
            .font(.system(size: 11))
            .foregroundColor(.appDarkBrown)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(Color.appLightIceBlue.opacity(0.7))
    .cornerRadius(16)
}
private var bottomNavigation: some View {
    HStack {
        Button(action: { selectedTab = 0 }) {
    VStack(spacing: 4) {
        Image(systemName: "figure.2.and.child.holdinghands")
        Text("Birlikte Git")
            .font(.system(size: 11, weight: .medium))
    }
    .foregroundColor(selectedTab == 0 ? .appCopper : .appMutedRose)
    .frame(maxWidth: .infinity)
}

        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                showSOSSheet = true
            }
        }) {
            ZStack {
                Circle()
                    .fill(isSOSActive ? Color.appMutedRose : Color.appCopper)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.appDarkBrown.opacity(0.16), radius: 14, x: 0, y: 8)

                Image("mainIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)
            }
        }
        .frame(maxWidth: .infinity)
        .offset(y: -18)

        Button(action: { selectedTab = 2 }) {
            VStack(spacing: 4) {
                Image(systemName: "person.fill")
                Text("Profil")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selectedTab == 2 ? .appCopper : .appMutedRose)
            .frame(maxWidth: .infinity)
        }
    }
    .padding(.horizontal, 24)
    .padding(.top, 12)
    .padding(.bottom, 28)
    .background(Color.white.opacity(0.78))
}
private var sosSheet: some View {
    ZStack {
        Color.black.opacity(0.22)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSOSSheet = false
                }
            }

        VStack {
            Spacer()

            VStack(spacing: 18) {
                Capsule()
                    .fill(Color.appMutedRose.opacity(0.4))
                    .frame(width: 44, height: 5)
                    .padding(.top, 12)

                Text(isSOSActive ? "Güvenlik modu açık" : "Güvenlik modunu başlat")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.appDarkestBrown)

                Text(isSOSActive ? "Mod aktifken Nara belirli aralıklarla iyi olup olmadığını kontrol edecek." : "Bu mod dışarıdan normal görünür. Şimdilik prototip olarak sadece durum değiştirir.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.appDarkBrown)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)

                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isSOSActive.toggle()
                        showSOSSheet = false
                    }
                }) {
                    Text(isSOSActive ? "Modu Kapat" : "Başlat")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isSOSActive ? Color.appMutedRose : Color.appCopper)
                        .cornerRadius(18)
                }
                .padding(.horizontal, 24)

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSOSSheet = false
                    }
                }) {
                    Text("Vazgeç")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.appDarkBrown)
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color.appBackground)
            .cornerRadius(28)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}
}

#Preview {
    HomeView()
}
