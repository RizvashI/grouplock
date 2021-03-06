//
//  ScanningViewControllerTests.swift
//  GroupLock
//
//  Created by Sergej Jaskiewicz on 18.08.16.
//  Copyright (c) 2016 Lanit-Tercom School. All rights reserved.
//

import XCTest
@testable import GroupLock

// swiftlint:disable force_cast
class ScanningViewControllerTests: XCTestCase {

    // MARK: Subject under test
    var sut: ScanningViewController!

    var window: UIWindow!

    // MARK: - Test lifecycle

    override func setUp() {
        super.setUp()

        window = UIWindow()
        setupScanningViewController()
    }

    override func tearDown() {

        window = nil
        super.tearDown()
    }

    // MARK: - Test setup

    func setupScanningViewController() {

        let bundle = Bundle.main
        let storyboard = UIStoryboard(name: "Main", bundle: bundle)
        sut = storyboard
            .instantiateViewController(withIdentifier: "ScanningViewController") as! ScanningViewController
    }

    func loadView() {
        window.addSubview(sut.view)
        RunLoop.current.run(until: Date())
    }

    // MARK: - Test doubles

    // MARK: - Tests

}
// swiftlint:enable force_cast
