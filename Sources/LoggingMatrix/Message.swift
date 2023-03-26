import Logging

extension MatrixLogHandler {
    internal struct Message: Encodable {
        let timestamp: String
        let label: String
        let level: Logger.Level
        let message: Logger.Message
        let metadata: Logger.Metadata
        let file: String
        let function: String
        let line: UInt
        let showLocation: Bool

        init(
            timestamp: String,
            label: String,
            level: Logger.Level,
            message: Logger.Message,
            metadata: Logger.Metadata,
            file: String,
            function: String,
            line: UInt,
            showLocation: Bool
        ) {
            self.timestamp = timestamp
            self.label = label
            self.level = level
            self.message = message
            self.metadata = metadata
            self.file = file
            self.function = function
            self.line = line
            self.showLocation = showLocation
        }

        enum CodingKeys: CodingKey {
            case msgtype
            case body
            case format
            case formatted_body
        }

        var levelIcon: String {
            switch level {
            case .trace:
                return ""
            case .debug:
                return "🪲"
            case .info:
                return "ℹ️"
            case .notice:
                return "🪧"
            case .warning:
                return "⚠️"
            case .error:
                return "⛔"
            case .critical:
                return "❌"
            }
        }

        private var plainBody: String {
            var body = """
                \(timestamp)
                \(levelIcon) [\(label)] [\(level)]
                \(message)
                """
            if showLocation {
                body.append("\n\(function) @ \(file):\(line)")
            }
            if !metadata.isEmpty {
                body.append("\n\n\(metadata.map { "\($0): \($1)"}.joined(separator: "\n"))")
            }
            return body
        }

        private var formattedBody: String {
            var body = """
                \(timestamp)</br>
                \(levelIcon) <b>[\(label)] [\(level)]</b></br>
                <b>\(message)</b>
                """
            if showLocation {
                body.append("</br><em>\(function) @ \(file):\(line)</em>")
            }
            if !metadata.isEmpty {
                body.append("<ul>")
                body.append("\(metadata.map { "<li>\($0): \($1)</li>"}.joined())")
                body.append("</ul>")
            }
            return body
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("m.text", forKey: .msgtype)
            try container.encode(plainBody, forKey: .body)
            try container.encode("org.matrix.custom.html", forKey: .format)
            try container.encode(formattedBody, forKey: .formatted_body)
        }
    }
}
