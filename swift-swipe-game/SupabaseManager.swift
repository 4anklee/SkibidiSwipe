import Foundation

enum SupabaseError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
}

struct SupabaseConfig {
    static var supabaseURL: String {
        guard let value = ProcessInfo.processInfo.environment["SUPABASE_URL"] else {
            fatalError("SUPABASE_URL not found in environment variables")
        }
        return value
    }
    
    static var supabaseKey: String {
        guard let value = ProcessInfo.processInfo.environment["SUPABASE_KEY"] else {
            fatalError("SUPABASE_KEY not found in environment variables")
        }
        return value
    }
}

class SupabaseManager {
    static let shared = SupabaseManager()
    
    private init() {}
    
    // Save username
    func saveUsername(username: String, completion: @escaping (Result<Bool, SupabaseError>) -> Void) {
        guard let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/users") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SupabaseConfig.supabaseKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(SupabaseConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "username": username,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, 
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.invalidResponse))
                return
            }
            
            completion(.success(true))
        }.resume()
    }
    
    // Update high score
    func updateHighScore(username: String, highScore: Int, completion: @escaping (Result<Bool, SupabaseError>) -> Void) {
        guard let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/high_scores") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SupabaseConfig.supabaseKey, forHTTPHeaderField: "apikey")
        request.addValue("Bearer \(SupabaseConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        request.addValue("resolution=merge", forHTTPHeaderField: "Prefer")
        
        let body: [String: Any] = [
            "username": username,
            "score": highScore,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, 
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.invalidResponse))
                return
            }
            
            completion(.success(true))
        }.resume()
    }
} 