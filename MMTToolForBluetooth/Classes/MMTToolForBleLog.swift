//
//  MMTToolForBleLog.swift
//  MMTToolForBluetooth
//
//  Created by Neal on 1/26/25.
//

import Foundation

public class MMTToolForBleLog: NSObject {
    
    static let share = MMTToolForBleLog()
    
    public enum Level {
        case error
        case warning
        case info
        case debug
        case verbose
        
        public var strValue: String {
            switch self {
            case .error:
                return "Error"
            case .warning:
                return "Warning"
            case .info:
                return "Info"
            case .debug:
                return "Debug"
            case .verbose:
                return "Verbose"
            }
        }
        
    }
    
    var logAction: ((_ msg: Any?, _ level: MMTToolForBleLog.Level, _ fileName: StaticString, _ lineCount: Int, _ functionName: StaticString)->())?
    
    public class func config(logAction: ((_ msg: Any?, _ level: MMTToolForBleLog.Level, _ fileName: StaticString, _ lineCount: Int, _ functionName: StaticString)->())?) {
        MMTToolForBleLog.share.logAction = logAction
    }
    
    class func log(_ msg: Any?, level: MMTToolForBleLog.Level = .debug, fileName: StaticString = #file, lineNumber: Int = #line, functionName: StaticString = #function) {
        MMTToolForBleLog.share.logAction?(msg, level, fileName, lineNumber, functionName)
    }
    
}

enum MMTLog {
    
    case error
    case warning
    case info
    case debug
    case verbose
    
    func log(_ msg: Any?, fileName: StaticString = #file, lineNumber: Int = #line, functionName: StaticString = #function) {
        switch self {
        case .error:
            MMTToolForBleLog.log(msg, level: .error, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .warning:
            MMTToolForBleLog.log(msg, level: .warning, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .info:
            MMTToolForBleLog.log(msg, level: .info, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .debug:
            MMTToolForBleLog.log(msg, level: .debug, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .verbose:
            MMTToolForBleLog.log(msg, level: .verbose, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        }
    }
    
}
