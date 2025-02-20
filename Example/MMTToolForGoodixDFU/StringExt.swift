//
//  StringExt.swift
//  MMTToolForBluetooth_Example
//
//  Created by Macmini3 on 18/2/2025.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation

extension String? {
    
    var safeValue: String {
        return self ?? ""
    }
    
}
