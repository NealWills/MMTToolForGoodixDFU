import CoreBluetooth
import Foundation

public typealias MMTService = CBService
public typealias MMTCharacteristic = CBCharacteristic

public protocol MMTToolForBleManagerDelegate: NSObject {
    
    func mmtBleManagerDidDiscoverDevice(_ device: MMTToolForBleDevice?)
    
    func mmtBleManagerDeviceConnectStatusDidChange(_ device: MMTToolForBleDevice?, status: MMTToolForBleDevice.ConnectStatus)
    
    func mmtBleManagerDeviceRssiDidChange(_ device: MMTToolForBleDevice?, rssi: Int?)
    
    func mmtBleManagerDeviceNameDidChange(_ device: MMTToolForBleDevice?, origin: String?, new: String?)
    
    func mmtBleManagerDeviceServerDidDiscover(_ device: MMTToolForBleDevice?, service: MMTService?, character: MMTCharacteristic?)
    
    func mmtBleManagerDeviceServerDidUpdate(_ device: MMTToolForBleDevice?, service: MMTService?, character: MMTCharacteristic?, value: Data?)
    
    func mmtBleManagerDeviceServerDidWrite(_ device: MMTToolForBleDevice?, service: MMTService?, character: MMTCharacteristic?, value: Data?)
    
}

public class MMTToolForBleManagerWeakDelegate: NSObject {
    weak var weakDelegate: MMTToolForBleManagerDelegate?
    init(weakDelegate: MMTToolForBleManagerDelegate? = nil) {
        self.weakDelegate = weakDelegate
    }
}

/// A manager class for handling Bluetooth operations in the MMTToolForBluetooth module.
/// 
/// This class provides various functionalities to manage Bluetooth connections and data transfer.
/// 
/// - Note: This class inherits from `NSObject`.
public class MMTToolForBleManager: NSObject {

    /// A singleton instance of `MMTToolForBleManager`.
    /// 
    /// This shared instance provides a global point of access to the `MMTToolForBleManager` class,
    /// ensuring that only one instance of the manager is created and used throughout the application.
    public static let shared = MMTToolForBleManager()

    /// The central manager instance responsible for managing Bluetooth low energy (BLE) connections and interactions.
    /// This property is optional and may be nil if the central manager has not been initialized.
    /// - Note: Ensure that the central manager is properly initialized before attempting to use it.
    var centralManager: CBCentralManager?
    
    var multiDelegateList: [MMTToolForBleManagerWeakDelegate] = .init()
    
    var bleStatus: CBManagerState = .unknown
    
    /// A dispatch queue used for managing Bluetooth-related tasks.
    /// This queue is optional and can be nil if not initialized.
    /// - Note: Ensure to initialize this queue before using it to avoid unexpected behavior.
    var queue: dispatch_queue_t?
    
    /// A variable to store the prefix used for scanning Bluetooth devices.
    /// This can be used to filter devices based on their name prefix during the scanning process.
    var scanPrefix: String?
    
    /// A dictionary that holds the list of scanned Bluetooth devices.
    /// The keys are the device identifiers as strings, and the values are `MMTToolForBleDevice` objects.
    public var deviceList: [String: MMTToolForBleDevice] = [:]

    /**
     Configures the Bluetooth manager.

     This method sets up the necessary configurations for the Bluetooth manager to function properly.
     */
    public class func configManager() {
        MMTToolForBleManager.shared.queue = DispatchQueue(label: "com.mmtsdk.MMTToolForBleManager.queue")
        MMTToolForBleManager.shared.centralManager = CBCentralManager(delegate: MMTToolForBleManager.shared, queue: MMTToolForBleManager.shared.queue)
    }
}

public extension MMTToolForBleManager {
    
    func addDelegate(_ delegate: MMTToolForBleManagerDelegate?) {
        let delegateUnit = MMTToolForBleManagerWeakDelegate.init(weakDelegate: delegate)
        self.multiDelegateList.append(delegateUnit)
    }
    
    func removeDelegate(_ delegate: MMTToolForBleManagerDelegate?) {
        let list = self.multiDelegateList.filter({
            guard let item0 = $0.weakDelegate else {
                return false
            }
            guard let item1 = delegate else {
                return true
            }
            
            let id0 = String.init(format: "%p", item0)
            let id1 = String.init(format: "%p", item1)
            return !(id0 == id1)
            
        })
        self.multiDelegateList = list
    }
}

/// Extension for `CBManagerState` to add additional functionality or properties.
/// `CBManagerState` is an enumeration that describes the possible states of a Core Bluetooth manager.
extension CBManagerState {
    var debugStrValue: String {
        switch self {
        case .unknown:
            return "unknown"
        case .resetting:
            return "resetting"
        case .unsupported:
            return "unsupported"
        case .unauthorized:
            return "unauthorized"
        case .poweredOff:
            return "poweredOff"
        case .poweredOn:
            return "poweredOn"
        }
    }
}

/// Extension for `MMTToolForBleManager` class to add additional functionalities or to organize code better.
/// This extension might include methods, properties, or other functionalities that are related to Bluetooth management.
/// This extension is part of the MMTToolForBluetooth module.
extension MMTToolForBleManager {
    
    /**
     Starts scanning for Bluetooth devices.

     - Parameter perfix: An optional string to filter devices by prefix. If `nil`, all devices will be scanned.
     */
    public func startScan(perfix: String? = nil) {
        MMTLog.debug.log("[MMTToolForBleManager] startScan perfix: \(perfix)")
        MMTToolForBleManager.shared.centralManager?.stopScan()
        MMTToolForBleManager.shared.scanPrefix = nil
        MMTToolForBleManager.shared.scanPrefix = perfix
        MMTToolForBleManager.shared.deviceList.filter {
            return $0.value.connectStatus != .scan
        }
        DispatchQueue.init(label: "com.mmtsdk.MMTToolForBleManager").asyncAfter(deadline: .now() + 1, execute: {
            MMTToolForBleManager.shared.centralManager?.scanForPeripherals(withServices: nil)
        })
        
    }
    
    /**
     Stops the ongoing Bluetooth scan.
     
     This method should be called to halt any active scanning for Bluetooth devices.
     */
    public func stopScan() {
        MMTToolForBleManager.shared.centralManager?.stopScan()
    }
    
}

/// Extension for `MMTToolForBleManager` to add additional functionalities or to organize code better.
/// This extension is part of the MMTToolForBluetooth module.
public extension MMTToolForBleManager {
    
    /**
     Connects to the specified Bluetooth device.

     - Parameter device: The `MMTToolForBleDevice` instance representing the Bluetooth device to connect to.
     */
    public class func connect(device: MMTToolForBleDevice) {
        device.manager = MMTToolForBleManager.shared.centralManager
        device.connect()
    }
    
    /**
     Disconnects the specified Bluetooth device.

     - Parameter device: The `MMTToolForBleDevice` instance representing the Bluetooth device to disconnect.
     */
    public class func disconnect(device: MMTToolForBleDevice) {
        device.disconnect()
    }
}

/**
 This extension conforms `MMTToolForBleManager` to the `CBCentralManagerDelegate` protocol.
 
 `CBCentralManagerDelegate` is a protocol that defines the methods that a delegate of a `CBCentralManager` object must adopt. 
 The methods of the protocol allow the delegate to monitor the discovery, connectivity, and retrieval of peripheral devices.
 
 By conforming to this protocol, `MMTToolForBleManager` can handle Bluetooth-related events such as discovering, connecting, and disconnecting from Bluetooth peripherals.
 */
extension MMTToolForBleManager: CBCentralManagerDelegate {
    
    /**
     Called when the central manager's state is updated.
     
     - Parameter central: The central manager whose state has been updated.
     */
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        MMTLog.debug.log("[MMTToolForBleManager] \(central.state.debugStrValue)")
        self.bleStatus = central.state
    }
    
    /**
     * Called when a connection is successfully made to a peripheral.
     *
     * - Parameters:
     *   - central: The central manager providing this information.
     *   - peripheral: The peripheral that has connected.
     */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        MMTLog.debug.log("[MMTToolForBleManager] didConnectPeripheral")
        let uuid = peripheral.identifier.uuidString.uppercased()
        if let device = MMTToolForBleManager.shared.deviceList[uuid] {
            device.connectStatus = .connected
            device.peripheral.discoverServices(nil)
            self.multiDelegateList.forEach({
                $0.weakDelegate?.mmtBleManagerDeviceConnectStatusDidChange(device, status: device.connectStatus)
            })
        } else {
            peripheral.delegate = nil
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    /**
     Called when the central manager fails to connect to a peripheral.

     - Parameters:
       - central: The central manager providing this information.
       - peripheral: The peripheral that failed to connect.
       - error: An optional error object containing details about why the connection failed.
     */
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleManager] didFailToConnectPeripheral")
        let uuid = peripheral.identifier.uuidString.uppercased()
        if let device = MMTToolForBleManager.shared.deviceList[uuid] {
            device.connectStatus = .disconnected
            self.multiDelegateList.forEach({
                $0.weakDelegate?.mmtBleManagerDeviceConnectStatusDidChange(device, status: device.connectStatus)
            })
        } else {
            peripheral.delegate = nil
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    /**
     Called when a peripheral device disconnects from the central manager.
     
     - Parameters:
       - central: The central manager providing this information.
       - peripheral: The peripheral that was disconnected.
       - error: An optional error object containing details of the disconnection, if any.
     */
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleManager] didDisconnectPeripheral")
        let uuid = peripheral.identifier.uuidString.uppercased()
        if let device = MMTToolForBleManager.shared.deviceList[uuid] {
            device.connectStatus = .disconnected
            self.multiDelegateList.forEach({
                $0.weakDelegate?.mmtBleManagerDeviceConnectStatusDidChange(device, status: device.connectStatus)
            })
        } else {
            peripheral.delegate = nil
            central.cancelPeripheralConnection(peripheral)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleManager] didDisconnectPeripheral")
        let uuid = peripheral.identifier.uuidString.uppercased()
        if let device = MMTToolForBleManager.shared.deviceList[uuid] {
            device.connectStatus = .disconnected
            self.multiDelegateList.forEach({
                $0.weakDelegate?.mmtBleManagerDeviceConnectStatusDidChange(device, status: device.connectStatus)
            })
        } else {
            peripheral.delegate = nil
            central.cancelPeripheralConnection(peripheral)
        }
    }
    /**
     Called when a peripheral is discovered during a scan.

     - Parameters:
       - central: The central manager that discovered the peripheral.
       - peripheral: The discovered peripheral.
       - advertisementData: A dictionary containing any advertisement data.
       - RSSI: The received signal strength indicator (RSSI) of the peripheral.
     */
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = MMTToolForBleDevice(peripheral: peripheral)
        device.update(rssi: RSSI.intValue)
        device.update(advertisementData: advertisementData)
        if let perfix = MMTToolForBleManager.shared.scanPrefix, perfix.count > 0 {
            let mac = device.mac ?? ""
            let deviceName = device.deviceName ?? ""
            let uuid = device.uuid ?? ""
            if !mac.uppercased().hasPrefix(perfix.uppercased()) && !deviceName.uppercased().hasPrefix(perfix.uppercased()) && !uuid.uppercased().hasPrefix(perfix.uppercased()) {
                return
            }
        }
        if let oldDevice = MMTToolForBleManager.shared.deviceList[device.uuid.uppercased()] {
            oldDevice.update(rssi: RSSI.intValue)
            oldDevice.update(advertisementData: advertisementData)
            oldDevice.timestamp = Date().timeIntervalSince1970
            oldDevice.connectStatus = .scan
            peripheral.delegate = oldDevice
            MMTLog.debug.log("[MMTToolForBleManager] didDiscoverPeripheral \(oldDevice)")
            
            let delegateList = self.multiDelegateList.filter({
                return $0 != nil
            })
            self.multiDelegateList = delegateList
            delegateList.forEach({
                $0.weakDelegate?.mmtBleManagerDidDiscoverDevice(oldDevice)
            })
        } else {
            device.update(rssi: RSSI.intValue)
            device.update(advertisementData: advertisementData)
            device.timestamp = Date().timeIntervalSince1970
            device.connectStatus = .scan
            MMTToolForBleManager.shared.deviceList[device.uuid.uppercased()] = device
            
            MMTLog.debug.log("[MMTToolForBleManager] didDiscoverPeripheral \(device)")
            
            let delegateList = self.multiDelegateList.filter({
                return $0 != nil
            })
            self.multiDelegateList = delegateList
            delegateList.forEach({
                $0.weakDelegate?.mmtBleManagerDidDiscoverDevice(device)
            })
            
        }
    }
    
}
