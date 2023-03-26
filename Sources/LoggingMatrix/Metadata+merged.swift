import Logging

extension Logger.Metadata {
    internal func merged(with other: Logger.Metadata?) -> Logger.Metadata {
        guard let other = other else {
            return self
        }
        return self.merging(other, uniquingKeysWith: { _, new in new })
    }
}
