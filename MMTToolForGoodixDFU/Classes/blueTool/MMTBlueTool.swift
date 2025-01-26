
import Foundation
import CoreBluetooth

class MMTBlueTool: NSObject {

    static let shared = MMTBlueTool()

    var centralManager: CBCentralManager!

    class func configManager() {
        MMTBlueTool.shared.centralManager = CBCentralManager(delegate: MMTBlueTool.shared, queue: nil) 
    }
   
}

extension MMTBlueTool: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("centralManagerDidUpdateState")
    }
    
}