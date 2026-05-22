//
//  KYCRepository.swift
//  Nara
//
//  Created by Eylül Soylu on 20.05.2026.
//
// =============================================================================
//  SUPABASE SQL SCHEMA
//  Aşağıdaki SQL'i Supabase Dashboard → SQL Editor'da çalıştırın.
// =============================================================================
//
//  -- 1. Kullanıcı tablosu
//  CREATE TABLE public.users (
//      id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//      tc_identity_hash VARCHAR(64)  NOT NULL,
//      phone_hash       VARCHAR(64)  NOT NULL,
//      is_verified      BOOLEAN      NOT NULL DEFAULT FALSE,
//      gender           VARCHAR(20)  NOT NULL,
//      created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
//
//      -- Mükerrer kayıt önlemi: aynı TC hash iki kez kayıt yapamaz
//      CONSTRAINT uq_tc_identity_hash UNIQUE (tc_identity_hash)
//  );
//
//  -- 2. Row Level Security — kullanıcı yalnızca kendi satırını görebilir
//  ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
//
//  CREATE POLICY "users_select_own" ON public.users
//      FOR SELECT USING (auth.uid() = id);
//
//  CREATE POLICY "users_insert_own" ON public.users
//      FOR INSERT WITH CHECK (auth.uid() = id);
//
//  -- 3. Servis rolü (backend) tüm satırları okuyabilir
//  CREATE POLICY "service_role_all" ON public.users
//      FOR ALL TO service_role USING (true) WITH CHECK (true);
//
// =============================================================================

import Foundation
import Supabase

// MARK: - Error

enum KYCError: LocalizedError {
    case duplicateIdentity
    case registrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .duplicateIdentity:
            return "Bu kimlik bilgisiyle daha önce kayıt oluşturulmuş."
        case .registrationFailed(let message):
            return "Kayıt başarısız: \(message)"
        }
    }
}

// MARK: - Repository

enum KYCRepository {

    // -------------------------------------------------------------------------
    // MARK: Kayıt
    // -------------------------------------------------------------------------

    /// PDF doğrulaması tamamlanan kullanıcıyı Supabase'e kaydeder.
    /// • `id` ve `phone_hash`: aktif auth session'dan otomatik alınır.
    /// - Throws: `KYCError.duplicateIdentity` — aynı phone_hash zaten kayıtlıysa
    /// - Throws: `KYCError.registrationFailed` — diğer veritabanı hatalarında
    static func registerUser(tcHash: String) async throws {

        let session   = try await supabase.auth.session
        let userId    = session.user.id
        let phone     = session.user.phone ?? ""
        let phoneHash = PDFVerificationService.sha256(phone)

        struct UserInsert: Encodable {
            let id: UUID
            let tc_identity_hash: String
            let phone_hash: String
            let is_verified: Bool
        }

        do {
            try await supabase
                .from("users")
                .insert(UserInsert(
                    id: userId,
                    tc_identity_hash: tcHash,
                    phone_hash: phoneHash,
                    is_verified: true
                ))
                .execute()
        } catch {
            let description = error.localizedDescription
            if description.contains("23505") || description.contains("duplicate") {
                throw KYCError.duplicateIdentity
            }
            throw KYCError.registrationFailed(description)
        }
    }

    // -------------------------------------------------------------------------
    // MARK: Profil Kontrolü
    // -------------------------------------------------------------------------

    /// Mevcut auth kullanıcısının public.users kaydı var mı kontrol eder.
    /// RLS politikası sayesinde yalnızca kendi satırı görünür.
    static func hasProfile() async throws -> Bool {
        struct Row: Decodable { let id: UUID }
        let rows: [Row] = try await supabase
            .from("users")
            .select("id")
            .limit(1)
            .execute()
            .value
        return !rows.isEmpty
    }
}
