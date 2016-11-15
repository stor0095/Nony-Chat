//  Nony
//
//  Created by Geemakun Storey on 2016-11-08.
//  Copyright © 2016 Razeware LLC. All rights reserved.

import UIKit
import Firebase

enum Section: Int {
    case createNewChannelSection = 0
    case currentChannelsSection
}

class ChannelListViewController: UITableViewController {
    
    // MARK: Properties
    var senderDisplayName: String?
    var channelTextField: UITextField?
    private var channels: [Channel] = []
    //channelRef will be used to store a reference to the list of channels in the database 
    //channelRefHandle will hold a handle to the reference so you can remove it later on.
    private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference().child("channels")
    private var channelRefHandle: FIRDatabaseHandle?
    //refernce to messages
    private lazy var messageRef: FIRDatabaseReference = self.channelRef.child("messages")
    
    let usersRef = FIRDatabase.database().reference(withPath: "online")
    var user: User!
    var userCountBarButtonItem: UIBarButtonItem!
    
    // MARK: TableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currentSection: Section = Section(rawValue: section) {
            switch currentSection {
            case .createNewChannelSection:
                return 0
            case .currentChannelsSection:
                return channels.count
            }
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue ? "NewChannel" : "ExistingChannel"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if (indexPath as NSIndexPath).section == Section.createNewChannelSection.rawValue {
            if let createNewChannelCell = cell as? CreateChannelCell {
                channelTextField = createNewChannelCell.newChannelNameField
            }
        } else if (indexPath as NSIndexPath).section == Section.currentChannelsSection.rawValue {
            
            let cellName = channels[(indexPath as NSIndexPath).row].name
            let cellID = channels[(indexPath as NSIndexPath).row].id
            cell.textLabel?.text = cellName
            // Get cell ID to determine what the chatroom name is
            // Once id and chatroom name are found, count the total number of messages to display
            let keepTrack = channelRef.child(cellID).child("messages")
            keepTrack.observe(.value, with: {(snapshot: FIRDataSnapshot!) in
                cell.detailTextLabel?.text = String(snapshot.childrenCount)
            })
        }
        return cell
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userCount()
        self.tableView.reloadData()
    }
    
    // MARK: FIrebase related methods
//    You call observe:with: on your channel reference, storing a handle to the reference. This calls the completion block every time a new channel is added to your database.
//    The completion receives a FIRDataSnapshot (stored in snapshot), which contains the data and other helpful methods.
//    You pull the data out of the snapshot and, if successful, create a Channel model and add it to your channels array.
    private func observeChannels() {
    // Use the observe method to listen for new channels being written to the Firebase DB
        channelRefHandle = channelRef.observe(.childAdded, with: {(snapshot) -> Void in
            let channelData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let name = channelData["name"] as! String!, name.characters.count > 0 {
                self.channels.append(Channel(id: id, name: name))
                self.tableView.reloadData()
            } else {
            print("Error, count not decode channel data")
            }
        })
    }

    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chatrooms"
        observeChannels()
        userCount()
        if(UserDefaults.standard.bool(forKey: "HasLaunchedOnce")) {
            // App has launched before
            print("App has launched before")
        }
        else {
            // This is the first launch ever
            print("First launch ever")
            UserDefaults.standard.set(true, forKey: "HasLaunchedOnce")
            UserDefaults.standard.synchronize()
            
            showAlert("Want a quick tour?", message: nil)
        }
        
    }
    deinit {
        if let refHandle = channelRefHandle {
            channelRef.removeObserver(withHandle: refHandle)
        }
    }
    
    // MARK :Actions
    @IBAction func createChannel(_ sender: AnyObject) {
        if let name = channelTextField?.text { // First check if you have a channel name in the text field.
            let newChannelRef = channelRef.childByAutoId() // Create a new channel reference with a unique key using childByAutoId().
            let channelItem = [ // Create a dictionary to hold the data for this channel
                "name": name
            ]
            newChannelRef.setValue(channelItem) //set the name on this new channel, which is saved to Firebase automatically
            channelTextField?.text = ""
        }
    }

    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Section.currentChannelsSection.rawValue {
            let channel = channels[(indexPath as NSIndexPath).row]
            self.performSegue(withIdentifier: "ShowChannel", sender: channel)
            
        }
    }
    
    var detailLabelCount = ExistingChannelCell()
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let channel = sender as? Channel {
            let chatVC = segue.destination as! ChatViewController
            // Set up the proprties
            
            chatVC.senderDisplayName = senderDisplayName
            chatVC.channel = channel
            chatVC.channelRef = channelRef.child(channel.id)
        }
    }
    
    @IBAction func refreshAction(_ sender: Any) {
        userCount()
     refreshControl?.endRefreshing()
    }
    
    func userCount() {
        userCountBarButtonItem = UIBarButtonItem(title: "Users: 0",
                                                 style: .plain,
                                                 target: self,
                                                 action: nil)
        userCountBarButtonItem.tintColor = UIColor.black
        navigationItem.leftBarButtonItem = userCountBarButtonItem
        
        usersRef.observe(.value, with: { snapshot in
            if snapshot.exists() {
                self.userCountBarButtonItem?.title = "Users: \(snapshot.childrenCount.description)"
            } else {
                self.userCountBarButtonItem?.title = "0"
            }
        })
        FIRAuth.auth()!.addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)
            
            let currentUserRef = self.usersRef.child(self.user.uid)
            currentUserRef.setValue(self.user.anonKeyBool)
            currentUserRef.onDisconnectRemoveValue()
        }
    }
    func showAlert(_ title: String, message: String?, style: UIAlertControllerStyle = .alert) {
        let alertController = UIAlertController(title: "Want a quick tour of our app?", message: nil, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel)
        alertController.addAction(cancelAction)
        
        let OKAction = UIAlertAction(title: "Yes", style: .default) { (action) in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "infoViewController")
            self.present(controller, animated: true, completion: nil)
        }
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true)
    }
}
