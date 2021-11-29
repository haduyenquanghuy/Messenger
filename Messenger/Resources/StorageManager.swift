//
//  StorageManager.swift
//  Messenger
//
//  Created by Ha Duyen Quang Huy on 30/11/2021.
//

import Foundation
import FirebaseStorage

final class StoreManager {
    static let shared = StoreManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion =  (Result<String, Error>) -> Void
    // handle back download url for the image after upload
    // cache image
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data,
                                     fileName:String,
                                     completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
}
