//  Nony
//
//  Created by Geemakun Storey on 2016-11-08.
//  Copyright © 2016 Razeware LLC. All rights reserved.

import UIKit
import Firebase
import JSQMessagesViewController
import Photos

final class ChatViewController: JSQMessagesViewController {
    
  // MARK: Properties
    var messages = [JSQMessage]()
    var channelRef: FIRDatabaseReference?
    var channel: Channel? {
        didSet {
            title = channel?.name
        }
    }
    //var deleteMessagesTimer: Timer!
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://chatfirebasetutorial-aa7f5.appspot.com")
    private let imageURLNotSetKey = "NOTSET"
    // This holds an array of JSQMediaitems
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    private var updatedMessageRefHandle: FIRDatabaseHandle?
  // MARK: View Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //messageCountDelegate?.messageCount
    //deleteMessagesTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
    
    //JSQMessagesCollectionViewCell.registerMenuAction(#selector(UIResponderStandardEditActions.delete(_:)))
    self.senderId = FIRAuth.auth()?.currentUser?.uid
    self.inputToolbar.contentView.leftBarButtonItem = nil
    
    // No avatars
    collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
    collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
    
    observeMessages()
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    observeTyping()
  }
    deinit {
        if let refHandle = newMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
        
        if let refHandle = updatedMessageRefHandle {
            messageRef.removeObserver(withHandle: refHandle)
        }
    }
  
  // MARK: Collection view data source (and related) methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
  
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView, didTapMessageBubbleAt indexPath: IndexPath) {
        // Alert user if they tap on a text bubble, prompt them if they want to report a certain message
        showAlert("Report Message?", message: "If you think this message is inappropiate, our mods will investigate.", style: .alert)
    }
    
  // MARK: Firebase related methods
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef.childByAutoId() //Using childByAutoId(), you create a child reference with a unique key
        let messageItem = [ // Then you create a dictionary to represent the message
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
        ]
        itemRef.setValue(messageItem) //Save the value at the new child location
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        isTyping = false
    }
  
  // MARK: UI and User Interaction
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    private lazy var messageRef: FIRDatabaseReference = self.channelRef!.child("messages")
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    private func observeMessages() {
        messageRef = channelRef!.child("messages")
        //Start by creating a query that limits the synchronization to the last 25 messages
        let messageQuery = messageRef.queryLimited(toLast: 25)
        // Use the .ChildAdded event to observe for every child item that has been added, and will be added, at the messages location.
        newMessageRefHandle = messageQuery.observe(.childAdded, with: {(snapshot) -> Void in
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                // 4
                self.addMessage(withId: id, name: name, text: text)
                
                // 5
                self.finishReceivingMessage()
            }
            else {
                print("Error! Could not decode message data")
            }
        })
    }
    private lazy var userIsTypingRef: FIRDatabaseReference =
        self.channelRef!.child("typingIndicator").child(self.senderId) // Create a Firebase reference that tracks whether the local user is typing.
    private var localTyping = false // Store whether the local user is typing in a private property
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // Use a computed property to update localTyping and userIsTypingRef each time it’s changed
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    private lazy var usersTypingQuery: FIRDatabaseQuery = self.channelRef!.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    
    private func observeTyping() {
        let typingIndicatorRef = channelRef!.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child("senderId")
        userIsTypingRef.onDisconnectRemoveValue()
        
        // 1
        usersTypingQuery.observe(.value) { (data: FIRDataSnapshot) in
            // 2 You're the only one typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            // 3 Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        
    }
}
    
  // MARK: UITextViewDelegate methods
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        // print(textView.text != "")
        isTyping = textView.text != ""
    }
    
    func showAlert(_ title: String, message: String?, style: UIAlertControllerStyle = .actionSheet) {
        let alertController = UIAlertController(title: "Report Message?", message: "If you think this message is inappropiate, our mods will investigate.\n Continue to report?", preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "No", style: .cancel)
        alertController.addAction(cancelAction)
        
        let OKAction = UIAlertAction(title: "Report", style: .destructive) { (action) in
            // Navigate here to new view controller to report message, then save to databse
            let viewController:UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController2") as UIViewController
           self.navigationController?.pushViewController(viewController, animated: true)
        }
        alertController.addAction(OKAction)
        
        self.present(alertController, animated: true)
    }
    
    // Delete messages from database function
//    func runTimedCode() {
//        print("Deleting messages...")
//        //messageRef.removeValue()
//        collectionView.reloadData()
//    }
 
}
