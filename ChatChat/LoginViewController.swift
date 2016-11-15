//  Nony
//
//  Created by Geemakun Storey on 2016-11-08.
//  Copyright © 2016 Razeware LLC. All rights reserved.

import UIKit
import Firebase

class LoginViewController: UIViewController, AnonUserKeys {
  
  var anonKeyValue: Bool = false
  var anonUID: String = ""
    
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
    
   required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
   
// MARK: View Lifecycle
  
    override func viewDidLoad() {
        
        // Bypass login if user device already registerd
        FIRAuth.auth()!.addStateDidChangeListener() { auth, user in
            if user != nil {
                let isAnonymous = user!.isAnonymous  // true
                let uid = user!.uid
                self.anonKeyValue = isAnonymous
                self.anonUID = uid
                // Send userData to next view controller
               // self.performSegue(withIdentifier: "LoginToChat", sender: nil)
            }
        }
    }
    
    
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHideNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }
  
  @IBAction func loginDidTouch(_ sender: AnyObject) {
    if nameField?.text != "" {
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            if let err = error {
                print(err.localizedDescription)
                return
            }
            let isAnonymous = user!.isAnonymous  // true
            let uid = user!.uid
            self.anonKeyValue = isAnonymous
            self.anonUID = uid
            
            self.performSegue(withIdentifier: "LoginToChat", sender: nil)
            
        })
    }
}
  
  // MARK: - Keyboard Notifications
  func keyboardWillShowNotification(_ notification: Notification) {
    let keyboardEndFrame = ((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)
    bottomLayoutGuideConstraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY
  }
  
  func keyboardWillHideNotification(_ notification: Notification) {
    bottomLayoutGuideConstraint.constant = 48
  }
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        let navVc = segue.destination as! UINavigationController
        let channelVc = navVc.viewControllers.first as! ChannelListViewController
        
        channelVc.senderDisplayName = nameField?.text
    }
  
}

