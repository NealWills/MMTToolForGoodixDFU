//
//  MMTToolForGoodixDFUToolUnit.swift
//  MMTToolForGoodixDFU
//
//  Created by Macmini3 on 20/2/2025.
//

import Foundation
import CoreBluetooth


public class MMTToolForGoodixDFUToolUnit: NSObject {
    
    var unitId: String = UUID().uuidString
    
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
        case dfuCancel
        
        var titleValue: String {
            switch self {
            case .normal:
                return "normal"
            case .sendDFUEnter:
                return "sendDFUEnter"
            case .dfuModeReady:
                return "dfuModeReady"
            case .dfuStart:
                return "dfuStart"
            case .dfuSuccess:
                return "dfuSuccess"
            case .dfuFailure:
                return "dfuFailure"
            case .dfuCancel:
                return "dfuCancel"
            }
        }
    }
    var dfuStage: DFUStage = .normal
    
    public override var description: String {
        get {
            var title: String = "" + "〖"
            title = title + " " + "id: " + String.init(format: "%p", self) + " " + " |"
            title = title + " " + "deviceMac: " + "\(self.deviceMac ?? "")" + " " + " |"
            title = title + " " + "deviceMac: " + "\(self.deviceMacExtra ?? "")" + " " + " |"
            title = title + " " + "deviceMac: " + "\(self.deviceUUID ?? "")" + " " + " |"
            title = title + " " + "dfuStatus: " + self.dfuStage.titleValue + " " + " |"
            title = title + " 〗 "
            return title
        }
    }
    
    public var startTimeStamp: TimeInterval = 0
    
    public var deviceMac: String?
    
    public var deviceMacExtra: String?
    
    public var deviceUUID: String?
    
//    weak var delegate: MMTToolForGoodixDFUDelegate?
    
    var startAddress: String?
    
    var dfuFilePath: String?
    
    fileprivate weak var service: CBService?
    
    fileprivate weak var readCharacter: CBCharacteristic?
    
    fileprivate weak var writeCharacter: CBCharacteristic?
    
    fileprivate weak var controlCharacter: CBCharacteristic?
    
    public var localServiceUUID: String?
    
    public var localReadCharacterUUID: String?
    
    public var localWriteCharacterUUID: String?
    
    public var localControlCharacterUUID: String?
    
    public var localPeripheral: CBPeripheral?
    
    fileprivate var easyDfu2: EasyDfu2?
    
    fileprivate var manager: CBCentralManager?
    
    fileprivate var peripheral: CBPeripheral?
    
    var timer: Timer?
    var timerValidTimestamp: TimeInterval = 0
    
    var currentProgress: Int = 0
    
    func startDfu() {
        
        self.dfuStage = .normal
        self.service = nil
        self.readCharacter = nil
        self.writeCharacter = nil
        self.controlCharacter = nil
        self.easyDfu2 = nil
        
        self.dfuStep01()
    }
    
    func destroyUnit() {
        self.manager?.delegate = nil
        self.manager = nil
        self.easyDfu2 = EasyDfu2.init()
        self.destroyTimer()
    }
    
    var stepBlock: ((_ unitId: String?, _ stage: String)->())?
    var progressBlock: ((_ unitId: String?, _ progress: Int)->())?
    var resultBlock: ((_ unitId: String?, _ progress: Int?, _ error: NSError?)->())?
    var dfuErrorMsgBlock: ((_ unitId: String?, _ errorMsg: String, _ stage: String)->())?
    
}

extension MMTToolForGoodixDFUToolUnit {
    
    // 1. 发送命令进入DFU模式
    
    func dfuStep01() {
        self.dfuStage = .sendDFUEnter
        guard let service = self.localPeripheral?.services?.first(where: {
            return $0.uuid.uuidString.uppercased() == self.localServiceUUID
        }) else {
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Device Service Not Exist")
            self.resultBlock?(self.unitId, 0, error)
            return
        }
        guard let controlCharacter = service.characteristics?.first(where: {
            return $0.uuid.uuidString.uppercased() == self.localControlCharacterUUID?.uppercased()
        }) else {
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Device ControlCharacter Not Exist")
            self.resultBlock?(self.unitId, 0, error)
            return
        }
        
        guard let startAddressStr = self.startAddress,
              let address = UInt32(startAddressStr, radix:16)
        else {
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist")
            self.resultBlock?(self.unitId, 0, error)
            return
        }
        guard let dfuFilePath = self.dfuFilePath else {
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            self.resultBlock?(self.unitId, 0, error)
            return
        }
        let url = URL.init(fileURLWithPath: dfuFilePath)
        guard let fileData = try? Data(contentsOf: url) else {
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            self.resultBlock?(self.unitId, 0, error)
            return
        }
        
        self.stepBlock?(self.unitId, "Dfu step01 [0x44, 0x4f, 0x4f, 0x47] send")
        
        localPeripheral?.writeValue(Data([0x44, 0x4f, 0x4f, 0x47]), for: controlCharacter, type: .withoutResponse)
        
        self.stepBlock?(self.unitId, "Dfu step01 stop scan")
        self.manager?.stopScan()
        self.manager = nil
        self.peripheral = nil
        
        self.manager = CBCentralManager()
        self.manager?.delegate = self
        
        self.dfuStage = .sendDFUEnter
        
        DispatchQueue(label: "com.mmt.sdk.goodix").asyncAfter(deadline: .now() + 1, execute: {
            self.stepBlock?(self.unitId, "Dfu step01 start scan")
            self.manager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        })
        
//        device.writeData(data: [0x44, 0x4f, 0x4f, 0x47], character: controlCharacter, type: .withoutResponse)
        
//        MMTToolForBleManager.shared.startScan(perfix: deviceName)
//        dfuStep02(peripheral: device.peripheral, dfuData: fileData, copyAddr: address)
    }
    
    func dfuStep02() {
        
        if self.dfuStage != .sendDFUEnter {
            return
        }
        self.stepBlock?(self.unitId, "Dfu step02 enter")
        self.dfuStage = .dfuModeReady
        
        guard let startAddressStr = self.startAddress,
              let address = UInt32(startAddressStr, radix:16)
        else {
//            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.remove(self)
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist")
            resultBlock?(self.unitId, 0, error)
            return
        }
        guard let dfuFilePath = self.dfuFilePath else {
//            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            resultBlock?(self.unitId, 0, error)
            return
        }
        let url = URL.init(fileURLWithPath: dfuFilePath)
        guard let fileData = try? Data(contentsOf: url) else {
//            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            resultBlock?(self.unitId, 0, error)
            
            return
        }
        
        guard let peripheral = self.peripheral else {
//            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Device Not Found"))
//            MMTToolForGoodixDFUTool.share.unitList.append(self)
            
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Device Not Found")
            resultBlock?(self.unitId, 0, error)
            
            return
        }
        
        self.stepBlock?(self.unitId, "Dfu step02 init easy dfu2")
        self.dfuStage = .dfuStart
     
        self.easyDfu2 = EasyDfu2.init()
        self.easyDfu2?.setFastMode(isFastMode: false)
        self.easyDfu2?.setListener(listener: self)
        self.easyDfu2?.setReconnectScanFilter { [weak self] peripheral, advertisementData, rssi in
            if let macData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
                let macList = macData.map({
                    return String.init(format: "%02x", $0).uppercased()
                })
                var mac = macList.joined(separator: ":")
                var macExtra: String?
                if macList.count > 6 {
                    mac = macList[0..<6].joined(separator: ":")
                    macExtra = macList[6..<macList.count].joined(separator: ":")
                }
                if mac.uppercased() == self?.deviceMac?.uppercased() {
                    return true
                }
                return false
            }
            return false
        }
        
        self.stepBlock?(self.unitId, "Dfu step02 dfu2 startDfuInCopyMode")
        
        self.easyDfu2?.startDfuInCopyMode(central: self.manager, target: peripheral, dfuData: fileData, copyAddr: address)
        
        self.currentProgress = 0
        self.stepBlock?(self.unitId, "Dfu step02 dfu2 start timer")
        
        self.timer?.invalidate()
        self.timer = nil
        self.timerValidTimestamp = Date().timeIntervalSince1970
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: true)
    }
    
    @objc func timerAction(_ sender: Any) {
        let currentDate = Date()
        let distance = currentDate.timeIntervalSince1970 - self.timerValidTimestamp
        if distance > 30 {
            let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "dfu stop with error: DFU time out")
            self.easyDfu2?.cancel()
            self.destroyTimer()
            resultBlock?(self.unitId, self.currentProgress, error)
        }
    }
    
    func destroyTimer() {
        
        self.timer?.invalidate()
        self.timer = nil
    }
    
//    func dfuStep02(peripheral: CBPeripheral) {
//        
//        if self.dfuStage != .sendDFUEnter {
//            return
//        }
//        
//        guard let startAddressStr = self.startAddress,
//              let address = UInt32(startAddressStr, radix:16)
//        else {
//            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist"))
////            MMTToolForGoodixDFUTool.share.unitList.remove(self)
//            return
//        }
//        guard let dfuFilePath = self.dfuFilePath else {
//            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
////            MMTToolForGoodixDFUTool.share.unitList.append(self)
//            return
//        }
//        let url = URL.init(fileURLWithPath: dfuFilePath)
//        guard let fileData = try? Data(contentsOf: url) else {
//            MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
////            MMTToolForGoodixDFUTool.share.unitList.append(self)
//            return
//        }
//        
//        
//        self.dfuStage = .dfuModeReady
//     
//        self.easyDfu2 = EasyDfu2.init()
//        self.easyDfu2?.setFastMode(isFastMode: false)
//        self.easyDfu2?.setListener(listener: self)
//        self.easyDfu2?.startDfuInCopyMode(central: nil, target: peripheral, dfuData: fileData, copyAddr: address)
//    }
    
}

extension MMTToolForGoodixDFUToolUnit: DfuListener {
    
    public func dfuCancelled(progress: Int) {
        
//        self.destroyTimer()
//        if let peripheral = self.peripheral {
//            self.manager?.cancelPeripheralConnection(peripheral)
//        }
//        
//        let error = MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "dfu stop with error: DFU Cancel")
//        resultBlock?(self.unitId, error)
        
//        if self.dfuStage != .dfuStart { return }
//        self.dfuStage = .dfuFailure
//        MMTGoodixLog.debug.log("[MMTToolForGoodixDFUToolUnit] dfuStopWithError DFU Cancel ")
//        MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: "DFU Cancel"))
//        if let peripheral = self.peripheral {
//            self.manager?.cancelPeripheralConnection(peripheral)
//        }
    }
    
    
    public func dfuStart() {
        
        self.timerValidTimestamp = Date().timeIntervalSince1970
        if self.currentProgress < 1 {
            self.currentProgress = 1
        }
        self.progressBlock?(self.unitId, self.currentProgress)
//
//        if self.dfuStage != .dfuModeReady { return }
//        self.dfuStage = .dfuStart
//        MMTGoodixLog.debug.log("[MMTToolForGoodixDFUToolUnit] dfuStart")
//        MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidBegin(self)
//        MMTToolForGoodixDFUTool.share.multiDelegateList.forEach({
//            $0.weakDelegate?.mmtToolForGoodixUnitDFUDidBegin(self)
//        })
    }
    
    public func dfuProgress(msg: String, progress: Int) {
        self.timerValidTimestamp = Date().timeIntervalSince1970
        if self.currentProgress < progress {
            self.currentProgress = progress
        }
        self.progressBlock?(self.unitId, self.currentProgress)
//        if self.dfuStage != .dfuStart { return }
//        MMTGoodixLog.debug.log("[MMTToolForGoodixDFUToolUnit] dfuProgress progress: \(progress) msg: \(msg)")
//        MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidChangeProgress(self, progress: progress)
//        MMTToolForGoodixDFUTool.share.multiDelegateList.forEach({
//            $0.weakDelegate?.mmtToolForGoodixUnitDFUDidChangeProgress(self, progress: progress)
//        })
    }
    
    public func dfuComplete() {
        
        self.timerValidTimestamp = Date().timeIntervalSince1970
        
        self.currentProgress = 100
        
//        if self.dfuStage != .dfuStart { return }
//        self.dfuStage = .dfuSuccess
//        MMTGoodixLog.debug.log("[MMTToolForGoodixDFUToolUnit] dfuComplete")
//        MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: nil)
//        MMTToolForGoodixDFUTool.share.multiDelegateList.forEach({
//            $0.weakDelegate?.mmtToolForGoodixUnitDFUDidEnd(self, error: nil)
//        })
        if let peripheral = self.peripheral {
            self.manager?.cancelPeripheralConnection(peripheral)
        }
        self.destroyTimer()
        
        self.resultBlock?(self.unitId, self.currentProgress, nil)
    }
    
    public func dfuStopWithError(errorMsg: String) {
        
        if self.currentProgress < 1 {
            self.dfuErrorMsgBlock?(self.unitId, errorMsg, "DFU Wait Start")
        } else {
            self.dfuErrorMsgBlock?(self.unitId, errorMsg, "DFU Did Start")
        }
//        if self.dfuStage != .dfuStart { return }
//        self.dfuStage = .dfuFailure
//        MMTGoodixLog.debug.log("[MMTToolForGoodixDFUToolUnit] dfuStopWithError \(errorMsg) ")
//        MMTToolForGoodixDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForGoodixDFUTool.createError(code: -1, localDescrip: errorMsg))
////        MMTToolForGoodixDFUTool.share.multiDelegateList.forEach({
////            $0.weakDelegate?.mmtToolForGoodixUnitDFUDidEnd(self, error: nil)
////        })
//        if let peripheral = self.peripheral {
//            self.manager?.cancelPeripheralConnection(peripheral)
//        }
    }
    
}


extension MMTToolForGoodixDFUToolUnit: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
//
        guard let originManager = self.manager else {
            return
        }
        
        let idOrigin = String.init(format: "%p", originManager)
        let idManager = String.init(format: "%p", central)
        if idOrigin != idManager { return }
        
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil)
        default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let macData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let macList = macData.map({
                return String.init(format: "%02x", $0).uppercased()
            })
            var mac = macList.joined(separator: ":")
            var macExtra: String?
            if macList.count > 6 {
                mac = macList[0..<6].joined(separator: ":")
                macExtra = macList[6..<macList.count].joined(separator: ":")
            }
            if mac.uppercased() == self.deviceMac?.uppercased() {
                self.peripheral = peripheral
                
                self.stepBlock?(self.unitId, "Dfu step01 device scan success")
                self.stepBlock?(self.unitId, "Dfu step01 device scan success than end scan")
                
                central.stopScan()
                self.dfuStep02()
            }
        }
    }
    
}
