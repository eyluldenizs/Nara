import Foundation
import Supabase

// Not defterindeki kendi URL ve Key'ini buraya yapıştır!
let supabaseURL = URL(string: "https://sstroqlpblsyqcxanpic.supabase.co")!
let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzdHJvcWxwYmxzeXFjeGFucGljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNjg2NDgsImV4cCI6MjA5NDg0NDY0OH0.KsprCtn-QFBSr6bW_gmNVe5yHoKg3gq2EvkgDZuT0CQ"

let supabase = SupabaseClient(
    supabaseURL: supabaseURL,
    supabaseKey: supabaseKey
)
