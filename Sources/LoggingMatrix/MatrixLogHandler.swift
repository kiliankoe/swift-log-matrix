import Foundation
import Logging

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public class MatrixLogHandler: LogHandler {

    private var homeserver: URL
    private var roomID: String
    private var accessToken: String

    private var label: String
    public var logLevel: Logger.Level
    private var showLocation: Bool

    private var timestamp: String {
        var buffer = [Int8](repeating: 0, count: 25)
        var timestamp = time(nil)
        let localTime = localtime(&timestamp)
        strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", localTime)
        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }

    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            metadata[metadataKey]
        }
        set(newValue) {
            metadata[metadataKey] = newValue
        }
    }

    public var metadata = Logger.Metadata()

    /// Create a new matrix log handler.
    /// - Parameters:
    ///   - label: Your log label.
    ///   - homeserver: Your Matrix homeserver, e.g. `https://matrix.org`.
    ///   - roomID: Your room ID (looks like `!xxxxxxxxxxxxxxx:homeserver.tld`).
    ///   - accessToken: Your access token.
    ///   - level: Log level, defaults to `.critical`.
    ///   - showLocation: Should the logs show the source location (function, file and line number), defaults to `false`.
    public init(
        label: String,
        homeserver: URL,
        roomID: String,
        accessToken: String,
        level: Logger.Level = .critical,
        showLocation: Bool = false
    ) {
        self.label = label
        self.homeserver = homeserver
        self.roomID = roomID
        self.accessToken = accessToken
        self.logLevel = level
        self.showLocation = showLocation
    }

    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        file: String,
        function: String,
        line: UInt
    ) {
        guard level >= logLevel else { return }
        let mergedMetadata = self.metadata.merged(with: metadata)
        Task {
            let matrixMessage = Message(
                timestamp: self.timestamp,
                label: self.label,
                level: level,
                message: message,
                metadata: mergedMetadata,
                file: file,
                function: function,
                line: line,
                showLocation: self.showLocation
            )
            do {
                try await send(matrixMessage)
            } catch {
                print("Error trying to send log to Matrix: \(error)")
            }
        }
    }

    private func send(_ message: Message) async throws {
        let payload = try JSONEncoder().encode(message)

        let pathComponents = ["/_matrix", "/client", "/r0", "/rooms", "/\(self.roomID)", "/send", "/m.room.message"]
        let sendURL = pathComponents.reduce(self.homeserver, { $0.appendingPathComponent($1) })
        guard var urlComponents = URLComponents(url: sendURL, resolvingAgainstBaseURL: false) else {
            throw Error.urlComponents
        }
        urlComponents.queryItems = [URLQueryItem(name: "access_token", value: self.accessToken)]

        guard var request = urlComponents.url.map({ URLRequest(url: $0) }) else { throw Error.urlComponents }
        request.httpMethod = "POST"
        request.httpBody = payload
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await URLSession.shared.data(for: request)

        do {
            _ = try JSONDecoder().decode(EventResponse.self, from: data)
        } catch {
            throw Error.invalidResponse(
                statusCode: (resp as? HTTPURLResponse)?.statusCode,
                message: String(data: data, encoding: .utf8)
            )
        }
    }

    private enum Error: Swift.Error {
        case urlComponents
        case invalidResponse(statusCode: Int?, message: String?)
    }

    private struct EventResponse: Decodable {
        let event_id: String
    }
}
