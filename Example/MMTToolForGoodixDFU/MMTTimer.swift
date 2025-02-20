//
//  MMTTimer.swift
//  MMTToolForBluetooth_Example
//
//  Created by Macmini3 on 27/1/2025.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

typealias MMTTimeInterval = RxTimeInterval

class MMTTimer {
    fileprivate static let share = MMTTimer()
    fileprivate var timerList: [MMTTimerUnit] = .init()

    @discardableResult class func addTimer(
        functionName: StaticString = #function,
        fileName: StaticString = #file,
        lineNumber: Int = #line,
        startCount: Int? = nil,
        endCount: Int? = nil,
        repeatDistance: MMTTimeInterval,
        disposeBag: DisposeBag? = nil,
        action: ((Int, MMTTimerUnit) -> Void)?,
        onDisposed: (() -> Void)? = nil
    ) -> MMTTimerUnit? {
        let timer = MMTTimerUnit()
        timer.functionName = functionName
        timer.fileName = fileName
        timer.lineNumber = lineNumber
        MMTTimer.share.timerList.append(timer)
        timer.addTimer(startCount: startCount, endCount: endCount, repeatDistance: repeatDistance, disposeBag: disposeBag, action: action, onDisposed: onDisposed)
        return timer
    }
}

class MMTTimerUnit {
    fileprivate var timer: Disposable?

    private let timerId: String = UUID().uuidString

    private var isPause = false
    private var pauseAdd: Int = 0

    fileprivate var functionName: StaticString?
    fileprivate var fileName: StaticString?
    fileprivate var lineNumber: Int?

    @discardableResult func addTimer(
        startCount: Int? = nil,
        endCount: Int? = nil,
        repeatDistance: MMTTimeInterval,
        disposeBag: DisposeBag? = nil,
        action: ((Int, MMTTimerUnit) -> Void)?,
        onDisposed: (() -> Void)? = nil
    ) -> MMTTimerUnit? {
        if let startCount = startCount, let endCount = endCount {
            if endCount <= startCount {
                return nil
            }
        }

        let timer = Observable<Int>
            .interval(repeatDistance, scheduler: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] currentT in
                    guard let self = self else { return }
                    if self.isPause {
                        self.pauseAdd += 1
                        return
                    }
                    let startTime = startCount ?? 0
                    let currentTime = startTime + currentT - self.pauseAdd
                    if let endTime = endCount {
                        if currentTime > endTime {
                            self.timer?.dispose()
                            self.destroyUnit()
                            return
                        }
                    }
                    action?(currentTime, self)
                },
                onDisposed: { [weak self] in
                    self?.destroyUnit()
                    onDisposed?()
                    if let functionName = self?.functionName, let fileName = self?.fileName, let lineNumber = self?.lineNumber {
                        print("timer disposed")
//                        log.debug("timer disposed", functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                    } else {
                        print("timer disposed")
                    }
                }
            )
        if let disposeBag = disposeBag {
            timer.disposed(by: disposeBag)
        }
        self.timer = timer
        return self
    }

    func pause() {
        isPause = true
    }

    func resume() {
        isPause = false
    }

    func stop() {
        timer?.dispose()
        timer = nil
    }

    func destroyUnit() {
        timer?.dispose()
        MMTTimer.share.timerList.removeAll {
            return $0.timerId == self.timerId
        }
        timer = nil
    }

    deinit {
        self.timer?.dispose()
        self.timer = nil
    }
}
