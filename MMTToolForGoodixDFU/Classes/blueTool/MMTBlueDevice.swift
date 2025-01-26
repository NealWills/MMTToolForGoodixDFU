//
//  MMTBlueDevice.swift
//  MMTToolForGoodixDFU
//
//  Created by Neal on 1/26/25.
//

import Foundation
import CoreBluetooth

class MMTBlueDevice: NSObject {

    var peripheral: CBPeripheral
    var deviceName: String?
    var uuid: String?
    var mac: String?
    var macExtra: String?
    var rssi: NSNumber?
    var advertisementData: [String: Any]?

    var centralManager: CBCentralManager?

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.uuid = peripheral.identifier.uuidString.lowercased()
        
    }

    func update(rssi: NSNumber) {
        
    }

}
