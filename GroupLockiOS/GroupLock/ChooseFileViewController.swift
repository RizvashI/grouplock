//
//  ChooseFileViewController.swift
//  GroupLock
//
//  Created by Sergej Jaskiewicz on 20.05.16.
//  Copyright © 2016 Lanit-Tercom School. All rights reserved.
//

import UIKit
import NUI

class ChooseFileViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    private var files: [File] {
        return FileManager.sharedInstance.files(insideDirectory: .Decrypted)
    }
    private var selectedFiles = [Int : File]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.applyNUI()
        collectionView?.allowsMultipleSelection = true
        nextButton.setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.clearColor()], forState: .Disabled)

    }
    
    override func viewWillAppear(animated: Bool) {
        collectionView?.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "encryptFiles" {
            let destination = segue.destinationViewController as! KeyTypeViewController
            let conveyedFiles = Array(selectedFiles.values)
            destination.files = conveyedFiles
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return files.count
    }

    override func collectionView(collectionView: UICollectionView,
                                 cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cellToConfigure = collectionView.dequeueReusableCellWithReuseIdentifier("fileToProcessCell",
                                                                         forIndexPath: indexPath)
        let cell = cellToConfigure as! ChooseFileViewCell
        
        if let fileContents = files[indexPath.item].contents {
            cell.thumbnailView.image = UIImage(data: fileContents)
        }
        
        cell.filenameLabel.text = files[indexPath.item].name
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(collectionView: UICollectionView,
                                 didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ChooseFileViewCell
        
        cell.layer.borderWidth = CGFloat(NUISettings.getFloat("selected-border-width",
                                                              withClass: "CollectionViewCell"))
        nextButton.enabled = true
        selectedFiles[indexPath.item] = files[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView,
                                 didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ChooseFileViewCell
        cell.layer.borderWidth = 0
        
        selectedFiles[indexPath.item] = nil
        
        if selectedFiles.count == 0 {
            nextButton.enabled = false
        }
    }
    
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    private let relativeInset = CGFloat(1.0 / 12.0)
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let sectionInset = collectionView.frame.width * relativeInset
        let width = (collectionView.frame.width - 3*sectionInset) / 2
        return CGSize(width: width, height: width)
    }
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        let sectionInset = collectionView.frame.width * relativeInset
        return UIEdgeInsets(top: sectionInset, left: sectionInset, bottom: sectionInset, right: sectionInset)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        let sectionInset = collectionView.frame.width * relativeInset / 1.5
        return sectionInset
    }
}
