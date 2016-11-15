//  Nony
//
//  Created by Geemakun Storey on 2016-11-08.
//  Copyright © 2016 Razeware LLC. All rights reserved.

import UIKit
import Firebase

class ReportMessageViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var tellUsLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var submitButton: UIButton!
    
    var reportDescription: String?
    
    // MARK: Properties
    private var flags: [Flags] = []
    
    private lazy var flagsRef: FIRDatabaseReference = FIRDatabase.database().reference().child("flags")
    private var flagsRefHandle: FIRDatabaseHandle?
    var previousViewTitle: String = ""
    private func observFlags() {
        flagsRefHandle = flagsRef.observe(.childAdded, with: {(snapshot) -> Void in
            let flagData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let name = flagData["report"] as! String!, name.characters.count > 0 {
                self.flags.append(Flags(description: id, channelType: name))
            //    print("Submitted flag report")
            } else {
            //print("Not listening to new updates")
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Report"
        observFlags()
        self.descriptionTextView.delegate = self
    
        
        // Dismiss keyboarx
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ReportMessageViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.
    }
    
    deinit {
        if let refHandle = flagsRefHandle {
            flagsRef.removeObserver(withHandle: refHandle)
        }
    }
    
    @IBAction func submitAction(_ sender: Any) {
        previousViewTitle = navigationController!.previousViewController()!.title!
        
        if (descriptionTextView?.text.isEmpty)! {
            showAlert(title: "Whoops!", message: "Tell us what is wrong before submitting the report.")
            return
        } else {
            if let name = descriptionTextView?.text {
                let newFlagRef = flagsRef.childByAutoId()
                let flagItem = ["description": name, "channelType": previousViewTitle]
                newFlagRef.setValue(flagItem)
                showAlertReport(title: "Report Sent!", message: "We will look at it right away. Thank you.")
                
            }
        }
    }
    //Calls this function when the tap is recognized to dismiss keyboard
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            //self.chatRoomTextField.becomeFirstResponder()
            descriptionTextView.resignFirstResponder()
            return false
        }
        return true
    }
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {   //delegate method
//        chatRoomTextField.resignFirstResponder()
//        return true
//    }
    
    // Show alert when button tapped
    func showAlertReport(title: String, message: String?, style: UIAlertControllerStyle = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let dismissAction = UIAlertAction(title: "Okay", style: .default) { (action) in
            self.navigationController?.popViewController(animated: true)
            self.descriptionTextView.text = ""
        }
        alertController.addAction(dismissAction)
        
        present(alertController, animated: true, completion: nil)
    }
    // Show alert when button tapped
    func showAlert(title: String, message: String?, style: UIAlertControllerStyle = .alert) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let dismissAction = UIAlertAction(title: "Okay", style: .default) { (action) in
        }
        alertController.addAction(dismissAction)
        
        present(alertController, animated: true, completion: nil)
    }

}
extension UINavigationController {
    
    ///Get previous view controller of the navigation stack
    func previousViewController() -> UIViewController!{
        
        let lenght = self.viewControllers.count
        
        let previousViewController: UIViewController! = lenght >= 2 ? self.viewControllers[lenght-2] : nil
        
        return previousViewController
    }
    
}
