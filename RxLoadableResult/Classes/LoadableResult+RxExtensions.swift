//  Created by Axel Ancona Esselmann on 1/23/18.
//  Copyright © 2019 Axel Ancona Esselmann. All rights reserved.
//

import RxSwift
import RxOptional
import RxRelay
import RxCocoa
import LoadableResult

public typealias LoadingObservable<T> = Observable<LoadableResult<T>>
public typealias DrivableState<T> = Driver<LoadableResult<T>>
public typealias LoadableBehaviorSubject<T> = BehaviorSubject<LoadableResult<T>>
public typealias LoadableBehaviorRelay<T> = BehaviorRelay<LoadableResult<T>>
public typealias PublishState<T> = PublishSubject<LoadableResult<T>>

public typealias ButtonDriver = Driver<Void>
public typealias ButtonDrivable = ControlEvent<Void>

extension ObservableType where Element: LoadableResultConvertable {
    public func subscribe(
        onLoading: (() -> Void)? = nil,
        onLoaded: ((Element.LoadableResultData) -> Void)? = nil,
        onError: ((Swift.Error) -> Void)? = nil,
        onCompleted: (() -> Void)? = nil,
        onDisposed: (() -> Void)? = nil
    ) -> Disposable {
        return subscribe(
            onNext: { stateConvertable in
                switch stateConvertable.loadableResult {
                case .inactive: break
                case .loading: onLoading?()
                case .loaded(let loadedValue): onLoaded?(loadedValue)
                case .error(let error): onError?(error)
                }
            },
            onError: { error in
                onError?(error)
            },
            onCompleted: {
                onCompleted?()
            },
            onDisposed: {
                onDisposed?()
            }
        )
    }

    public func bindLoadableResult<O>(to observer: O?, behavior: ViewModelBindingBehaviour = .default, onLoaded: ((Element.LoadableResultData) -> Void)? = nil) -> Disposable where Self.Element: LoadableResultConvertable, O: ObserverType, Self.Element == O.Element {
        return self.subscribe(
            onNext: { stateConvertable in
                guard let onLoaded = onLoaded else {
                    observer?.onNext(stateConvertable)
                    return
                }
                switch (behavior, stateConvertable.loadableResult) {
                case (.`default`, .loaded(let loadedValue)):
                    observer?.onNext(stateConvertable)
                    onLoaded(loadedValue)
                case (.interceptLoaded, .loaded(let loadedValue)):
                    onLoaded(loadedValue)
                case (.interceptLoadedAndCompleteObserver, .loaded(let loadedValue)):
                    observer?.onCompleted()
                    onLoaded(loadedValue)
                default: observer?.onNext(stateConvertable)
                }
            },
            onError: { error in
                observer?.onError(error)
            },
            onCompleted: {
                observer?.onCompleted()
            }
        )
    }

}

public enum ViewModelBindingBehaviour {
    case `default`
    case interceptLoaded
    case interceptLoadedAndCompleteObserver
}

extension ObservableType  {
    public func filterMap<T>(with transformation: @escaping (Element) -> T?)  -> Observable<T> {
        return map { element -> T? in
            guard let transformed = transformation(element) else {
                return nil
            }
            return transformed
        }.filterNil()
    }
}

extension ObservableType where Element: LoadableType  {

    public func mapLoaded() -> Observable<Element.LoadedType> {
        return self.map { element -> Element.LoadedType? in
            return element.loaded
        }.filterNil()
    }

    // Swallows errors and loaded state
    public func filterNotLoaded() -> Observable<Element> {
        return self.map { element -> Element? in
            guard element.loaded != nil else {
                return nil
            }
            return element
        }.filterNil()
    }

    // NOTE: Will complete. Careful with using bind.
    public func takeUntilFirstLoaded() -> Observable<Element> {
        return self.takeUntil(.inclusive) { element -> Bool in
            return element.loaded != nil
        }
    }
}

extension BehaviorSubject where Element: LoadableType {
    public var loadedValue: Element.LoadedType? {
        return safeValue?.loaded
    }

}

internal extension BehaviorSubject {
    var safeValue: Element? {
        return try? value()
    }

}

extension ObservableConvertibleType {
    public func asDrivableState<T>(startWith startingState: LoadableResult<T>) -> DrivableState<T> where Element == LoadableResult<T> {
        let driver = asDriver(onErrorRecover: {
            .just(.error($0))
        })
        return driver.startWith(startingState)
    }

    public func asDrivableState(startWith startingState: LoadableResult<Element>) -> DrivableState<Element> {
        return asObservable()
            .map { .loaded($0) }
            .asDriver(onErrorJustReturn: .error(LoadableResultError.unknown))
    }

    public func asDrivableState<T>(startWith maybeStartingState: LoadableResult<T>? = nil) -> DrivableState<T> where Element == LoadableResult<T> {
        let driver = asDriver(onErrorRecover: {
            .just(.error($0))
        })
        if let statingState = maybeStartingState {
            return driver.startWith(statingState)
        } else {
            return driver
        }
    }
}

extension Observable {
    public func with<T>(_ instance: T?) -> Observable<(Element, T)> {
        guard let instance = instance else {
            return .empty()
        }
        return map { element -> (Element, T) in
            return (element, instance)
        }
    }

    public func with<T, O1, O2>(_ instance: T?) -> Observable<(O1, O2, T)> where Element == (O1, O2) {
        guard let instance = instance else {
            return .empty()
        }
        return map { ($0.0, $0.1, instance) }
    }

    public func with<T, O1, O2, O3>(_ instance: T?) -> Observable<(O1, O2, O3, T)> where Element == (O1, O2, O3) {
        guard let instance = instance else {
            return .empty()
        }
        return map { ($0.0, $0.1, $0.2, instance) }
    }

    public func with<T, O1, O2, O3, O4>(_ instance: T?) -> Observable<(O1, O2, O3, O4, T)> where Element == (O1, O2, O3, O4) {
        guard let instance = instance else {
            return .empty()
        }
        return map { ($0.0, $0.1, $0.2, $0.3, instance) }
    }

    public func with<T, O1, O2, O3, O4, O5>(_ instance: T?) -> Observable<(O1, O2, O3, O4, O5, T)> where Element == (O1, O2, O3, O4, O5) {
        guard let instance = instance else {
            return .empty()
        }
        return map { ($0.0, $0.1, $0.2, $0.3, $0.4, instance) }
    }

    public func with<T, O1, O2, O3, O4, O5, O6>(_ instance: T?) -> Observable<(O1, O2, O3, O4, O5, O6, T)> where Element == (O1, O2, O3, O4, O5, O6) {
        guard let instance = instance else {
            return .empty()
        }
        return map { ($0.0, $0.1, $0.2, $0.3, $0.4, $0.5, instance) }
    }

    // MARK: - filterNils

    public func filterNils<O1, O2>() -> Observable<(O1, O2)> where Element == (O1?, O2?) {
        return map { (tuple: (O1?, O2?)) -> (O1, O2)? in
            guard let t0 = tuple.0, let t1 = tuple.1 else {
                return nil
            }
            return (t0, t1)
        }.filterNil()
    }

    public func filterNils<O1, O2, O3>() -> Observable<(O1, O2, O3)> where Element == (O1?, O2?, O3?) {
        return map { (tuple: (O1?, O2?, O3?)) -> (O1, O2, O3)? in
            guard let t0 = tuple.0, let t1 = tuple.1, let t2 = tuple.2 else {
                return nil
            }
            return (t0, t1, t2)
        }.filterNil()
    }

    public func filterNils<O1, O2, O3, O4>() -> Observable<(O1, O2, O3, O4)> where Element == (O1?, O2?, O3?, O4?) {
        return map { (tuple: (O1?, O2?, O3?, O4?)) -> (O1, O2, O3, O4)? in
            guard let t0 = tuple.0, let t1 = tuple.1, let t2 = tuple.2, let t3 = tuple.3 else {
                return nil
            }
            return (t0, t1, t2, t3)
        }.filterNil()
    }

    public func filterNils<O1, O2, O3, O4, O5>() -> Observable<(O1, O2, O3, O4, O5)> where Element == (O1?, O2?, O3?, O4?, O5?) {
        return map { (tuple: (O1?, O2?, O3?, O4?, O5?)) -> (O1, O2, O3, O4, O5)? in
            guard let t0 = tuple.0, let t1 = tuple.1, let t2 = tuple.2, let t3 = tuple.3, let t4 = tuple.4 else {
                return nil
            }
            return (t0, t1, t2, t3, t4)
        }.filterNil()
    }

    public func filterNils<O1, O2, O3, O4, O5, O6>() -> Observable<(O1, O2, O3, O4, O5, O6)> where Element == (O1?, O2?, O3?, O4?, O5?, O6?) {
        return map { (tuple: (O1?, O2?, O3?, O4?, O5?, O6?)) -> (O1, O2, O3, O4, O5, O6)? in
            guard let t0 = tuple.0, let t1 = tuple.1, let t2 = tuple.2, let t3 = tuple.3, let t4 = tuple.4, let t5 = tuple.5 else {
                return nil
            }
            return (t0, t1, t2, t3, t4, t5)
        }.filterNil()
    }

    public func filterNils<O1, O2, O3, O4, O5, O6, O7>() -> Observable<(O1, O2, O3, O4, O5, O6, O7)> where Element == (O1?, O2?, O3?, O4?, O5?, O6?, O7?) {
        return map { (tuple: (O1?, O2?, O3?, O4?, O5?, O6?, O7?)) -> (O1, O2, O3, O4, O5, O6, O7)? in
            guard let t0 = tuple.0, let t1 = tuple.1, let t2 = tuple.2, let t3 = tuple.3, let t4 = tuple.4, let t5 = tuple.5, let t6 = tuple.6 else {
                return nil
            }
            return (t0, t1, t2, t3, t4, t5, t6)
        }.filterNil()
    }

    public func filterNils<O1, O2, O3, O4, O5, O6, O7, O8>() -> Observable<(O1, O2, O3, O4, O5, O6, O7, O8)> where Element == (O1?, O2?, O3?, O4?, O5?, O6?, O7?, O8?) {
        return map { (tuple: (O1?, O2?, O3?, O4?, O5?, O6?, O7?, O8?)) -> (O1, O2, O3, O4, O5, O6, O7, O8)? in
            guard let t0 = tuple.0, let t1 = tuple.1, let t2 = tuple.2, let t3 = tuple.3, let t4 = tuple.4, let t5 = tuple.5, let t6 = tuple.6, let t7 = tuple.7 else {
                return nil
            }
            return (t0, t1, t2, t3, t4, t5, t6, t7)
        }.filterNil()
    }
}

extension BehaviorSubject {
    public func unpack<T>(
        whenInactive: T? = nil,
        whenLoading: T? = nil,
        whenError: T? = nil
    ) -> Observable<T?> where Element == LoadableResult<T> {
        return asObservable().unpack(
            whenInactive: whenInactive,
            whenLoading : whenLoading,
            whenError : whenError
        )
    }
}

extension ObservableType {

    /// Exposes the loaded state of a LoadableResult and provides ability to give defaults for non-loaded states
    public func unpack<T>(
        whenInactive: T? = nil,
        whenLoading: T? = nil,
        whenError: T? = nil
    ) -> Observable<T?> where Element == LoadableResult<T> {
        return map { state -> T? in
            return state.unpack()
        }
    }

    /// Emits onNext events for loaded results. Emits actual errors for error results (will terminate stream)
    public func unpacked<T>() -> Observable<T> where Element == LoadableResult<T> {
        return map { result -> Event<T>? in
            switch result {
            case .inactive, .loading:
                return nil
            case .loaded(let loaded):
                return Event.next(loaded)
            case .error(let error):
                return Event.error(error)
            }
        }
        .filterNil()
        .dematerialize()
    }

    /// Only emmits for loaded values.
    public func loaded<T>() -> Observable<T> where Element == LoadableResult<T> {
        return unpack().filterNil()
    }

    public func unpack<T, Observer>(withStateObserver stateObserver: Observer) -> Observable<T> where Element == LoadableResult<T>, Observer : RxSwift.ObserverType, Observer.Element == LoadableResult<Void> {
        return map { state -> T? in
            switch state {
            case .inactive:
                stateObserver.onNext(.inactive)
                return nil
            case .loading:
                stateObserver.onNext(.loading)
                return nil
            case .loaded(let unpacked):
                stateObserver.onNext(LoadableResult.loaded(()))
                return unpacked
            case .error(let error):
                stateObserver.onNext(.error(error))
                return nil
            }
        }.filterNil()
    }

    public func unpack<T>(whenNotLoaded: T) -> Observable<T> where Element == LoadableResult<T> {
        return unpack(
            whenInactive: whenNotLoaded,
            whenLoading: whenNotLoaded,
            whenError: whenNotLoaded
        ).filterNil()
    }
}

extension Driver {
    /// Exposes the loaded state of a LoadableResult and provides ability to give defaults for non-loaded states
    public func unpack<T>(
        whenInactive: T? = nil,
        whenLoading: T? = nil,
        whenError: T? = nil
    ) -> Driver<T?> where Element == LoadableResult<T> {
        return map { state -> T? in
            switch state {
            case .inactive:
                return whenInactive
            case .loading:
                return whenLoading
            case .loaded(let unpacked):
                return unpacked
            case .error:
                return whenError
            }
        }.asDriver(onErrorJustReturn: whenError)
    }

    public func unpack<T>(whenNotLoaded: T) -> Driver<T> where Element == LoadableResult<T> {
        return unpack(
            whenInactive: whenNotLoaded,
            whenLoading: whenNotLoaded,
            whenError: whenNotLoaded
        ).filterNil()
    }

}

extension Driver {
    public func mapDriver<Result>(_ selector: @escaping (Self.Element) -> Result) -> Driver<Result>
    {
        return map(selector)
            .map { $0 as Result? }
            .asDriver(onErrorJustReturn: nil)
            .filterNil()
    }
}

extension Observable {
    public func toBool<T>() -> LoadingObservable<Bool> where Element == LoadableResult<T> {
        return mapLoaded() { _ in return true }
    }
}

public enum LoadableResultType: Equatable {
    case inactive
    case loaded
    case loading
    case error
}

extension LoadableResult {
    public var type: LoadableResultType {
        switch self {
        case .inactive:
            return .inactive
        case .loading:
            return .loading
        case .loaded:
            return .loaded
        case .error:
            return .error
        }
    }
}

extension Observable {
    // Will complete once a given result type is encountered
    public func takeUntil<T>(_ resultTypes: LoadableResultType...) -> Observable<LoadableResult<T>> where Element == LoadableResult<T> {
        takeUntil(.inclusive) { result -> Bool in
            func typeIsIncluded(_ type: LoadableResultType) -> Bool {
                return resultTypes.first { type == $0 } != nil
            }
            return typeIsIncluded(result.type)
        }

    }
}

extension Observable {
    public func mapLoaded<T, Result>(_ transform: @escaping (T) -> Result) -> LoadingObservable<Result> where Element == LoadableResult<T> {
        return map { (state: LoadableResult<T>) -> LoadableResult<Result> in
            switch state {
            case .inactive: return .inactive
            case .loading: return .loading
            case .loaded(let before): return .loaded(transform(before))
            case .error(let error): return .error(error)
            }
        }
    }

    /// Loaded results are the input for the flatmap
    /// Example:
    /// - Request chaingin
    ///     A server request returns a URL for an image resource. The request for the image resource can
    ///     be passed into flatMapLoaded, for a final loaded resutl type of UIImage.
    public func flatMapLoaded<Loaded, Mapped>(_ transform: @escaping (Loaded) -> Observable<LoadableResult<Mapped>>) -> Observable<LoadableResult<Mapped>> where Element == LoadableResult<Loaded> {
        return flatMap { result -> Observable<LoadableResult<Mapped>> in
            switch result {
            case .inactive: return .just(.inactive)
            case .loading: return .just(.loading)
            case .error(let error): return .just(.error(error))
            case .loaded(let before): return transform(before)
            }
        }
    }

    public enum MappedError: Error {
        case both(Error, Error)
    }

    public func mapLoaded<T1, T2, Result>(_ transform: @escaping (T1, T2) -> Result) -> LoadingObservable<Result> where Element == (LoadableResult<T1>, LoadableResult<T2>) {
        return map { (tuple: (LoadableResult<T1>, LoadableResult<T2>)) -> LoadableResult<Result> in
            switch (tuple.0, tuple.1) {
            case (.inactive, .inactive),
                 (.inactive, .loading),
                 (.inactive, .loaded),
                 (.loading, .inactive),
                 (.loaded, .inactive):
                return .inactive
            case (.loading, .loading),
                 (.loaded, .loading),
                 (.loading, .loaded):
                return .loading
            case (.loaded(let t1), .loaded(let t2)):
                return .loaded(transform(t1, t2))
            case (.error(let e1), .error(let e2)):
                return .error(MappedError.both(e1, e2))
            case (.inactive, .error(let error)),
                 (.error(let error), .inactive),
                 (.loading, .error(let error)),
                 (.error(let error), .loading),
                 (.loaded, .error(let error)),
                 (.error(let error), .loaded):
                return .error(error)
            }
        }
    }

    public func mapLoaded<T1, T2, Result>(_ transform: @escaping (T1, T2) -> Result) -> LoadingObservable<Result> where Element == (LoadableResult<T1>, T2) {
        return map { (tuple: (LoadableResult<T1>, T2)) -> LoadableResult<Result> in
            return tuple.0.mapLoaded {
                transform($0, tuple.1)
            }
        }
    }

    public func mapLoaded<T1, T2, Result>(_ transform: @escaping (T1, T2) -> Result) -> LoadingObservable<Result> where Element == (T1, LoadableResult<T2>) {
        return map { (tuple: (T1, LoadableResult<T2>)) -> LoadableResult<Result> in
            return tuple.1.mapLoaded {
                transform(tuple.0, $0)
            }
        }
    }

    public func mapLoadableResult<T, Result>(_ transform: @escaping (T) -> LoadableResult<Result>) -> LoadingObservable<Result> where Element == LoadableResult<T> {
        return map { (state: LoadableResult<T>) -> LoadableResult<Result> in
            switch state {
            case .inactive:
                return .inactive
            case .loading:
                return .loading
            case .loaded(let before):
                return transform(before)
            case .error(let error):
                return .error(error)
            }
        }
    }
}

public extension ObservableType where Element: LoadableResultConvertable  {
    var loadableResult: LoadingObservable<Element.LoadableResultData> {
        return self.map { (element: Element) -> LoadableResult<Element.LoadableResultData> in
            let state: LoadableResult<Element.LoadableResultData> = element.loadableResult
            return state
        }
    }
}
