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

    public func filterNils<O1, O2, O3>() -> Observable<(O1, O2, O3)> where Element == (O1?, O2?, O3?) {
        return map { (tuple: (O1?, O2?, O3?)) -> (O1, O2, O3)? in
            guard let t0 = tuple.0, let t1 = tuple.1, let t2 = tuple.2 else {
                return nil
            }
            return (t0, t1, t2)
        }.filterNil()
    }
}

extension LoadableResult  {
    /// Exposes the loaded state of a LoadableResult and provides ability to give defaults for non-loaded states
    public func unpack<Element>(
        whenInactive: Element? = nil,
        whenLoading: Element? = nil,
        whenError: Element? = nil
    ) -> Element? {
        return map { state -> Element? in
            switch state {
            case .inactive:
                return whenInactive
            case .loading:
                return whenLoading
            case .loaded:
                return self.loaded as? Element
            case .error:
                return whenError
            }
        }
    }

    public func unpack<Element>(whenNotLoaded: Element) -> Element {
        return unpack(
            whenInactive: whenNotLoaded,
            whenLoading: whenNotLoaded,
            whenError: whenNotLoaded
        ) ?? whenNotLoaded
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
        }
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
        return mapLoadableResult() { _ in return true }
    }
}

extension Observable {
    public func mapLoadableResult<T, Result>(_ transform: @escaping (T) -> Result) -> LoadingObservable<Result> where Element == LoadableResult<T> {
        return map { (state: LoadableResult<T>) -> LoadableResult<Result> in
            switch state {
            case .inactive:
                return .inactive
            case .loading:
                return .loading
            case .loaded(let before):
                return .loaded(transform(before))
            case .error(let error):
                return .error(error)
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
