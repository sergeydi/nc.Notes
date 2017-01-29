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
    var note: NSManagedObject?
    var finishEditButton: UIBarButtonItem!
    lazy var shareButton:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(EditNoteViewController.shareNote))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Finish edit text button
        finishEditButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(exitEditMode))
        navigationItem.setRightBarButtonItems([finishEditButton, shareButton], animated: true)
        finishEditButton.isEnabled = false
        // Load text from note to textEditView
        guard let noteText = note?.value(forKeyPath: "content") as? String else { return }
        textEditView.text = noteText
        textEditView.delegate = self
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        finishEditButton.isEnabled = true
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
