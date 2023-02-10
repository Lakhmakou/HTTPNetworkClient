import Foundation

public protocol NetworkRequest {
    var webServiceUrl: String { get }
    var apiPath: String { get }
    var apiVersion: String { get }
    var apiResource: String { get }
    var endPoint: String { get }
    var body: Data? { get }
    var urlParameters: [String: String]? { get }
    var requestType: HTTPMethod { get }
    var contentType: String { get }
    var headers: [String: String]? { get }
    var retry: Retry? { get }
    var needAuth: Bool { get }
}

// MARK: - Default Settings

public extension NetworkRequest {
    var webServiceUrl: String { "" }
    var apiPath: String { "" }
    var apiVersion: String { "" }
    var apiResource: String { "" }
    var endPoint: String { "" }
    var body: Data? { nil }
    var urlParameters: [String: String]? { nil }
    var requestType: HTTPMethod { .get }
    var contentType: String { "application/json" }
    var headers: [String: String]? { nil }
    var retry: Retry? { nil }
    var needAuth: Bool { true }
}

public class Retry {
    let maxRetries: UInt
    var currentTry: UInt = 1
    let delay: TimeInterval = 0.0

    init(_ maxRetries: UInt) {
        self.maxRetries = maxRetries
    }
}
