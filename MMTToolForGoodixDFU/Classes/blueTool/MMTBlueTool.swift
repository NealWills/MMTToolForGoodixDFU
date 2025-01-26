
import Foundation
import CoreBluetooth

/// A tool class for handling Bluetooth operations related to Goodix DFU.
///
/// This class provides various methods and properties to manage and interact with Bluetooth devices
/// specifically for the Goodix DFU (Device Firmware Update) process.
///
/// - Note: This class inherits from `NSObject`.
///
class MMTBlueTool: NSObject {

    static let shared = MMTBlueTool()

    var centralManager: CBCentralManager!

    var searchPrefix: String?
    
    var scanList: [MMTBlueDevice] = .init()
    
    var queue: dispatch_queue_t?

    class func configManager() {
        MMTBlueTool.shared.queue = DispatchQueue(label: "com.mmtToolForGoodixDFU")
        MMTBlueTool.shared.centralManager = CBCentralManager(delegate: MMTBlueTool.shared, queue: nil)
    }
   
    class func scanDevice(prefix: String? = nil) {
        MMTBlueTool.shared.centralManager.stopScan()
    }
    
}

/**
 This extension conforms `MMTBlueTool` to the `CBCentralManagerDelegate` protocol.
 
 `CBCentralManagerDelegate` is a protocol that defines the methods that a delegate of a `CBCentralManager` object must adopt.
 
 By adopting this protocol, `MMTBlueTool` can handle Bluetooth-related events such as discovering, connecting, and disconnecting from peripherals.
 */
extension MMTBlueTool: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState")
    }


    
}
