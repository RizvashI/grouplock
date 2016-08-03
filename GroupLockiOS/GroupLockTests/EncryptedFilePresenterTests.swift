//
//  EncryptedFilePresenterTests.swift
//  GroupLock
//
//  Created by Sergej Jaskiewicz on 25.07.16.
//  Copyright (c) 2016 Lanit-Tercom School. All rights reserved.
//

import XCTest
@testable import GroupLock

// swiftlint:disable force_unwrapping
class EncryptedFilePresenterTests: XCTestCase {

    struct Seeds {
        struct Share {
            static let response = EncryptedFile.Share.Response(dataToShare: [NSData(), NSData()],
                                                               excludedActivityTypes: ["0", "1", "2"])
        }

        struct Fetch {

            private static let testImageURL = NSBundle(forClass: EncryptedFilePresenterTests.self)
                .URLForResource("test-image", withExtension: "png")!

            // MARK: Seeds for cases where file contains correct image data
            private static let correctData = [
                NSData(contentsOfURL: testImageURL)!,
                NSData(contentsOfURL: testImageURL)!
            ]

            private static let fileInfoForCorrectContents = [
                EncryptedFile.Fetch.ViewModel.FileInfo(fileName: "File 1",
                    fileThumbnail: UIImage(data: correctData[0])!, encrypted: true),
                EncryptedFile.Fetch.ViewModel.FileInfo(fileName: "File 2",
                    fileThumbnail: UIImage(data: correctData[1])!, encrypted: false)
            ]

            private static let filesWithCorrectContents = [
                File(name: "File 1", type: "JPG", encrypted: true, contents: correctData[0]),
                File(name: "File 2", type: "PNG", encrypted: false, contents: correctData[1])
            ]

            static let responseWithCorrectData = EncryptedFile.Fetch.Response(files: filesWithCorrectContents)
            static let viewModelForCorrectData =
                EncryptedFile.Fetch.ViewModel(fileInfo: fileInfoForCorrectContents)

            // MARK: Seeds for cases where file contains incorrect image data or no data at all

            private static let fileInfoForIncorrectContents = [
                EncryptedFile.Fetch.ViewModel.FileInfo(fileName: "File 1",
                    fileThumbnail: UIImage(), encrypted: true),
                EncryptedFile.Fetch.ViewModel.FileInfo(fileName: "File 2",
                    fileThumbnail: UIImage(), encrypted: false)
            ]

            private static let filesWithIncorrectContents = [
                File(name: "File 1", type: "JPG", encrypted: true, contents: NSData()),
                File(name: "File 2", type: "JPG", encrypted: false, contents: nil)
            ]

            static let responseWithIncorrectData = EncryptedFile.Fetch.Response(files: filesWithIncorrectContents)
            static let viewModelForIncorrectData =
                EncryptedFile.Fetch.ViewModel(fileInfo: fileInfoForIncorrectContents)
        }
    }

    // MARK: Subject under test
    var sut: EncryptedFilePresenter!

    // MARK: - Test lifecycle

    override func setUp() {
        super.setUp()

        sut = EncryptedFilePresenter()
    }

    // MARK: - Test doubles

    class EncryptedFilePresenterOutputSpy: EncryptedFilePresenterOutput {

        var shareResponseReceived: EncryptedFile.Share.Response?

        var fetchViewModelReceived: EncryptedFile.Fetch.ViewModel?

        func displayFiles(viewModel: EncryptedFile.Fetch.ViewModel) {
            fetchViewModelReceived = viewModel
        }

        func displaySharingInterface(response: EncryptedFile.Share.Response) {
            shareResponseReceived = response
        }
    }

    // MARK: - Tests

    func test_ThatEncryptedFilePresenter_ForwardsShareResponse() {

        // Given
        let encryptedFilePresenterOutputSpy = EncryptedFilePresenterOutputSpy()
        sut.output = encryptedFilePresenterOutputSpy
        let response = Seeds.Share.response

        // When
        sut.shareFiles(response)

        // Then
        let expectedResponse = response
        let returnedResponse = encryptedFilePresenterOutputSpy.shareResponseReceived
        XCTAssertNotNil(returnedResponse,
                        "EncryptedFilePresenter should invoke displaySharingInterface(_:) method on its output")
        XCTAssertEqual(expectedResponse, returnedResponse,
                       "EncryptedFilePresenter should forward the `Share` response it received to its output")
    }

    func test_ThatEncryptedFilePresenter_FormsCorrectFetchViewModelForFilesWithCorrectContents() {

        // Given
        let encryptedFilePresenterOutputSpy = EncryptedFilePresenterOutputSpy()
        sut.output = encryptedFilePresenterOutputSpy

        // When
        sut.presentFiles(Seeds.Fetch.responseWithCorrectData)

        // Then
        let expectedViewModel = Seeds.Fetch.viewModelForCorrectData
        let returnedViewModel = encryptedFilePresenterOutputSpy.fetchViewModelReceived
        XCTAssertNotNil(returnedViewModel,
                        "EncryptedFilePresenter should invoke displayFiles(_:) method on its output")
        XCTAssertEqual(expectedViewModel, returnedViewModel,
                       "EncryptedFilePresenter should form a correct view model when asked to present files")
    }

    func test_ThatEncryptedFIlePresenter_FormsCorrectFetchViewModelForFilesWithIncorrectContents() {

        // Given
        let encryptedFilePresenterOutputSpy = EncryptedFilePresenterOutputSpy()
        sut.output = encryptedFilePresenterOutputSpy

        // When
        sut.presentFiles(Seeds.Fetch.responseWithIncorrectData)

        // Then
        let expectedViewModel = Seeds.Fetch.viewModelForIncorrectData
        let returnedViewModel = encryptedFilePresenterOutputSpy.fetchViewModelReceived
        XCTAssertNotNil(returnedViewModel,
                        "EncryptedFilePresenter should invoke displayFiles(_:) method on its output")
        XCTAssertEqual(expectedViewModel, returnedViewModel,
                       "EncryptedFilePresenter should form a correct view model even for files with incorrect" +
            " contents or no contents at all")
    }
}
// swiftlint:enable force_unwrapping
