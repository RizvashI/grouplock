//
//  ChooseFileViewController.swift
//  GroupLock
//
//  Created by Sergej Jaskiewicz on 20.05.16.
//  Copyright © 2016 Lanit-Tercom School. All rights reserved.
//

import UIKit
import NUI
import JSQDataSourcesKit

protocol ChooseFileViewControllerInput {
    func displayFiles(with viewModel: ChooseFile.Configure.ViewModel)
}

protocol ChooseFileViewControllerOutput {

    func setFetchedResultsDelegate(request: ChooseFile.SetDelegate.Request)
    func configureFetchedResultsController(request: ChooseFile.Configure.Request)
    func fetchFiles(request: ChooseFile.FetchFiles.Request)

    var numberOfSelectedFiles: Int { get }
    func fileSelected(request: ChooseFile.SelectFiles.Request)
    func fileDeselected(request: ChooseFile.SelectFiles.Request)

    var chosenFiles: [File] { get }
    var encryption: Bool { get set }
}

class ChooseFileViewController: UICollectionViewController, ChooseFileViewControllerInput {

    var output: ChooseFileViewControllerOutput!
    var router: ChooseFileRouter!

    private typealias FileInfo = ChooseFile.Configure.ViewModel.FileInfo
    private typealias CollectionViewCellFactory = ViewFactory<FileInfo, FileCollectionViewCell>
    private typealias DataSource = FetchedResultsController<ManagedFile>
    private typealias FileInfoFetchedResultsController = PresentedDataSource<DataSource, FileInfo>
    private var dataSourceProvider: DataSourceProvider<FileInfoFetchedResultsController,
                                                       CollectionViewCellFactory,
                                                       CollectionViewCellFactory>!

    @IBOutlet var nextButton: UIBarButtonItem!


    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureCollectionView()

        let request = ChooseFile.Configure.Request(forEncryption: output.encryption)
        output.configureFetchedResultsController(request)

        nextButton.setTitleTextAttributes(
            [NSForegroundColorAttributeName : NUISettings.getColor("font-color-disabled", withClass: "BarButton")],
            forState: .Disabled
        )
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        output.fetchFiles(ChooseFile.FetchFiles.Request())
    }

    // MARK: - Methods to invoke during viewDidLoad

    private func configureCollectionView() {

        collectionView?.applyNUI()
        collectionView?.allowsMultipleSelection = true

        guard let collectionViewLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        // swiftlint:disable:next force_unwrapping (since by this time collectionView is initialized)
        CollectionViewGridLayout.setCollectionViewFlowLayout(for: collectionView!,
                                                             withBaseLayout: collectionViewLayout)
    }

    // MARK: - ChooseFileViewControllerInput

    func displayFiles(with viewModel: ChooseFile.Configure.ViewModel) {

        let cellFactory = ViewFactory(reuseIdentifier: "fileToProcessCell") {
            (cell, item: ChooseFile.Configure.ViewModel.FileInfo?,
            type, parentView, indexPath) -> FileCollectionViewCell in

            cell.filenameLabel.text = item?.name
            cell.thumbnailView.image = item?.thumbnail

            if !cell.selected {
                cell.visualizeDeselection()
            } else {
                cell.visualizeSelection()
            }

            return cell
        }

        let fetchedResultsDelegateProvider = FetchedResultsDelegateProvider(
            cellFactory: cellFactory,
            // swiftlint:disable:next force_unwrapping (since collectionView is initialized by this time)
            collectionView: collectionView!
        )

        let request = ChooseFile.SetDelegate.Request(
            fetchedResultsControllerDelegate: fetchedResultsDelegateProvider.collectionDelegate
        )
        output.setFetchedResultsDelegate(request)

        let collectionViewDataSourceProvider = DataSourceProvider(
            dataSource: viewModel.fileInfoDataSource,
            cellFactory: cellFactory,
            supplementaryFactory: cellFactory
        )

        dataSourceProvider = collectionViewDataSourceProvider

        collectionView?.dataSource = dataSourceProvider.collectionViewDataSource
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView,
                                 didSelectItemAtIndexPath indexPath: NSIndexPath) {

        // swiftlint:disable:next force_cast (since this collectionView's cells are instances of this class)
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FileCollectionViewCell

        cell.visualizeSelection()
        nextButton.enabled = true
        let request = ChooseFile.SelectFiles.Request(indexPath: indexPath)
        output.fileSelected(request)
    }

    override func collectionView(collectionView: UICollectionView,
                                 didDeselectItemAtIndexPath indexPath: NSIndexPath) {

        // swiftlint:disable:next force_cast (since this collectionView's cells are instances of this class)
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FileCollectionViewCell
        cell.visualizeDeselection()

        let request = ChooseFile.SelectFiles.Request(indexPath: indexPath)
        output.fileDeselected(request)

        if output.numberOfSelectedFiles == 0 {
            nextButton.enabled = false
        }
    }
}

extension ChooseFileViewController {
    override func awakeFromNib() {
        super.awakeFromNib()
        ChooseFileConfigurator.configure(self)
    }
}
