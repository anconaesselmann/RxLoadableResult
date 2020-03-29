//  Created by Axel Ancona Esselmann on 1/23/18.
//  Copyright © 2019 Axel Ancona Esselmann. All rights reserved.
//

import Foundation

public enum LoadableResult<T> {
    case inactive
    case loading
    case loaded(T)
    case error(Error)

    var hasLoaded: Bool {
        if case .loaded = self {
            return true
        } else {
            return false
        }
    }

    /// Every state can be remapped.
    /// map should be used when a states get combined or changed altogether.
    /// mapLoaded exists if you want to only map the loaded case, which is the more common case.
    ///
    /// Example:
    /// A server response returns a valid object that should actually be treated as an error case.
    public func map<E>(_ transform: @escaping (LoadableResult<T>) -> E) -> E {
        return transform(self)
    }

    /// The loaded state gets transformed to a new type. The transformation should not be able to fail
    /// In case acces to each individual state is necessary use map.
    ///
    /// Example:
    /// - A server response returns a full object. We are only interested in in one property.
    /// - A server response returns a list of objects. We are only interested in the first element in the list
    public func mapLoaded<E>(_ transform: @escaping (T) -> E) -> LoadableResult<E> {
        switch self {
        case .inactive:
            return .inactive
        case .loading:
            return .loading
        case .loaded(let loaded):
            return .loaded(transform(loaded))
        case .error(let error):
            return .error(error)
        }
    }

    /// The loaded state gets transformed to a new type. The transformation might fail in an upredictable way
    ///
    /// Example:
    public func mapLoaded<E>(_ transform: @escaping (T) -> Result<E, Error>) -> LoadableResult<E> {
        switch self {
        case .inactive:
            return .inactive
        case .loading:
            return .loading
        case .loaded(let loaded):
            let transformed = transform(loaded)
            switch transformed {
            case .success(let success):
                return .loaded(success)
            case .failure(let error):
                return .error(error)
            }
        case .error(let error):
            return .error(error)
        }
    }

    /// The loaded state gets transformed to a new type. The transformation might fail but in a predictable way.
    ///
    /// Example:
    public func mapLoaded<E>(onFailure error: Error, transform: @escaping (T) -> E?) -> LoadableResult<E> {
        switch self {
        case .inactive:
            return .inactive
        case .loading:
            return .loading
        case .loaded(let loaded):
            if let transformed = transform(loaded) {
                 return .loaded(transformed)
            } else {
                return .error(error)
            }
        case .error(let error):
            return .error(error)
        }
    }

    /// The loaded state gets transformed to a new type. The transformation might fail, in which case we have a default ot fallback on.
    ///
    /// Example:
    public func mapLoaded<E>(onFailure fallback: E, transform: @escaping (T) -> E?) -> LoadableResult<E> {
        switch self {
        case .inactive:
            return .inactive
        case .loading:
            return .loading
        case .loaded(let loaded):
            if let transformed = transform(loaded) {
                 return .loaded(transformed)
            } else {
                return .loaded(fallback)
            }
        case .error(let error):
            return .error(error)
        }
    }

    /// The loaded state gets transformed to a new type. The transformation might fail but recovery might be possible.
    ///
    /// Example:
    public func mapLoaded<E>(onFailure failureTransformation: (T) -> Result<E, Error>, transform: @escaping (T) -> E?) -> LoadableResult<E> {
        switch self {
        case .inactive:
            return .inactive
        case .loading:
            return .loading
        case .loaded(let loaded):
            if let transformed = transform(loaded) {
                 return .loaded(transformed)
            } else {
                switch failureTransformation(loaded) {
                case .success(let revovered):
                    return .loaded(revovered)
                case .failure(let error):
                    return .error(error)
                }
            }
        case .error(let error):
            return .error(error)
        }
    }

    /// A network request might return an error that needs to be processed before we display it for the user
    public func mapError<ErrorType>(_ transform: @escaping (Error) -> ErrorType) -> Self where ErrorType: Error {
        switch self {
        case .inactive, .loading, .loaded:
            return self
        case .error(let error):
            return .error(transform(error))
        }
    }

    /// A server request returns an error case from which we might be able to recover before with local data.
    public func mapError(_ transform: @escaping (Error) -> T?) -> Self {
        switch self {
        case .inactive, .loading, .loaded:
            return self
        case .error(let error):
            if let recovered = transform(error) {
                return .loaded(recovered)
            } else {
                return self
            }
        }
    }

    /// Exposes the loaded state of a LoadableResult and provides ability to give defaults for non-loaded states
    public func unpack(
        whenInactive: T? = nil,
        whenLoading: T? = nil,
        whenError: T? = nil
    ) -> T? {
        return map { state -> T? in
            switch state {
            case .inactive:
                return whenInactive
            case .loading:
                return whenLoading
            case .loaded:
                return self.loaded
            case .error:
                return whenError
            }
        }
    }

    public func unpack(whenNotLoaded: T) -> T {
        return unpack(
            whenInactive: whenNotLoaded,
            whenLoading: whenNotLoaded,
            whenError: whenNotLoaded
        ) ?? whenNotLoaded
    }

}

extension LoadableResult: Equatable where T: Equatable {
    /// Note: Error types are not compared to determine equality, only the fact that an error occured.
    public static func == (lhs: LoadableResult<T>, rhs: LoadableResult<T>) -> Bool {
        switch (lhs, rhs) {
        case (.inactive, .inactive): return true
        case (.loading, .loading): return true
        case (.error, .error): return true
        case (.loaded(let lhe), .loaded(let rhe)): return lhe == rhe
        default: return false
        }
    }
}

extension LoadableResult: TypelessRequestStatusConvertable {
    public var typeless: TypelessRequestStatus {
        switch self {
        case .inactive: return .inProgress
        case .loading: return .inProgress
        case .loaded: return .success
        case .error(let error): return .error(error)
        }
    }
}

public protocol TypelessRequestStatusConvertable {
    var typeless: TypelessRequestStatus { get }
}
