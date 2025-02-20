//
//  MMTToolForGoodixDFUToolUnit.swift
//  MMTToolForGoodixDFU
//
//  Created by Macmini3 on 20/2/2025.
//

import Foundation
import MMTToolForBluetooth


public class MMTToolForGoodixDFUToolUnit: NSObject {
    
    public enum DFUStatus {
        case prepare
        case progress(_ current: Int, _ total: Int)
        case finish
        case error(_ error: Error)
    }
    
    public var dfuStatus: DFUStatus = .prepare
    
    enum DFUStage {
        case normal
        case sendDFUEnter
        case dfuModeReady
        case dfuStart
        case dfuSuccess
        case dfuFailure
    }
    var dfuStage: DFUStage = .normal
    
    public var startTimeStamp: TimeInterval = 0
    
    fileprivate weak var device: MMTToolForBleDevice?
    
    public var deviceMac: String?
    
    public var deviceMacExtra: String?
    
    public var deviceUUID: String?
    
    weak var delegate: MMTToolForGoodixDFUDelegate?
    
    var startAddress: String?
    
    var dfuFilePath: String?
    
    fileprivate weak var service: MMTService?
    
    fileprivate weak var readCharacter: MMTCharacteristic?
    
    fileprivate weak var writeCharacter: MMTCharacteristic?
    
    fileprivate weak var controlCharacter: MMTCharacteristic?
    
    public var localServiceUUID: String?
    
    public var localReadCharacterUUID: String?
    
    public var localWriteCharacterUUID: String?
    
    public var localControlCharacterUUID: String?
    
    fileprivate var easyDfu2: EasyDfu2?
    
    func startDfu() {
        
        self.dfuStage = .normal
        self.device = nil
        self.service = nil
        self.readCharacter = nil
        self.writeCharacter = nil
        self.controlCharacter = nil
        self.easyDfu2 = nil
        
        MMTToolForBleManager.shared.addDelegate(self)
        
        self.dfuStep01()
    }
    
}

extension MMTToolForGoodixDFUToolUnit {
    
    // 1. 发送命令进入DFU模式
    
    func dfuStep01() {
        guard let device = MMTToolForBleManager.shared.deviceList.first(where: {
            return $0.value.mac?.uppercased() == self.deviceMac
        })?.value else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Device Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            return
        }
        self.dfuStage = .sendDFUEnter
        guard let service = device.peripheral.services?.first(where: {
            return $0.uuid.uuidString.uppercased() == self.localServiceUUID
        }) else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Device Service Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            return
        }
        guard let controlCharacter = service.characteristics?.first(where: {
            return $0.uuid.uuidString.uppercased() == self.localControlCharacterUUID?.uppercased()
        }) else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Device ControlCharacter Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            return
        }
        
        guard let startAddressStr = self.startAddress,
              let address = UInt32(startAddressStr, radix:16)
        else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            return
        }
        guard let dfuFilePath = self.dfuFilePath else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            return
        }
        let url = URL.init(fileURLWithPath: dfuFilePath)
        guard let fileData = try? Data(contentsOf: url) else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            return
        }
        
        let deviceName = device.deviceName ?? device.mac
        
        self.dfuStage = .sendDFUEnter
        
        device.writeData(data: [0x44, 0x4f, 0x4f, 0x47], character: controlCharacter, type: .withoutResponse)
        
        MMTToolForBleManager.shared.startScan(perfix: deviceName)
//        dfuStep02(peripheral: device.peripheral, dfuData: fileData, copyAddr: address)
    }
    
    func dfuStep02(peripheral: MMTPeripheral) {
//    func dfuStep02(peripheral: MMTPeripheral, dfuData: Data, copyAddr: UInt32) {
        
//        guard let service = self.service,
//              let readCharacter = self.readCharacter,
//              let writeCharacter = self.writeCharacter,
//              let controlCharacter = self.controlCharacter else {
//            return
//        }
//        guard let device = MMTToolForBleManager.shared.deviceList.first(where: {
//            return $0.value.mac?.uppercased() == self.deviceMac?.uppercased()
//        })?.value else {
//            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Device Not Exist"))
//            return
//        }
//        guard let peripheral = self.device?.peripheral else {
//            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Device Not Exist"))
//            return
//        }
        
        if self.dfuStage != .sendDFUEnter {
            return
        }
        
        guard let startAddressStr = self.startAddress,
              let address = UInt32(startAddressStr, radix:16)
        else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.remove(self)
            return
        }
        guard let dfuFilePath = self.dfuFilePath else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            return
        }
        let url = URL.init(fileURLWithPath: dfuFilePath)
        guard let fileData = try? Data(contentsOf: url) else {
            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            return
        }
        
        
        self.dfuStage = .dfuModeReady
     
        self.easyDfu2 = EasyDfu2.init()
        self.easyDfu2?.setFastMode(isFastMode: false)
        self.easyDfu2?.setListener(listener: self)
        self.easyDfu2?.startDfuInCopyMode(central: nil, target: peripheral, dfuData: fileData, copyAddr: address)
    }
    
}


extension MMTToolForGoodixDFUToolUnit: MMTToolForBleManagerDelegate {
    
    public func mmtBleManagerDidDiscoverDevice(_ device: MMTToolForBleDevice?) {
        guard let device = device else { return }
        if device.mac?.uppercased() != self.deviceMac?.uppercased() {
            return
        }
        if self.dfuStage != .sendDFUEnter {
            return
        }
//        self.device = device
        dfuStep02(peripheral: device.peripheral)
//        device?.connect()
    }
    
    public func mmtBleManagerDeviceConnectStatusDidChange(_ device: MMTToolForBleDevice?, status: MMTToolForBleDevice.ConnectStatus) {
        
    }
    
    public func mmtBleManagerDeviceRssiDidChange(_ device: MMTToolForBleDevice?, rssi: Int?) {
        
    }
    
    public func mmtBleManagerDeviceNameDidChange(_ device: MMTToolForBleDevice?, origin: String?, new: String?) {
        
    }
    
    public func mmtBleManagerDeviceServerDidDiscover(_ device: MMTToolForBleDevice?, service: MMTService?, character: MMTCharacteristic?) {
//        if self.localServiceUUID?.uppercased() == service?.uuid.uuidString.uppercased() {
//            self.service = service
//        }
//        
//        if let character = service?.characteristics?.first(where: {
//            return self.localReadCharacterUUID?.uppercased() == $0.uuid.uuidString.uppercased()
//        }) {
//            self.readCharacter = character
//        }
//        
//        if let character = service?.characteristics?.first(where: {
//            return self.localWriteCharacterUUID?.uppercased() == $0.uuid.uuidString.uppercased()
//        }) {
//            self.writeCharacter = character
//        }
//        
//        if let character = service?.characteristics?.first(where: {
//            return self.localControlCharacterUUID?.uppercased() == $0.uuid.uuidString.uppercased()
//        }) {
//            self.controlCharacter = character
//        }
//        
//        self.dfuStep02()
    }
    
    public func mmtBleManagerDeviceServerDidUpdate(_ device: MMTToolForBleDevice?, service: MMTService?, character: MMTCharacteristic?, value: Data?) {

    }
    
    public func mmtBleManagerDeviceServerDidWrite(_ device: MMTToolForBleDevice?, service: MMTService?, character: MMTCharacteristic?, value: Data?) {
        
    }
    
}


extension MMTToolForGoodixDFUToolUnit: DfuListener {
    
    public func dfuStart() {
        if self.dfuStage != .dfuModeReady { return }
        self.dfuStage = .dfuStart
    }
    
    public func dfuProgress(msg: String, progress: Int) {
        if self.dfuStage != .dfuStart { return }
        MMTLog.debug.log("[MMTToolForGoodixDFUToolUnit] dfuProgress progress: \(progress) msg: \(msg)")
    }
    
    public func dfuComplete() {
        if self.dfuStage != .dfuStart { return }
        self.dfuStage = .dfuSuccess
        MMTLog.debug.log("[MMTToolForGoodixDFUToolUnit] dfuComplete")
    }
    
    public func dfuStopWithError(errorMsg: String) {
        if self.dfuStage != .dfuStart { return }
        self.dfuStage = .dfuFailure
        MMTLog.debug.log("[MMTToolForGoodixDFUToolUnit] dfuStopWithError \(errorMsg) ")
    }
    
    
}
