import Foundation
import Supabase

// Not defterindeki kendi URL ve Key'ini buraya yapıştır!
let supabaseURL = URL(string: "https://sstroqlpblsyqcxanpic.supabase.co/rest/v1/")!
let supabaseKey = "sb_publishable_nHoW4T-ndAU9ExHzIOonAw_dZOSYe_T"

let supabase = SupabaseClient(
    supabaseURL: supabaseURL,
    supabaseKey: supabaseKey
)
