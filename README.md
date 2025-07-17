![Header Image](Resources/MMTToolForGoodixDFU.png)

# MMTToolForGoodixDFU

[![CI Status](https://img.shields.io/travis/NealWills/MMTToolForGoodixDFU.svg?style=flat)](https://travis-ci.org/NealWills/MMTToolForGoodixDFU)
[![Version](https://img.shields.io/cocoapods/v/MMTToolForGoodixDFU.svg?style=flat)](https://cocoapods.org/pods/MMTToolForGoodixDFU)
[![License](https://img.shields.io/cocoapods/l/MMTToolForGoodixDFU.svg?style=flat)](https://cocoapods.org/pods/MMTToolForGoodixDFU)
[![Platform](https://img.shields.io/cocoapods/p/MMTToolForGoodixDFU.svg?style=flat)](https://cocoapods.org/pods/MMTToolForGoodixDFU)

## Example

## Requirements

## Installation

MMTToolForGoodixDFU is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MMTToolForGoodixDFU'
```


## How To Use

#### use

```Swift
class Class {
    func startDFU() {
        let startAddressStr = "01080000"

	MMTToolForGoodixDFUTool.addDelegate(self)
  
	MMTToolForGoodixDFUTool.startDfu(deviceUUID: device.uuid, deviceMac: device.mac, deviceMacExtra: device.macExtra, peripheral: device.peripheral, startAddress: startAddressStr, filePath: filePath)
    }

}

extension Class: MMTToolForGoodixDFUDelegate {
    func mmtToolForGoodixUnitDidShowErrorMessage(_ unit: MMTToolForGoodixDFU.MMTToolForGoodixDFUToolUnit?, stage: String?, error: (any Error)?) {
  
    }

    func mmtToolForGoodixUnitDidEnter(_ unit: MMTToolForGoodixDFU.MMTToolForGoodixDFUToolUnit?) {

    }

    func mmtToolForGoodixUnitDidFailToEnter(_ unit: MMTToolForGoodixDFU.MMTToolForGoodixDFUToolUnit?, error: (any Error)?) {
  
    }
  
    func mmtToolForGoodixUnitDFUDidBegin(_ unit: MMTToolForGoodixDFU.MMTToolForGoodixDFUToolUnit?) {
  
    }
  
    func mmtToolForGoodixUnitDFUDidChangeProgress(_ unit: MMTToolForGoodixDFU.MMTToolForGoodixDFUToolUnit?, progress: Int) {
  
    }
  
    func mmtToolForGoodixUnitDFUDidEnd(_ unit: MMTToolForGoodixDFU.MMTToolForGoodixDFUToolUnit?, error: (any Error)?) {
  
    }
  
    func mmtToolForGoodixUnitGetUUID(_ unit: MMTToolForGoodixDFU.MMTToolForGoodixDFUToolUnit?) -> DFUServerTurple? {
        let device = ....
        let service = device.serviceList[.goodixService]
        let readCharacter = device.characterList[.goodixCharactericsRxUUid]
        let writeCharacter = device.characterList[.goodixCharactericsTxUUid]
        let controlCharacter = device.characterList[.goodixCharactericsControlPointUUid]
        return ( service: service, readCharacter: readCharacter, writeCharacter: writeCharacter, controlCharacter: controlCharacter )
    }

}
```

#### Dealloc

```
MMTToolForGoodixDFUTool.removeDelegate(self)
```

## Author

NealWills, nealwills93@gmail.com

## License

MMTToolForGoodixDFU is available under the MIT license. See the LICENSE file for more info.
