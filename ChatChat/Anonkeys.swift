//
//  Anonkeys.swift
//  Nony
//
//  Created by Geemakun Storey on 2016-11-08.
//  Copyright © 2016 Razeware LLC. All rights reserved.
//

import Foundation

protocol AnonUserKeys {
    var anonKeyValue: Bool { get }
    var anonUID: String { get }
}

protocol MessageCount {
    var messageCount: Int {get set}
}
