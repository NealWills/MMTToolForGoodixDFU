//
//  MMTToolForGoodixDFUTool.swift
//  MMTToolForGoodixDFU
//
//  Created by Macmini3 on 20/2/2025.
//

import Foundation
import MMTToolForBluetooth

class MMTToolForGoodixWeakDelegateUnit: NSObject {
    weak var weakDelegate: MMTToolForGoodixDFUDelegate?
    
    init(weakDelegate: MMTToolForGoodixDFUDelegate? = nil) {
        self.weakDelegate = weakDelegate
    }
}

public protocol MMTToolForGoodixDFUDelegate: NSObject {
    
    func mmtToolForGoodixUnitDidEnter(_ unit: MMTToolForGoodixDFUToolUnit?)
    func mmtToolForGoodixUnitDidFailToEnter(_ unit: MMTToolForGoodixDFUToolUnit?, error: Error?)
    func mmtToolForGoodixUnitDFUDidBegin(_ unit: MMTToolForGoodixDFUToolUnit?)
    func mmtToolForGoodixUnitDFUDidChangeProgress(_ unit: MMTToolForGoodixDFUToolUnit?)
    func mmtToolForGoodixUnitDFUDidEnd(_ unit: MMTToolForGoodixDFUToolUnit?, error: Error?)
    
    typealias DFUServerTurple = (
        service: MMTService?,
        readCharacter: MMTCharacteristic?,
        writeCharacter: MMTCharacteristic?,
        controlCharacter: MMTCharacteristic?
    )
    func mmtToolForGoodixUnitGetUUID(_ unit: MMTToolForGoodixDFUToolUnit?) -> DFUServerTurple?
    
}

public class MMTToolForGoodixDFUTool: NSObject {

    static let share = MMTToolForGoodixDFUTool()
    var multiDelegateList: [MMTToolForGoodixWeakDelegateUnit] = .init()
    var unitList: [MMTToolForGoodixDFUToolUnit] = .init()
    
    public class func configManager() {
        MMTToolForGoodixDFUFileManager.removeTempDir()
    }
    
    public class func startDfu(device: MMTToolForBleDevice, startAddress: String?, filePath: String?) {
        let unit = MMTToolForGoodixDFUToolUnit.init()
        
        guard let deviceMac = device.mac?.uppercased() else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Device Not Exist"))
            return
        }
        
        unit.deviceMac = deviceMac.uppercased()
        unit.deviceMacExtra = device.macExtra?.uppercased()
        unit.deviceUUID = device.peripheral.identifier.uuidString.uppercased()
        
        guard let filePath = filePath else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
            return
        }
        
        if filePath.count < 4 {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
            return
        }
        unit.dfuFilePath = filePath
        
        let isExist = FileManager.default.fileExists(atPath: filePath)
        if !isExist {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
            return
        }
        MMTToolForGoodixDFUFileManager.copyDFUFileToTempDir(originPath: filePath, deviceMac: deviceMac)
        guard let startAddress = startAddress else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Start Address Unit Not Exist"))
            return
        }
        unit.startAddress = startAddress
        
        let isContain = MMTToolForGoodixDFUTool.share.unitList.contains(where: {
            return $0.deviceMac?.uppercased() == device.mac?.uppercased()
        }) ?? false
        if isContain {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Unit Exist"))
            return
        }
        guard let turple = MMTToolForGoodixDFUTool.sendDelegateUnitDFUGetUUID(unit) else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Delegate Not Exist"))
            return
        }
        guard let service = turple.service else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Service Not Exist"))
            return
        }
        guard let readCharacter = turple.readCharacter else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "ReadCharacter Not Exist"))
            return
        }
        guard let writeCharacter = turple.writeCharacter else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "WriteCharacter Not Exist"))
            return
        }
        guard let controlCharacter = turple.controlCharacter else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "ControlCharacter Not Exist"))
            return
        }
        unit.localServiceUUID = service.uuid.uuidString.uppercased()
        unit.localReadCharacterUUID = readCharacter.uuid.uuidString.uppercased()
        unit.localWriteCharacterUUID = writeCharacter.uuid.uuidString.uppercased()
        unit.localControlCharacterUUID = controlCharacter.uuid.uuidString.uppercased()
        unit.startTimeStamp = Date().timeIntervalSince1970
        MMTToolForGoodixDFUTool.share.unitList.append(unit)
        MMTToolForGoodixDFUTool.sendDelegateUnitDidEnter(unit)
        unit.startDfu()
    }
    
}

public extension MMTToolForGoodixDFUTool {
    
    class func addDelegate(_ delegate: MMTToolForGoodixDFUDelegate?) {
        guard let delegate = delegate else { return }
        let delegateId = String.init(format: "%p", delegate)
        var list = MMTToolForGoodixDFUTool.share.multiDelegateList
        list = list.filter {
            return $0.weakDelegate != nil
        }
        if list.contains(where: {
            if let item = $0.weakDelegate {
                let id0 = String.init(format: "%p", item)
                return id0 == delegateId
            }
            return false
        }) {
            return
        }
        let delegateUnit = MMTToolForGoodixWeakDelegateUnit.init(weakDelegate: delegate)
        list.append(delegateUnit)
        MMTToolForGoodixDFUTool.share.multiDelegateList = list
    }
    
    class func removeDelegate(_ delegate: MMTToolForGoodixDFUDelegate?) {
        guard let delegate = delegate else { return }
        let delegateId = String.init(format: "%p", delegate)
        var list = MMTToolForGoodixDFUTool.share.multiDelegateList
        list = list.filter {
            guard let item = $0.weakDelegate else {
                return false
            }
            let id0 = String.init(format: "%p", item)
            return id0 != delegateId
        }
        MMTToolForGoodixDFUTool.share.multiDelegateList = list
    }
    
    class func sendDelegateUnitDidEnter(_ unit: MMTToolForGoodixDFUToolUnit?) {
        let list = MMTToolForGoodixDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForGoodixUnitDidEnter(unit)
        })
    }
    
    class func sendDelegateUnitDidFailToEnter(_ unit: MMTToolForGoodixDFUToolUnit?, error: Error?) {
        let list = MMTToolForGoodixDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForGoodixUnitDidFailToEnter(unit, error: error)
        })
    }
    
    class func sendDelegateUnitDFUDidBegin(_ unit: MMTToolForGoodixDFUToolUnit?) {
        let list = MMTToolForGoodixDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForGoodixUnitDFUDidBegin(unit)
        })
    }
    
    class func sendDelegateUnitDFUDidChangeProgress(_ unit: MMTToolForGoodixDFUToolUnit?) {
        let list = MMTToolForGoodixDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForGoodixUnitDFUDidChangeProgress(unit)
        })
    }
    
    class func sendDelegateUnitDFUDidEnd(_ unit: MMTToolForGoodixDFUToolUnit?, error: Error?) {
        let list = MMTToolForGoodixDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForGoodixUnitDFUDidEnd(unit, error: error)
        })
    }
    
    class func sendDelegateUnitDFUGetUUID(_ unit: MMTToolForGoodixDFUToolUnit?) -> MMTToolForGoodixDFUDelegate.DFUServerTurple? {
        let list = MMTToolForGoodixDFUTool.share.multiDelegateList
        let turpleList: [MMTToolForGoodixDFUDelegate.DFUServerTurple?] = list.map({
            return $0.weakDelegate?.mmtToolForGoodixUnitGetUUID(unit)
        }).filter({
            return $0 != nil
        })
        return turpleList.first ?? nil
    }
    
    class func createError(code: Int, localDescrip: String) -> NSError {
        var userInfo: [String : Any] = .init()
        userInfo[NSLocalizedDescriptionKey] = localDescrip
        let error = NSError(domain: "com.mmt.sdk.goodixDFUTool.error", code: code, userInfo: userInfo)
        return error
    }
    
}
