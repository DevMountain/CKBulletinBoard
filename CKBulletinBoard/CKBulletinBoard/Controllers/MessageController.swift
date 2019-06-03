//
//  MessageController.swift
//  CKBulletinBoard
//
//  Created by Karl Pfister on 6/3/19.
//  Copyright © 2019 Karl Pfister. All rights reserved.
//

import Foundation
import CloudKit

class MessageController {
    static let sharedInstance = MessageController()
    var messages: [Message] = []
    let privateDB = CKContainer.default().privateCloudDatabase
    
    // CRUD
    func createMessageWith(text: String, timestamp: Date) {
        let message = Message(text: text, timestamp: timestamp)
        self.save(message: message) { (_) in
            // No error handling
        }
    }
    
//    func updateMessage(message: Message, text: String, timestamp: Date, completion: @escaping (Bool) -> Void){
//        
//        // Update the message Locally
//        message.text = text
//        message.timestamp = timestamp
//        
//        privateDB.fetch(withRecordID: message.ckRecordID) { (record, error) in
//            if let error = error {
//                print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
//                completion(false)
//                return
//            }
//            guard let record = record else {completion(false); return}
//            record[Constants.textKey] = text
//            record[Constants.timestampKey] = timestamp
//            
//            let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
//            operation.savePolicy = .changedKeys
//            operation.queuePriority = .high
//            operation.qualityOfService = .userInitiated
//            operation.modifyRecordsCompletionBlock = { (records, reordIDs, error) in
//                completion(true)
//            }
//            self.privateDB.add(operation)
//        }
//    }
    
    func deleteMessage(message: Message, completion: @escaping (Bool) -> ()){
        // Remove locally
        guard let index = MessageController.sharedInstance.messages.firstIndex(of: message) else {return}
        MessageController.sharedInstance.messages.remove(at: index)
        // Delete from Cloud
        privateDB.delete(withRecordID: message.ckRecordID) { (_, error) in
            if let error = error{
                print("\(error.localizedDescription) \(error) in function: \(#function)")
                completion(false)
                return
            }else {
                print("Record Deleted from CloudKit")
                completion(true)
            }
        }
    }
    
    func save(message: Message, completion: @escaping (Bool)-> ()){
        let messageRecord = CKRecord(messge: message)
        privateDB.save(messageRecord) { (record, error) in
            if let error = error {
                print("💩  There was an error in \(#function) ; \(error)  ; \(error.localizedDescription)  💩")
                completion(false)
                return
            }
            guard let record = record, let message = Message(ckRecord: record) else { completion(false); return}
            self.messages.append(message)
            completion(true)
        }
    }
    
    func fetchMessages(completion: @escaping (Bool) -> ()){
        let predicate = NSPredicate(value: true)
        let querry = CKQuery(recordType: Constants.recordKey, predicate: predicate)
        
        privateDB.perform(querry, inZoneWith: nil) { (records, error) in
            if let error = error{
                print("\(error.localizedDescription) \(error) in function: \(#function)")
                completion(false)
                return
            }
            
            guard let records = records else {completion(false) ; return}
            let messages = records.compactMap{ Message(ckRecord: $0)}
            self.messages = messages
            completion(true)
        }
    }
    
}// End of class
