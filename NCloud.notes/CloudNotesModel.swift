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
    static let instance = CloudNotesModel()
    
//    func syncLocalNotesToRemote(remoteNotes: [AnyObject], completeHandler:@escaping (Bool) -> Void) {
//        let localNotes = getNotesFromCoreData()
//        for localNote in localNotes {
//            
//        }
//    }
    
    func getLocalNotes() -> [Note] {
        var unsortedNotes = [Note]()
        let fetchRequest = NSFetchRequest<Note>(entityName: "Note")
        // Get notes from CoreData, sort by modofication time and store to notes
        do {
            unsortedNotes = try CoreDataManager.instance.managedObjectContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return unsortedNotes.count > 0 ? sortNotesByTimestamp(notes: unsortedNotes) : unsortedNotes
    }
    
    func syncRemoteNotesToLocal(remoteNotes: [AnyObject]) {
        var newNotes = [AnyObject]()
        var updatedNotes = [AnyObject]()
        var notesToDelete = [Note]()
        let localNotesDict = convertLocalNotesToDictionaryByID(notes: getLocalNotes())
        let remoteNotesDict = convertRemoteNotesToDictionaryByID(notes: remoteNotes)
        // Remove deleted notes
        for (key, value) in localNotesDict {
            if remoteNotesDict[key] == nil {
               notesToDelete.append(value as! Note)
            }
        }
        // Updated current or add new notes
        for case let remoteNote as [String:AnyObject] in remoteNotes {
            // If exist local note for remote note
            if let localNote = localNotesDict[remoteNote["id"] as! Int] {
                // If remote note newer then local
                if (localNote.value(forKeyPath: "modified") as? Int)! < remoteNote["modified"] as! Int {
                    // Update it to CoreData
                    print("Find note with new version")
                    updatedNotes.append(remoteNote as AnyObject)
                }
            } else {
                // Add new note to CoreData
                newNotes.append(remoteNote as AnyObject)
            }
        }
        if newNotes.count > 0 {
            saveRemoteNotes(notesArray: newNotes)
        }
        if updatedNotes.count > 0 {
            updateCoreDataNotes(updatedNotes: updatedNotes)
        }
        if notesToDelete.count > 0 {
            deleteLocalNotes(notes: notesToDelete)
        }
    }
    
    func deleteLocalNotes(notes: [Note]) {
        // Delete notes from context
        for oldNote in notes {
            CoreDataManager.instance.deleteObject(object: oldNote)
        }
        CoreDataManager.instance.saveContext()
    }
    
    func updateCoreDataNotes(updatedNotes: [AnyObject]) {
        print("Update notes")
        var localNotes = [Note]()
        let fetchRequest = NSFetchRequest<Note>(entityName: "Notes")
        // Get notes from CoreData to localNotes and convert to dictionary [ID:Note]
        do {
            localNotes = try CoreDataManager.instance.managedObjectContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        let localNotesDictionary = convertLocalNotesToDictionaryByID(notes: localNotes)
        // Remove old notes from CoreData
        for case let updatedNote as [String:AnyObject] in updatedNotes {
            CoreDataManager.instance.managedObjectContext.delete(localNotesDictionary[(updatedNote["id"] as! Int)]!)
        }
        CoreDataManager.instance.saveContext()
        // Save updated notes to CoreData
        saveRemoteNotes(notesArray: updatedNotes)
    }
    
    
    // Convert [NSManagedObject] array to [note_id:NSManagedObject] dictionary
    private func convertLocalNotesToDictionaryByID(notes: [Note]) -> [Int:Note] {
        var dictionary = [Int:Note]()
        for note in notes {
            dictionary[(note.value(forKeyPath: "id") as? Int)!] = note
        }
        return dictionary
    }
    
    // Convert [AnyObject] to [id:AnyObject]
    private func convertRemoteNotesToDictionaryByID(notes: [AnyObject]) -> [Int:AnyObject] {
        var dictionary = [Int:AnyObject]()
        for case let note as [String:AnyObject] in notes {
            dictionary[note["id"] as! Int] = note as AnyObject?
        }
        return dictionary
    }
    
    private func sortNotesByTimestamp(notes: [Note]) -> [Note]{
        var unsortedNotes = [Int:Note]()
        var sortedNotes = [Note]()
        for note in notes {
            unsortedNotes[(note.value(forKeyPath: "modified") as? Int)!] = note
        }
        for (_, value) in unsortedNotes.sorted(by: { $0.0 > $1.0 }) {
            sortedNotes.append(value)
        }
        return sortedNotes
    }
    
    func saveRemoteNotes(notesArray: [AnyObject]) {
        // Save all received notes to managedContext
        for case let note as [String:AnyObject] in notesArray {
            // Insert new empty noteManagedObject(row) into Notes Entity(table)
            let noteManagedObject = Note()
            // Add note attributes to empty ManagedObject
            noteManagedObject.title = note["title"] as? String
            noteManagedObject.content = note["content"] as? String
            noteManagedObject.modified = Int64(note["modified"] as! Int)
            noteManagedObject.id = Int64(note["id"] as! Int)
            noteManagedObject.favorite = note["favorite"] as! Bool
        }
        // Try to save all notes to CoreData
        CoreDataManager.instance.saveContext()
    }
    
    // Delete all notes ONLY!!! from CoreData
    func deleteAllNotes() {
        let fetchRequest = NSFetchRequest<Note>(entityName: "Note")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        do {
            try CoreDataManager.instance.managedObjectContext.execute(deleteRequest)
        } catch let error as NSError {
            print(error)
        }
    }
}


