//
//  SettingsTableViewController.swift
//  NCloud.notes
//
//  Created by Sergey Didanov on 29.12.16.
//  Copyright © 2016 Sergey Didanov. All rights reserved.
//

import UIKit
import MessageUI
import SwiftKeychainWrapper

class SettingsTableViewController: UITableViewController {
    let userDefaults = UserDefaults.standard
    @IBOutlet weak var serverNameLabel: UILabel!
    @IBOutlet weak var syncOnStartSwitch: UISwitch!
    @IBAction func CloseSettingView(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        syncOnStartSwitch.addTarget(self, action: #selector(SettingsTableViewController.switchChanged(_:)), for: UIControlEvents.valueChanged)
    }
    
    func switchChanged(_ mySwitch: UISwitch) {
        if mySwitch.isOn {
            if KeychainWrapper.standard.string(forKey: "server") != nil {
                userDefaults.set(true, forKey: "syncOnStart")
            } else {
                showAlert(withMessage: "First connect to server!")
                syncOnStartSwitch.setOn(false, animated: true)
            }
        } else {
            userDefaults.removeObject(forKey: "syncOnStart")
        }
    }

    func showAlert(withMessage message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("View will appear")
        // syncOnStartSwitch part
        if userDefaults.object(forKey: "syncOnStart") != nil {
            syncOnStartSwitch.setOn(true, animated: false)
        }
        // serverNameLabel part
        if UserDefaults.standard.object(forKey: "loggedIn") as? Bool != nil {
            if let serverName = KeychainWrapper.standard.string(forKey: "server") {
                serverNameLabel.text = serverName
            }
        } else {
            serverNameLabel.text =  "Not logged in"
            syncOnStartSwitch.setOn(false, animated: false)
        }
    }
    
    deinit {
        print("SettingsTableViewController deinited")
    }
}

// Send mail extension
extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Contact button tapped
        if indexPath.section == 1 {
            if MFMailComposeViewController.canSendMail(){
                let mailComposeVC = MFMailComposeViewController()
                mailComposeVC.mailComposeDelegate = self
                mailComposeVC.setToRecipients(["support@didanov.com"])
                mailComposeVC.setSubject("NCloud.notes issue")
                present(mailComposeVC, animated: true, completion: nil)
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
