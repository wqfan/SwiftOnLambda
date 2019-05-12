enum SwiftOnLambdaError: Error {
    case missingValue
    case noData
    case noResponse
    case unableToDecodeEvent
    case unableToEncodeResponse
    case unassignedResult
}

struct InvocationError: Encodable {
    let errorMessage: String
}
