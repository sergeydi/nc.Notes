//
//  EditNoteViewController.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 25.01.17.
//  Copyright © 2017 Sergey Didanov. All rights reserved.
//

import UIKit
import CoreData

class EditNoteViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var textEditView: UITextView!
    var noteID: NSManagedObjectID!
    var note: Note!
    lazy var shareButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(EditNoteViewController.shareNote))
    lazy var finishEditButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(EditNoteViewController.exitEditMode))
    lazy var deleteNoteButton: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "DeleteNote"), style: .plain, target: self, action: #selector(EditNoteViewController.deleteNote))
    let cloudNotesModel = CloudNotesModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Finish edit text button
        navigationItem.setRightBarButtonItems([finishEditButton, shareButton, deleteNoteButton], animated: true)
        finishEditButton.isEnabled = false
        note = CoreDataManager.instance.managedObjectContext.object(with: noteID) as! Note
        // Load text from note to textEditView
        textEditView.text = note?.content
        textEditView.delegate = self
    }
    
    // Detect when note begin editing
    func textViewDidBeginEditing(_ textView: UITextView) {
        finishEditButton.isEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Save or update local note if did any changes
        if note?.content != textEditView.text || textEditView.text.characters.count == 0 {
            saveNote()
        }
    }
    
    func deleteNote() {
        if note.id > 0 {
            note.delete = true
            CoreDataManager.instance.saveContext()
        } else {
            CoreDataManager.instance.deleteObject(object: note)
        }
        _ = navigationController?.popViewController(animated: true)
    }
    
    func saveNote() {
        note?.modified = Int64(Date().timeStamp)
        note?.content = textEditView.text
        if textEditView.text.characters.count > 0 {
            note?.title = textEditView.text.lines[0]
        }
        if note?.id == nil {
            note?.id = 0
        }
        CoreDataManager.instance.saveContext()
    }
    
    func shareNote() {
        let shareViewController = UIActivityViewController(activityItems: [textEditView.text as String], applicationActivities: nil)
        present(shareViewController, animated: true, completion: {})
    }
    
    // Exit textEditView from edit mode
    func exitEditMode() {
        textEditView.endEditing(true)
        finishEditButton.isEnabled = false
    }
    
    // Scroll textEditView on top
    override func viewDidLayoutSubviews() {
        self.textEditView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        print("EditNoteViewController deinited")
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension String {
    var lines: [String] { return self.components(separatedBy: .newlines) }
}
