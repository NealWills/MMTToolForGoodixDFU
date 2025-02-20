//
//  DictionaryExt.swift
//  MMTToolForBluetooth_Example
//
//  Created by Macmini3 on 18/2/2025.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation

extension Dictionary {
    
    func sortAsciiDescription() -> String {
        
        let list = self.map({
            return (key: $0.key, value: $0.value)
        }).sorted(by: {
//            let key0 = "\($0.key)".first ?? "0"
//            let key1 = "\($1.key)".first ?? "1"
            let key0 = "\($0.key)"
            let key1 = "\($1.key)"
            return key0 < key1
        })
        var title = "[" + "\n"
        list.forEach({
            if let params = $0.value as? [String: Any] {
                title = title + "    \($0.key)" + ": " + params.sortAsciiDescription() + "\n"
            } else {
                title = title + "    \($0.key)" + ": " + "\($0.value)" + "\n"
            }
        })
        title = title + "]"
        return title
    }
    
}
