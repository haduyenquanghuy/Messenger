//
//  DatabaseManager.swift
//  Messenger
//
//  Created by AnhDT on 27/11/2021.
//

import Foundation
import FirebaseDatabase

// this class cannot be subclass
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
}

// MARK: - Account Management

extension DatabaseManager{
    
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        // Firebase database allows you to observe value changes on any entry in your no SQL DB
        // by specifying the child that you want to observe for
        // and specifying what type of observation you want
        database.child(email).observeSingleEvent(of: .value, with: { snapshot in
            // this snapshot has a value property off of it that can be optional if doesn't exist
            // if has email -> call completion; pass value = true, else value = false;
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Inserts new user to database
    public func insertUser(with user:ChatAppUser) {
        // emailAddress become primary key => can't have 2 user same email
        database.child(user.emailAddress).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ])
    }
}
struct ChatAppUser {
    
    let firstName: String
    let lastName: String
    let emailAddress: String
    //    let profilePictureURL: String
}

