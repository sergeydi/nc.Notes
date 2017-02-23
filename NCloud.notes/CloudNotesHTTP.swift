//
//  CloudNotesHTTP.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 25.01.17.
//  Copyright © 2017 Sergey Didanov. All rights reserved.
//

import Foundation
import Alamofire
import SwiftKeychainWrapper
import CoreData

class CloudNotesHTTP {
    static let instance = CloudNotesHTTP()
    
    let noteApiBaseURL = "/index.php/apps/notes/api/v0.2/notes"
    var authHeader: HTTPHeaders? {
        guard let username = KeychainWrapper.standard.string(forKey: "username"),
            let password = KeychainWrapper.standard.string(forKey: "password") else { return nil }
        var header: HTTPHeaders = [:]
        if let authorizationHeader = Request.authorizationHeader(user: username, password: password) {
            header[authorizationHeader.key] = authorizationHeader.value
        }
        return header
    }
    
    // Get all notes from server
    func getRemoteNotes(completeHandler:@escaping ([AnyObject]?, Bool) -> Void) {
        guard authHeader != nil, let serverName = KeychainWrapper.standard.string(forKey: "server") else { completeHandler(nil, false); return }
        let url = "https://" + serverName + noteApiBaseURL
        Alamofire.request(url, headers: authHeader).validate().responseJSON { response in
            if response.result.isSuccess {
                // If Success return JSON response from the server
                completeHandler(response.result.value as? [AnyObject], true)
            } else {
                completeHandler(nil, false)
            }
        }
    }
    
    func updateRemoteNotes(fromLocalNotes: [NSManagedObjectID], updateRemoteNotesHandler:@escaping (Bool) -> Void) {
        guard authHeader != nil,  let serverName = KeychainWrapper.standard.string(forKey: "server") else { updateRemoteNotesHandler(false); return }
        
        var updatedNotes = [AnyObject]()
        var updateRequests = fromLocalNotes.count {
            didSet {
                if updateRequests == 0 {
                    if updatedNotes.count > 0 {
                        CloudNotesModel.instance.updateLocalNotes(updatedNotes: updatedNotes)
                    }
                    updateRemoteNotesHandler(true)
                }
            }
        }
        
        for localNoteObjectID in fromLocalNotes {
            let localNote = CoreDataManager.instance.managedObjectContext.object(with: localNoteObjectID) as! Note
            let parameters: Parameters = ["content": localNote.content!, "modified" : localNote.modified]
            var url = ""
            var httpMethod: HTTPMethod
            if localNote.delete {
                print("Found note to delete")
                url = "https://" + serverName + noteApiBaseURL + "/\(localNote.id)"
                httpMethod = .delete
            } else {
                if localNote.id > 0 {
                    // URL for updating exist note
                    url = "https://" + serverName + noteApiBaseURL + "/\(localNote.id)"
                    httpMethod = .put
                } else {
                    // URL for adding new note
                    url = "https://" + serverName + noteApiBaseURL
                    httpMethod = .post
                    // Delete new local note withot ID
                    CoreDataManager.instance.deleteObject(object: localNote)
                }
            }
            
            Alamofire.request(url, method: httpMethod, parameters: parameters, headers: authHeader).validate().responseJSON { response in
                if response.result.isSuccess {
                    updatedNotes.append(response.result.value as AnyObject)
                    updateRequests -= 1
                } else {
                    updateRemoteNotesHandler(false)
                }
            }
        }
    }
}
