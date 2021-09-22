//
//  ImageTool.swift
//  AGGeometryKitDemo
//
//  Created by Gavin Xiang on 2021/9/22.
//  Copyright © 2021 Agens. All rights reserved.
//

import UIKit
import Photos

class ImageTool: NSObject {
    // https://www.coder.work/article/2372601
    class func fetchAssetCollectionForAlbum(albumName: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }
    // https://developer.apple.com/forums/thread/72745
    /*
     A closure is said to escape a function when the closure is passed as an argument to the function, but is called after the function returns. When you declare a function that takes a closure as one of its parameters, you can write @escaping before the parameter’s type to indicate that the closure is allowed to escape.
     */
    // https://docs.swift.org/swift-book/LanguageGuide/Closures.html
    @objc class func createAlbum(_ image: UIImage, albumName: String, completionHandler: @escaping (Bool) -> Void) -> Void {
        var result: Bool = false
        print("in CreateAlbum")

        if let assetCollection = fetchAssetCollectionForAlbum(albumName: albumName) {
            result = self.saveImage(image, assetCollection: assetCollection)
            completionHandler(result)
        }
        else {
            PHPhotoLibrary.requestAuthorization{ status in
                switch status
                {
                case .authorized :
                    print("CreateAlbum, we are authorized")
                    do
                        {
                            var assetCollectionPlaceholder: PHObjectPlaceholder? = nil
                            try PHPhotoLibrary.shared().performChangesAndWait({
                                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                                assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                                result = true
                            })
                            print("execution of the performanChanges in createAlbum")
                            if (result) {
                                print("album was created")
                                let collectionFetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [assetCollectionPlaceholder!.localIdentifier], options: nil)
                                
                                let assetCollection = collectionFetchResult.firstObject!
                                print("createAlbum: result value: \(result)")
                                result = self.saveImage(image, assetCollection: assetCollection)  //here is the issue
                            }
                            else {
                                print("there is a problem")
                            }
                        }
                    catch let error
                    {
                        result = false
                        print("there was a problem: \(error.localizedDescription)")
                    }
                    break
                default:
                    print("should really prompt the user to let them know it's failed")
                    break
                }
                completionHandler(result)
            }
        }
    }
    
    class func saveImage(_ image: UIImage, assetCollection: PHAssetCollection?) ->Bool {
        print("Executing saveImage")
        var result:Bool = false
        if assetCollection == nil {
            print("the album is nil")
            return result
        }
        print("saveImage: we will start saving the image")
        
        do
            {
                try PHPhotoLibrary.shared().performChangesAndWait({
                    let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                    let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollection!)
                    let enumeration: NSArray = [assetPlaceHolder!]
                    albumChangeRequest!.addAssets(enumeration)
                    print("saveImage: image was save without issues")
                    result = true
                    print("saveImage: result value after saving the image: \(result)")
                })
            }
        catch let error
        {
            result = false
            print("saveImage: there was a problem: \(error.localizedDescription)")
        }
        print("saveImage: result value before exiting the method: \(result)")
        return result
        
    }
}
