import Foundation

enum SupabaseError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case configurationError
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

    private init() {
        // Print the URL and key being used for debugging
        print("Supabase URL: \(SupabaseConfig.supabaseURL)")
        print("Supabase Key length: \(SupabaseConfig.supabaseKey.count) characters")
    }

    // Save username
    func saveUsername(username: String, completion: @escaping (Result<Bool, SupabaseError>) -> Void)
    {
        // Using the proper table name "User" instead of "users"
        guard let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/User") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SupabaseConfig.supabaseKey, forHTTPHeaderField: "apikey")
        request.addValue(
            "Bearer \(SupabaseConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        request.addValue("return=minimal,resolution=merge", forHTTPHeaderField: "Prefer")  // Use a single Prefer header with both options

        let body: [String: Any] = [
            "username": username,
            "created_at": ISO8601DateFormatter().string(from: Date()),
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.decodingError(error)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }

            print("HTTP Response status code: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString =
                    data != nil
                    ? String(data: data!, encoding: .utf8) ?? "No response body"
                    : "No response body"
                print("Error response: \(responseString)")
                completion(.failure(.invalidResponse))
                return
            }

            completion(.success(true))
        }.resume()
    }

    // Update high score
    func updateHighScore(
        username: String, highScore: Int,
        completion: @escaping (Result<Bool, SupabaseError>) -> Void
    ) {
        guard
            let encodedUsername = username.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed),
            let url = URL(
                string: "\(SupabaseConfig.supabaseURL)/rest/v1/User?username=eq.\(encodedUsername)")
        else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SupabaseConfig.supabaseKey, forHTTPHeaderField: "apikey")
        request.addValue(
            "Bearer \(SupabaseConfig.supabaseKey)", forHTTPHeaderField: "Authorization")
        request.addValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "highest_score": highScore
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(.decodingError(error)))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }

            print("HTTP Response status code: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString =
                    data != nil
                    ? String(data: data!, encoding: .utf8) ?? "No response body"
                    : "No response body"
                print("Error response: \(responseString)")
                completion(.failure(.invalidResponse))
                return
            }

            completion(.success(true))
        }.resume()
    }

    // Get current user by username
    func getCurrentUser(
        username: String, completion: @escaping (Result<[String: Any]?, SupabaseError>) -> Void
    ) {
        guard
            let encodedUsername = username.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed),
            let url = URL(
                string:
                    "\(SupabaseConfig.supabaseURL)/rest/v1/User?username=eq.\(encodedUsername)&select=*"
            )
        else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SupabaseConfig.supabaseKey, forHTTPHeaderField: "apikey")
        request.addValue(
            "Bearer \(SupabaseConfig.supabaseKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }

            print("HTTP Response status code: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString =
                    data != nil
                    ? String(data: data!, encoding: .utf8) ?? "No response body"
                    : "No response body"
                print("Error response: \(responseString)")
                completion(.failure(.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.success(nil))
                return
            }

            do {
                guard let users = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                    let user = users.first
                else {
                    completion(.success(nil))
                    return
                }
                completion(.success(user))
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }

    // Get all users
    func getAllUsers(completion: @escaping (Result<[[String: Any]], SupabaseError>) -> Void) {
        guard let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/User?select=*") else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(SupabaseConfig.supabaseKey, forHTTPHeaderField: "apikey")
        request.addValue(
            "Bearer \(SupabaseConfig.supabaseKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }

            print("HTTP Response status code: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString =
                    data != nil
                    ? String(data: data!, encoding: .utf8) ?? "No response body"
                    : "No response body"
                print("Error response: \(responseString)")
                completion(.failure(.invalidResponse))
                return
            }

            guard let data = data else {
                completion(.success([]))
                return
            }

            do {
                guard let users = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                else {
                    completion(.success([]))
                    return
                }
                completion(.success(users))
            } catch {
                print("Decoding error: \(error.localizedDescription)")
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
}
