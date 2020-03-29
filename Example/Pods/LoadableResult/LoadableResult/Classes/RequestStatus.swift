//  Created by Axel Ancona Esselmann on 9/11/18.
//  Copyright © 2019 Axel Ancona Esselmann. All rights reserved.
//

import Foundation

public enum LoadableResultError: Error {
    case unknown
}

public enum TypelessRequestStatus {
    case inProgress
    case success
    case error(Error)
}

public protocol LoadableResultConvertable {
    associatedtype LoadableResultData
    var loadableResult: LoadableResult<LoadableResultData> { get }
}

public enum RequestStatus<RequestData, ResponseData, ErrorType> where ErrorType: Error {
    case unknown
    case inProgress(RequestData)
    case success(ResponseData)
    case error(ErrorType)
}

extension RequestStatus: LoadableResultConvertable {
    public var loadableResult: LoadableResult<ResponseData> {
        switch self {
        case .unknown:
            return .error(LoadableResultError.unknown)
        case .inProgress: return .loading
        case .success(let data): return .loaded(data)
        case .error(let error): return .error(error)
        }
    }
}

extension RequestStatus: LoadableType {
    public var loaded: ResponseData? {
        switch self {
        case .unknown, .inProgress, .error: return nil
        case .success(let loaded): return loaded
        }
    }
}

extension RequestStatus: TypelessRequestStatusConvertable {
    public var typeless: TypelessRequestStatus {
        switch self {
        case .unknown, .inProgress: return .inProgress
        case .success: return .success
        case .error(let error): return .error(error)
        }
    }
}

extension LoadableResult: LoadableResultConvertable {
    public var loadableResult: LoadableResult<LoadedType> {
        return self
    }
}
