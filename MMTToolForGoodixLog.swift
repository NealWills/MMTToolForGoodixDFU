//
//  MMTToolForGoodixLog.swift
//  MMTToolForGoodixDFU
//
//  Created by Macmini3 on 21/2/2025.
//

import Foundation

public class MMTToolForGoodixLog: NSObject {
    
    static let share = MMTToolForGoodixLog()
    
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
    
    var logAction: ((_ msg: Any?, _ level: MMTToolForGoodixLog.Level, _ fileName: StaticString, _ lineCount: Int, _ functionName: StaticString)->())?
    
    public class func config(logAction: ((_ msg: Any?, _ level: MMTToolForGoodixLog.Level, _ fileName: StaticString, _ lineCount: Int, _ functionName: StaticString)->())?) {
        MMTToolForGoodixLog.share.logAction = logAction
    }
    
    class func log(_ msg: Any?, level: MMTToolForGoodixLog.Level = .debug, fileName: StaticString = #file, lineNumber: Int = #line, functionName: StaticString = #function) {
        MMTToolForGoodixLog.share.logAction?(msg, level, fileName, lineNumber, functionName)
    }
    
}

public enum MMTGoodixLog {
    
    case error
    case warning
    case info
    case debug
    case verbose
    
    public func log(_ msg: Any?, fileName: StaticString = #file, lineNumber: Int = #line, functionName: StaticString = #function) {
        switch self {
        case .error:
            MMTToolForGoodixLog.log(msg, level: .error, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .warning:
            MMTToolForGoodixLog.log(msg, level: .warning, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .info:
            MMTToolForGoodixLog.log(msg, level: .info, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .debug:
            MMTToolForGoodixLog.log(msg, level: .debug, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        case .verbose:
            MMTToolForGoodixLog.log(msg, level: .verbose, fileName: fileName, lineNumber: lineNumber, functionName: functionName)
        }
    }
    
}
