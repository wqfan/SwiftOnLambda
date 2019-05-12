public func startEventLoop<Event: Decodable, Response: Encodable>(on handler: @escaping (Event) -> Response) throws {
    while true {
        let (requestId, event) = try retrieveInvocationEvent()
        let result = invoke(handler: handler, with: event)
        switch(result) {
        case .success(let response):
            try postInvocationResponse(on: requestId, with: response)
        case .failure(let error):
            try postInvocationError(on: requestId, with: error)
        }
    }
}
