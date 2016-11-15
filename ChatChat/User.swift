//
//  User.swift
//  Nony
//
//  Created by Geemakun Storey on 2016-11-08.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import Foundation
import Firebase

struct User {
    
    let uid: String
    let anonKeyBool: Bool
    
    init(authData: FIRUser) {
        uid = authData.uid
        anonKeyBool = authData.isAnonymous
    }
    
    init(uid: String, anonKeyBool: Bool) {
        self.uid = uid
        self.anonKeyBool = anonKeyBool
    }
}


