//  Created by Axel Ancona Esselmann on 2/5/20.
//

import Foundation

public protocol LoadableType {
    associatedtype LoadedType
    var loaded: LoadedType? { get }
}

extension LoadableResult: LoadableType {
    public var loaded: T? {
        switch self {
        case .inactive, .loading, .error: return nil
        case .loaded(let loaded): return loaded
        }
    }
}


extension LoadableResult {

    /// true for any loaded result.
    public var isloaded: Bool {
        switch self {
        case .inactive, .loading, .error: return false
        case .loaded: return true
        }
    }

    /// Any loaded result returns true. Aloading result return nil,  inactive and error states return false
    public var toBool: Bool? {
        switch self {
        case .inactive: return false
        case .loading: return nil
        case .loaded: return true
        case .error: return false
        }
    }

    public func toBool(
        whenInactive: Bool? = false,
        whenLoading: Bool? = false,
        whenLoaded: Bool? = true,
        whenError: Bool? = false
    ) -> Bool? {
        switch self {
        case .inactive: return whenInactive
        case .loading: return whenLoading
        case .loaded: return true
        case .error: return whenError
        }
    }
}
