//
//  ViewController.swift
//  RxSample
//
//  Created by TakuNishimura on 2016/10/28.
//  Copyright © 2016年 taktem. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class RootViewController: UIViewController {
    
    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var textField1: UITextField!
    @IBOutlet private weak var textField2: UITextField!
    @IBOutlet private weak var outputLabel: UILabel!
    @IBOutlet private weak var resetButton: UIButton!

    private let disposeBag = DisposeBag()

    private let textStream = Variable("")

    override func viewDidLoad() {
        super.viewDidLoad()

        bindText1()
        bindText2()
        bindText3()
        bindText4()
        bindScroll()
    }

    // スタンダードなテキストBind
    private func bindText1() {
        textField1.rx.text
            .flatMap { RootViewController.unwrapString(source: $0) }
            .subscribe(onNext: { [unowned self] in
                self.outputLabel.text = $0
            })
            .addDisposableTo(disposeBag)
    }

    // 2個のTextFieldを結合
    private func bindText2() {
        // @IBActionの代用
        resetButton.rx.tap
            .subscribe(onNext: { [unowned self] _ in
                self.outputLabel.text = nil
            })
            .addDisposableTo(disposeBag)
        
        // TextField監視
        let textStream1 = textField1.rx.text
            .flatMap { RootViewController.unwrapString(source: $0) }
        let textStream2 = textField2.rx.text
            .flatMap { RootViewController.unwrapString(source: $0) }

        Observable
            .combineLatest(textStream1, textStream2, resultSelector: { $0.0 + ":" + $0.1 })
            .subscribe(onNext: { [unowned self] in
                self.outputLabel.text = $0
            })
            .addDisposableTo(disposeBag)
    }

    // Hot Coldの例
    private func bindText3() {
        let textStream = textField1.rx.text
            .filter {_ in
                print("kick")
                return true
            }
            .shareReplay(1)
        
        textStream
            .bindTo(textField2.rx.text)
            .addDisposableTo(disposeBag)

        textStream
            .bindTo(textField2.rx.text)
            .addDisposableTo(disposeBag)
    }

    // VariableとSchedulerの例
    private func bindText4() {
        textField1.rx.text
            .flatMap { RootViewController.unwrapString(source: $0) }
            .subscribe(onNext: { [unowned self] in self.textStream.value = $0 })
            .addDisposableTo(disposeBag)

        textStream.asObservable()
            .map { $0.characters.count }
            // subscribeOnでの指定に従って、以前の処理が走る
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            // observeOnの指定に従って、以降の処理が走る
            .subscribe(onNext: { print($0) })
            .addDisposableTo(disposeBag)
    }

    // スクロール監視
    private func bindScroll() {
        scrollView.rx.contentOffset
            .map { $0.y }
            .buffer(timeSpan: 1.0, count: 2, scheduler: MainScheduler.instance)
            .filter { $0.count > 0 }
            .subscribe(onNext: {
                print($0.first!)
            })
            .addDisposableTo(disposeBag)
    }

    // flatMapサンプル用
    private class func unwrapString(source: String?) -> Observable<String> {
        return Observable<String>.create {
            if let st = source {
                $0.onNext(st)
            } else {
                $0.onNext("")
            }

            $0.onCompleted()
            
            return Disposables.create()
        }
    }
}

