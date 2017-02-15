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
        
        var updateRequests = fromLocalNotes.count {
            didSet {
                if updateRequests == 0 {
                    updateRemoteNotesHandler(true)
                }
            }
        }
        
        for localNoteID in fromLocalNotes {
            let localNote = CoreDataManager.instance.managedObjectContext.object(with: localNoteID) as! Note
            let parameters: Parameters = ["content": localNote.content!]
            let url = "https://" + serverName + noteApiBaseURL + "/\(localNote.id)"
            
            Alamofire.request(url, method: .put, parameters: parameters, headers: authHeader).validate().responseJSON { response in
                if response.result.isSuccess {
                    updateRequests -= 1
                } else {
                    updateRemoteNotesHandler(false)
                }
            }
        }
    }
}
