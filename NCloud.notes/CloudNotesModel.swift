//
//  HTTPClient.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 01.01.17.
//  Copyright © 2017 Sergey Didanov. All rights reserved.
//

import Foundation
import Alamofire
import CoreData



class CloudNotesModel {
    let noteApiBaseURL = "/index.php/apps/notes/api/v0.2/notes"
    

    
    // Check connection to remote server using credentials as arguments
    func connectToServerUsing(server: String, username: String, password: String, checkConnectionHandler:@escaping (Bool) -> Void) {
        // Custom Alamofire sessionManager for timout 5 se
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        let sessionManager = Alamofire.SessionManager(configuration: configuration)
        // Create headers for use Http plain authentication
        var headers: HTTPHeaders = [:]
        guard let authorizationHeader = Request.authorizationHeader(user: username, password: password) else { checkConnectionHandler(false); return }
        headers[authorizationHeader.key] = authorizationHeader.value
        // Build URL and make http-request
        let requestURL = "https://" + server + noteApiBaseURL
        Alamofire.request(requestURL, method: .get, headers: headers).validate().responseJSON { response in
            if response.result.isSuccess {
                self.addNotesToCoreData(notesArray: response.result.value as! [AnyObject])
                checkConnectionHandler(true)
            } else {
                print(response)
                checkConnectionHandler(false)
            }
        }
    }
    
    private func addNotesToCoreData(notesArray: [AnyObject]) {
        // Declare access to Managed Object Context(Database) and notesEntity(Table) for using Core Data
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let notesEntity = NSEntityDescription.entity(forEntityName: "Notes", in: managedContext)!
        // Save all received notes to managedContext
        for case let note as [String:AnyObject] in notesArray {
            // Insert new empty noteManagedObject(row) into Notes Entity(table)
            let noteManagedObject = NSManagedObject(entity: notesEntity, insertInto: managedContext)
            // Add note attributes to empty ManagedObject
            noteManagedObject.setValue(note["title"] as! String, forKeyPath: "title")
            noteManagedObject.setValue(note["content"] as! String, forKeyPath: "content")
            noteManagedObject.setValue(note["modified"] as! Int, forKeyPath: "modified")
            noteManagedObject.setValue(note["id"] as! Int, forKeyPath: "id")
            noteManagedObject.setValue(note["favorite"] as! Bool, forKeyPath: "favorite")
        }
        // Try to save all notes in Managed Object Context to CoreData
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    // Delete all notes ONLY!!! from CoreData
    func deleteAllNotes() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Notes")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        do {
            try managedContext.execute(deleteRequest)
        } catch let error as NSError {
            print(error)
        }
    }
}


