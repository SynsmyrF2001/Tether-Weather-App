import Foundation

final class APIService {
    static let shared = APIService()
    private init() {}

    enum APIError: LocalizedError {
        case invalidURL
        case badStatus(Int)
        case corruptData

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL."
            case .badStatus(let code): return "Server returned status code \(code)."
            case .corruptData: return "Data is corrupt or unreadable."
            }
        }
    }

    func getJSON<T: Decodable>(
        urlString: String,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    ) async throws -> T {
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.badStatus(http.statusCode)
        }
        guard !data.isEmpty else { throw APIError.corruptData }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy
        return try decoder.decode(T.self, from: data)
    }
}
