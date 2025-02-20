import Foundation 
import CoreBluetooth

/// A class that provides tools for interacting with Bluetooth devices.
/// 
/// This class is part of the MMTToolForBluetooth module and is designed to facilitate
/// communication and operations with Bluetooth devices.
/// 
/// - Note: This class inherits from `NSObject`.
public class MMTToolForBleDevice: NSObject {
    
    public enum ConnectStatus {
        case disconnected
        case connecting
        case connected
        case scan
        
        public var titleValue: String {
            switch self {
            case .disconnected:
                return "disconnected"
            case .connecting:
                return "connecting"
            case .connected:
                return "connected"
            case .scan:
                return "scan"
            }
        }
        
        public var weightValue: Int {
            switch self {
            case .disconnected:
                return 0
            case .connecting:
                return 2
            case .connected:
                return 3
            case .scan:
                return 1
            }
        }
    }
   
    /// The connection status of the Bluetooth device.
    /// 
    /// This property holds the current connection status of the Bluetooth device.
    /// It is of type `ConnectStatus` and is initialized to `.disConnect`.
    ///
    /// - Note: The `ConnectStatus` enum should define the possible states of the connection.
    public var connectStatus: ConnectStatus = .disconnected
    
    /// The `CBPeripheral` instance representing the Bluetooth peripheral device.
    public var peripheral: CBPeripheral
    
    /// A string representing the universally unique identifier (UUID) of the Bluetooth device.
    public var uuid: String
    
    /// The name of the Bluetooth device.
    /// This property is optional and can be nil if the device name is not available.
    public var deviceName: String?
    
    /// The received signal strength indicator (RSSI) value for the Bluetooth device.
    /// This value represents the signal strength in decibels (dBm).
    /// It is an optional integer, which means it can be `nil` if the RSSI value is not available.
    public var rssi: Int?
    
    /// The MAC address of the Bluetooth device.
    /// This property is optional and may be `nil` if the MAC address is not available.
    public var mac: String?
    
    /// A variable to store additional information related to the MAC address of the Bluetooth device.
    public var macExtra: String?
    
    /// A dictionary containing the advertisement data of the Bluetooth device.
    /// The keys are `String` representing the type of advertisement data, and the values are `AnyObject` representing the data itself.
    /// This property is optional and may be `nil` if no advertisement data is available.
    public var advertisementData: [String: Any]?
    
    /// The service UUID of the Bluetooth device.
    public var serviceUUID: String?
    
    /// A variable to store the timestamp.
    /// 
    /// This variable holds a `TimeInterval` value representing the timestamp.
    /// The default value is set to 0.
    public var timestamp: TimeInterval = 0
    
    /// A weak reference to the `CBCentralManager` instance.
    /// This property is used to manage Bluetooth-related tasks.
    /// The weak reference helps to avoid retain cycles and memory leaks.
    /// 
    weak var manager: CBCentralManager?
    
    /// A string representing the description of the Bluetooth device.
    public override var description: String {
        get {
            var title = ""
            title = title + "〖 "
            title = title + "mac: " + (self.mac ?? "")
            title = title + " ┃ " + "macExtra: " + (self.macExtra ?? "nil")
            title = title + " ┃ " + "deviceName: " + (self.deviceName ?? "nil")
            title = title + " ┃ " + "serviceUUID: " + (self.serviceUUID ?? "nil")
            title = title + " ┃ " + "rssi: " + "\(self.rssi ?? -300)"
            title = title + " ┃ " + "timestamp: " + "\(self.timestamp)"
            title = title + " 〗"
            return title
        }
    }
    
    /// Initializes a new instance of `MMTToolForBleDevice` with the specified peripheral and manager.
    ///
    /// - Parameters:
    ///   - peripheral: The `CBPeripheral` instance representing the Bluetooth peripheral device.
    ///   - manager: An optional `CBCentralManager` instance managing the Bluetooth connection.
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.uuid = peripheral.identifier.uuidString.uppercased()
        super.init()
        peripheral.delegate = self
        self.timestamp = Date().timeIntervalSince1970
    }

    /**
     Updates the Bluetooth device with the provided advertisement data.
     
     - Parameter advertisementData: A dictionary containing the advertisement data. The keys are `String` and the values are `AnyObject`.
     */
    func update(advertisementData: [String: Any]?) {
        self.advertisementData = advertisementData
        self.timestamp = Date().timeIntervalSince1970
        let localName = peripheral.name ?? ""
        self.deviceName = advertisementData?["kCBAdvDataLocalName"] as? String ?? localName
        if let macData = advertisementData?["kCBAdvDataManufacturerData"] as? Data {
            let macList = macData.map({
                return String.init(format: "%02x", $0).uppercased()
            })
            var mac = macList.joined(separator: ":")
            var macExtra: String?
            if macList.count > 6 {
                mac = macList[0..<6].joined(separator: ":")
                macExtra = macList[6..<macList.count].joined(separator: ":")
            }
            self.mac = mac.uppercased()
            self.macExtra = macExtra?.uppercased()
        }
        if let data = advertisementData?["kCBAdvDataServiceUUIDs"] as? [Any],
           let serviceUUID = data.first as? CBUUID {
            self.serviceUUID = serviceUUID.uuidString
        }
        
        // self.deviceName = peripheral.name
        // self.mac = peripheral.identifier.UUIDString
        // self.macExtra = peripheral.identifier.UUIDString
    }

    /// Updates the RSSI (Received Signal Strength Indicator) value for the Bluetooth device.
    ///
    /// - Parameter rssi: An optional integer representing the RSSI value. If `nil`, the RSSI value is not updated.
    func update(rssi: Int?) {
        self.rssi = rssi
        self.timestamp = Date().timeIntervalSince1970
    }
    
}


/// Extension for the `MMTToolForBleDevice` class.
/// This extension provides additional functionality specific to Bluetooth device operations.
public extension MMTToolForBleDevice {
    
    /// Establishes a connection to the Bluetooth device.
    /// 
    /// This method initiates the process of connecting to a Bluetooth device.
    /// It handles the necessary steps to establish a connection and ensures
    /// that the device is ready for communication.
    func connect() {
        self.manager?.cancelPeripheralConnection(self.peripheral)
        DispatchQueue.init(label: "com.mmtsdk.MMTToolForBleManager.deviceQueue")
            .asyncAfter(deadline: .now() + 0.2, execute: {
                self.manager?.connect(self.peripheral)
                self.connectStatus = .connecting
                MMTToolForBleManager.shared.multiDelegateList.forEach({
                    $0?.mmtBleManagerDeviceConnectStatusDidChange(self, status: .connecting)
                })
            })
    }
    
    /// Disconnects the Bluetooth device.
    ///
    /// This method terminates the connection with the currently connected Bluetooth device.
    /// It ensures that any ongoing communication is properly closed and resources are released.
    ///
    /// - Note: Make sure to handle any necessary cleanup or state updates after calling this method.
    func disconnect() {
        self.manager?.cancelPeripheralConnection(self.peripheral)
        self.connectStatus = .disconnected
    }
}


extension MMTToolForBleDevice: CBPeripheralDelegate {
    
    
    /**
     *  @method peripheralDidUpdateName:
     *
     *  @param peripheral    The peripheral providing this update.
     *
     *  @discussion            This method is invoked when the @link name @/link of <i>peripheral</i> changes.
     */
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] peripheralDidUpdateName \(peripheral.name)")
        let origin = self.deviceName
        let new = peripheral.name
        self.deviceName = new
        MMTToolForBleManager.shared.multiDelegateList.forEach({
            $0?.mmtBleManagerDeviceNameDidChange(self, origin: origin, new: new)
        })
    }

    /**
     *  @method peripheral:didModifyServices:
     *
     *  @param peripheral            The peripheral providing this update.
     *  @param invalidatedServices    The services that have been invalidated
     *
     *  @discussion            This method is invoked when the @link services @/link of <i>peripheral</i> have been changed.
     *                        At this point, the designated <code>CBService</code> objects have been invalidated.
     *                        Services can be re-discovered via @link discoverServices: @/link.
     */
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] didModifyServices")
    }

    /**
     *  @method peripheralDidUpdateRSSI:error:
     *
     *  @param peripheral    The peripheral providing this update.
     *    @param error        If an error occurred, the cause of the failure.
     *
     *  @discussion            This method returns the result of a @link readRSSI: @/link call.
     *
     *  @deprecated            Use {@link peripheral:didReadRSSI:error:} instead.
     */
    public func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] peripheralDidUpdateRSSI")
        peripheral.readRSSI()
    }

    /**
     *  @method peripheral:didReadRSSI:error:
     *
     *  @param peripheral    The peripheral providing this update.
     *  @param RSSI            The current RSSI of the link.
     *  @param error        If an error occurred, the cause of the failure.
     *
     *  @discussion            This method returns the result of a @link readRSSI: @/link call.
     */
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] didReadRSSI")
        self.update(rssi: RSSI.intValue)
        MMTToolForBleManager.shared.multiDelegateList.forEach({
            $0?.mmtBleManagerDeviceRssiDidChange(self, rssi: RSSI.intValue)
        })
    }

    /**
     *  @method peripheral:didDiscoverServices:
     *
     *  @param peripheral    The peripheral providing this information.
     *    @param error        If an error occurred, the cause of the failure.
     *
     *  @discussion            This method returns the result of a @link discoverServices: @/link call. If the service(s) were read successfully, they can be retrieved via
     *                        <i>peripheral</i>'s @link services @/link property.
     *
     */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] didDiscoverServices")
        peripheral.services?.forEach({
            $0.peripheral?.discoverCharacteristics(nil, for: $0)
        })
        MMTToolForBleManager.shared.multiDelegateList.forEach({
            $0?.mmtBleManagerDeviceServerDidDiscover(self, service: nil, character: nil)
        })
    }

    /**
     *  @method peripheral:didDiscoverIncludedServicesForService:error:
     *
     *  @param peripheral    The peripheral providing this information.
     *  @param service        The <code>CBService</code> object containing the included services.
     *    @param error        If an error occurred, the cause of the failure.
     *
     *  @discussion            This method returns the result of a @link discoverIncludedServices:forService: @/link call. If the included service(s) were read successfully,
     *                        they can be retrieved via <i>service</i>'s <code>includedServices</code> property.
     */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] didDiscoverCharacteristicsFor \(service)")
        service.characteristics?.forEach({
            $0.service?.peripheral?.discoverDescriptors(for: $0)
        })
        MMTToolForBleManager.shared.multiDelegateList.forEach({
            $0?.mmtBleManagerDeviceServerDidDiscover(self, service: service, character: nil)
        })
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] didDiscoverDescriptorsFor \(characteristic)")
        MMTToolForBleManager.shared.multiDelegateList.forEach({
            $0?.mmtBleManagerDeviceServerDidDiscover(self, service: characteristic.service, character: characteristic)
        })
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] didUpdateValueFor \(characteristic)")
        MMTToolForBleManager.shared.multiDelegateList.forEach({
            $0?.mmtBleManagerDeviceServerDidUpdate(self, service: characteristic.service, character: characteristic, value: characteristic.value)
        })
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] didWriteValueFor \(characteristic)")
        MMTToolForBleManager.shared.multiDelegateList.forEach({
            $0?.mmtBleManagerDeviceServerDidWrite(self, service: characteristic.service, character: characteristic, value: characteristic.value)
        })
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: (any Error)?) {
        MMTLog.debug.log("[MMTToolForBleDevice \(self.mac)] didWriteValueFor \(descriptor)")
    }
    
}
