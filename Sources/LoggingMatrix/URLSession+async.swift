import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

extension URLSession {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let response = response as? HTTPURLResponse, let data = data {
                    continuation.resume(returning: (data, response))
                } else {
                    continuation.resume(throwing: LoggingMatrixError.unexpectedNetworkingError)
                }
            }
            task.resume()
        }
    }
}
