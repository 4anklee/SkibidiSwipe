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
        guard
            let info = Bundle.main.infoDictionary,
            let value = info["SupabaseURL"] as? String
        else {
            fatalError("SUPABASE_URL not found in environment variables")
        }
        return "https://\(value)"
    }

    static var supabaseKey: String {
        guard
            let info = Bundle.main.infoDictionary,
            let value = info["SupabaseKey"] as? String
        else {
            fatalError("SUPABASE_KEY not found in environment variables")
        }
        return value
    }
}

class SupabaseManager {
    static let shared = SupabaseManager()

    private init() {
        // debugPrint the URL and key being used for debugging
        debugPrint("Supabase URL: \(SupabaseConfig.supabaseURL)")
        debugPrint(
            "Supabase Key length: \(SupabaseConfig.supabaseKey.count) characters"
        )
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
                debugPrint("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                debugPrint("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }

            debugPrint("HTTP Response status code: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString =
                    data != nil
                    ? String(data: data!, encoding: .utf8) ?? "No response body"
                    : "No response body"
                debugPrint("Error response: \(responseString)")
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
                debugPrint("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                debugPrint("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }

            debugPrint("HTTP Response status code: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString =
                    data != nil
                    ? String(data: data!, encoding: .utf8) ?? "No response body"
                    : "No response body"
                debugPrint("Error response: \(responseString)")
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
                debugPrint("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                debugPrint("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }

            debugPrint("HTTP Response status code: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString =
                    data != nil
                    ? String(data: data!, encoding: .utf8) ?? "No response body"
                    : "No response body"
                debugPrint("Error response: \(responseString)")
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
                debugPrint("Decoding error: \(error.localizedDescription)")
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }

    // Check if username exists
    func checkUsernameExists(username: String, completion: @escaping (Bool, Error?) -> Void) {
        guard
            let encodedUsername = username.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed),
            let url = URL(
                string:
                    "\(SupabaseConfig.supabaseURL)/rest/v1/User?username=eq.\(encodedUsername)&select=username"
            )
        else {
            completion(false, SupabaseError.invalidURL)
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
                debugPrint("Network error: \(error.localizedDescription)")
                completion(false, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                debugPrint("Invalid response type")
                completion(false, SupabaseError.invalidResponse)
                return
            }

            debugPrint("HTTP Response status code: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString =
                    data != nil
                    ? String(data: data!, encoding: .utf8) ?? "No response body"
                    : "No response body"
                debugPrint("Error response: \(responseString)")
                completion(false, SupabaseError.invalidResponse)
                return
            }

            guard let data = data else {
                completion(false, nil)
                return
            }

            do {
                guard let users = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                else {
                    completion(false, nil)
                    return
                }

                // Username exists if the array is not empty
                completion(!users.isEmpty, nil)
            } catch {
                debugPrint("Decoding error: \(error.localizedDescription)")
                completion(false, error)
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
                debugPrint("Network error: \(error.localizedDescription)")
                completion(.failure(.networkError(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                debugPrint("Invalid response type")
                completion(.failure(.invalidResponse))
                return
            }

            debugPrint("HTTP Response status code: \(httpResponse.statusCode)")

            if !(200...299).contains(httpResponse.statusCode) {
                let responseString =
                    data != nil
                    ? String(data: data!, encoding: .utf8) ?? "No response body"
                    : "No response body"
                debugPrint("Error response: \(responseString)")
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
                debugPrint("Decoding error: \(error.localizedDescription)")
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
}
