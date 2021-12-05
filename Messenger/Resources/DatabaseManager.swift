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
    
    static func safeEmail(emailAddress:String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// MARK: - Account Management

extension DatabaseManager{
    
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        // Firebase database allows you to observe value changes on any entry in your no SQL DB
        // by specifying the child that you want to observe for
        // and specifying what type of observation you want
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
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
    public func insertUser(with user:ChatAppUser, completion: @escaping (Bool) -> Void) {
        // emailAddress become primary key => can't have 2 user same email
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("failed to write to database")
                completion(false)
                return
            }
            
            // multiple entry for each uses
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]]{
                    // append to user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                    
                } else {
                    // create that array
                    let newCollection: [[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
            
            completion(true)
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(value))
        })
    }
}

// MARK: - Sending messages / conversations
extension DatabaseManager {
    
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion :@escaping(Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: {[weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversation:[String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "lastest_message" :[
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversation:[String: Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": "Self",
                "lastest_message" :[
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            // Update recipient conversation entry
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipient_newConversation)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversation])
                }
            })
            
            // Update current user conversations entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // you should append
                conversations.append(newConversation)
                userNode["conversations"] = conversations
            } else {
                // conversation array does NOT exist
                // create it
                userNode["conversations"] = [
                    newConversation
                ]
            }
            
            ref.setValue(userNode, withCompletionBlock: {error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self?.finishCreatingConversation(name :name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
            })
        })
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        var message = ""
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        print("adding conversation: \(conversationID)")
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: {error,_ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /// Fetch and returns all conversations for the user with passed in email
    public func getAllConversations(for email:String, completion: @escaping (Result<[Conversation], Error>) -> Void){
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let lastestMessage = dictionary["lastest_message"] as? [String: Any],
                      let date = lastestMessage["date"] as? String,
                      let message = lastestMessage["message"] as? String,
                      let isRead = lastestMessage["is_read"] as? Bool else {
                          return nil
                      }
                let lastestMessageObject = LastestMessage(date: date,
                                                          text: message,
                                                          isRead: isRead)
                
                return Conversation(id: conversationID,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: lastestMessageObject)
            })
            
            completion(.success(conversations))
        })
    }
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id:String, completion: @escaping(Result<[Message], Error>)-> Void){
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                          return nil
                      }
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: .text(content))
            })
            
            completion(.success(messages))
        })
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message:Message, completion: @escaping (Bool) -> Void){
        
    }
    
}

public enum DatabaseError: Error {
    case failedToFetch
}

struct ChatAppUser {
    
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        return safeEmail
    }
    //    let profilePictureURL: String
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}

