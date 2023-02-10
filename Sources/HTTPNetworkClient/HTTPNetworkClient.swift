import Foundation

public class HTTPNetworkClient: NSObject {
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15.0
        configuration.urlCache = nil
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()

    public static let shared = HTTPNetworkClient()
    override private init() {
        super.init()
    }

    private var dataTask: URLSessionDataTask?
    public var authToken: String?
    public var authErrorAction: (() -> Void)?

    public func callApi(_ request: NetworkRequest, completion: @escaping (Result<NetworkResponse, Error>) -> Void) {
        let urlRequest = urlRequestWith(apiRequest: request)
        dataTask = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                if let retry = request.retry, retry.currentTry < retry.maxRetries {
                    retry.currentTry += 1
                    DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + retry.delay) {
                        self.callApi(request, completion: completion)
                    }
                } else {
                    completion(.failure(error))
                }
            } else {
                completion(.success((response, data)))
            }
        }
        dataTask?.resume()
    }

    func urlRequestWith(apiRequest: NetworkRequest) -> URLRequest {
        let completeUrl = apiRequest.webServiceUrl +
            apiRequest.apiPath +
            apiRequest.apiVersion +
            apiRequest.apiResource +
            apiRequest.endPoint

        var components = URLComponents(string: completeUrl)!
        if let urlParams = apiRequest.urlParameters {
            var queryItems = [URLQueryItem]()
            urlParams.forEach { key, value in
                let queryItem = URLQueryItem(name: key, value: String(value))
                queryItems.append(queryItem)
            }
            components.queryItems = queryItems
        }

        let url = components.url! // URL(string: completeUrl)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = apiRequest.requestType.rawValue
        urlRequest.setValue(apiRequest.contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = apiRequest.body

        apiRequest.headers?.forEach {
            urlRequest.setValue($1, forHTTPHeaderField: $0)
        }

        if apiRequest.needAuth, let bearerToken = authToken {
            urlRequest.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        return urlRequest
    }
}

extension HTTPNetworkClient: URLSessionDelegate {
    public func urlSession(_: URLSession, didBecomeInvalidWithError _: Error?) {}

    public func urlSession(_: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.host {
        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
