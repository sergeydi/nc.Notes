//
//  EditNoteViewController.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 25.01.17.
//  Copyright © 2017 Sergey Didanov. All rights reserved.
//

import UIKit
import CoreData

class EditNoteViewController: UIViewController {

    @IBOutlet weak var textEditView: UITextView!
    var note: NSManagedObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let noteText = note?.value(forKeyPath: "content") as? String else { return }
        textEditView.text = noteText
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
