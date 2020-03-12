//  Created by Axel Ancona Esselmann on 3/3/20.
//

import RxSwift
import LoadableResult

public extension ObservableType where Element == LoadableResult<Bool>  {

    func subscribe(onTrue: (() -> Void)? = nil, onFalse: (() -> Void)? = nil) -> Disposable {
        loaded().subscribe(onNext: { isTrue in
            if isTrue {
                onTrue?()
            } else {
                onFalse?()
            }
        })
    }

    func mapLoaded<Result>(true onTrue: Result, false onFalse: Result) -> LoadingObservable<Result>  {
        return map { result -> LoadableResult<Result> in
            switch result {
            case .inactive:
                return .inactive
            case .loading:
                return .loading
            case .loaded(let isTrue):
                return isTrue ? .loaded(onTrue) : .loaded(onFalse)
            case .error(let error):
                return .error(error)
            }
        }
    }
}
