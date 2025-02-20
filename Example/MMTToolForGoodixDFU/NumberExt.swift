//
//  NumberExt.swift
//  MMTToolForBluetooth_Example
//
//  Created by Macmini3 on 18/2/2025.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation

extension Int? {
    
    var safeValue: Int {
        return self ?? 0
    }
    
}


extension Double? {
    
    var safeValue: Double {
        return self ?? 0.0
    }
    
}

