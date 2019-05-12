enum SwiftOnLambdaError: Error {
    case invalidData
    case missingValue
    case noData
    case noResponse
    case unassignedResult
}

struct InvocationError: Encodable {
    let errorMessage: String
}
