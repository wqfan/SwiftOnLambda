import Foundation

private let AWS_LAMBDA_RUNTIME_API = ProcessInfo.processInfo.environment["AWS_LAMBDA_RUNTIME_API"]!
private let LAMBDA_RUNTIME_REQUEST_ID = "Lambda-Runtime-Aws-Request-Id"

private func resolve(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Result<(HTTPURLResponse, Data), Error> {
    if let error = error {
        return .failure(error)
    }
    guard let data = data else {
        return .failure(SwiftOnLambdaError.noData)
    }
    guard let response = response as? HTTPURLResponse else {
        return .failure(SwiftOnLambdaError.noResponse)
    }
    return .success((response, data))
}

private func invokeAPI(url: String, method: String = "GET", body: Data? = nil) -> Result<(HTTPURLResponse, Data), Error> {
    var result: Result<(HTTPURLResponse, Data), Error> = .failure(SwiftOnLambdaError.unassignedResult)
    let semaphore = DispatchSemaphore(value: 0)
    
    var request = URLRequest(url: URL(string: url)!)
    request.httpMethod = method
    request.httpBody = body
    
    URLSession.shared.dataTask(with: request) {
        result = resolve($0, $1, $2)
        semaphore.signal()
        }.resume()
    semaphore.wait()
    return result
}


func retrieveInvocationEvent() throws -> (String, Data) {
    let INVOKE_NEXT = "http://\(AWS_LAMBDA_RUNTIME_API)/2018-06-01/runtime/invocation/next"
    switch invokeAPI(url: INVOKE_NEXT) {
    case .success((let response, let data)):
        guard let requestId = response.allHeaderFields[LAMBDA_RUNTIME_REQUEST_ID] as? String else { throw SwiftOnLambdaError.missingValue }
        return (requestId, data)
    case .failure(let error):
        throw error
    }
}

func invoke<Event: Decodable, Response: Encodable>(handler: @escaping (Event) -> Response, with event: Data) -> Result<Data, Error> {
    let jsonDecoder = JSONDecoder()
    guard let event = try? jsonDecoder.decode(Event.self, from: event) else {
        return .failure(SwiftOnLambdaError.invalidData)
    }
    
    let result = handler(event)
    
    let jsonEncoder = JSONEncoder()
    guard let response = try? jsonEncoder.encode(result) else {
        return .failure(SwiftOnLambdaError.invalidData)
    }
    return .success(response)
}

func postInvocationResponse(on requestId:String, with response: Data) throws {
    let INVOKE_POST_RESPONSE = "http://\(AWS_LAMBDA_RUNTIME_API)/2018-06-01/runtime/invocation/\(requestId)/response"
    switch invokeAPI(url: INVOKE_POST_RESPONSE, method: "POST", body: response) {
    case .success((let response, let data)):
        print(response, data)
    case .failure(let error):
        throw error
    }
}

func postInvocationError(on requestId:String, with error: Error) throws {
    let jsonEncoder = JSONEncoder()
    let error = try! jsonEncoder.encode(InvocationError(errorMessage: String(describing: error)))
    let INVOKE_POST_ERROR = "http://\(AWS_LAMBDA_RUNTIME_API)/2018-06-01/runtime/invocation/\(requestId)/error"
    switch invokeAPI(url: INVOKE_POST_ERROR, method: "POST", body: error) {
    case .success((let response, let data)):
        print(response, data)
    case .failure(let error):
        throw error
    }
}
