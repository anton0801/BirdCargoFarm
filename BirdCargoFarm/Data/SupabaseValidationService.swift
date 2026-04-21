import Foundation
import Supabase


final class SupabaseValidationService: ValidationService {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://cdohzytqhkbvmewjryrr.supabase.co")!,
            supabaseKey: "sb_publishable_ifJtvarmjtZSt-B1vcwaHw_po7k_Ig6"
        )
    }
    
    func validate() async throws -> Bool {
        do {
            let response: [ValidationRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let firstRow = response.first else {
                return false
            }
            
            return firstRow.isValid
        } catch {
            print("🐦 [BirdCargo] Validation error: \(error)")
            throw error
        }
    }
}
