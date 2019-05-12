public func startEventLoop<Event: Decodable, Response: Encodable>(handler: @escaping (Event) -> Response) throws {
    while true {
        let (requestId, event) = try retrieveInvokeEvent()
        let result = invoke(event: event, handler: handler)
        switch(result) {
        case .success(let response):
            try postInvocationResponse(requestId: requestId, response: response)
        case .failure(let error):
            try postInvocationError(requestId: requestId, error: error)
        }
    }
}
