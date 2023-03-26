internal enum LoggingMatrixError: Error {
    case invalidURL
    case unexpectedNetworkingError
    case invalidResponse(statusCode: Int, message: String?)
}
