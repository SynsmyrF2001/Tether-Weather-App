import Foundation

public class APIService{
    public static let shared = APIService()
    
    public enum APIError: Error {
        case error( errorString: String)
    }
    
    public func getJSON<T: Decodable>(urlString: String,
                                      dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                                      keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                                      completion: @escaping(Result<T,APIError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.error(errorString: NSLocalizedString("Error: Invalid URL", comment: ""))))
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(.error(errorString: "Error: \(error.localizedDescription)")))
                return
            }
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(.error(errorString: NSLocalizedString("Error: Server returned status code \(httpResponse.statusCode).", comment: ""))))
                return
            }
            guard let data = data else {
                completion(.failure(.error(errorString: NSLocalizedString("Error: Data is corrupt.", comment: ""))))
                return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = dateDecodingStrategy
            decoder.keyDecodingStrategy = keyDecodingStrategy
            do {
                let decodedData = try decoder.decode(T.self, from: data)
                completion(.success(decodedData))
                return
            } catch let decodingError {
                completion(.failure(APIError.error(errorString: "Error: \(decodingError.localizedDescription)")))
                return
            }
        }.resume()
    }
}

