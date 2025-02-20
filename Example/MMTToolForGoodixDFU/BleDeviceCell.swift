//
//  BleDeviceCell.swift
//  MMTToolForBluetooth_Example
//
//  Created by Macmini3 on 18/2/2025.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import MMTToolForBluetooth
import SnapKit

class BleDeviceCell: UITableViewCell {
    
    var tagBase: Int = 100001
    
    var device: MMTToolForBleDevice? {
        didSet {
            configCell(device)
        }
    }
    
    var connectAction: (()->())?
    var dfuAction: (()->())?

    var titleLabel: UILabel?
    var subTitlelabel: UILabel?
    var connectButton: UIButton?
    var dfuButton: UIButton?
    var serviceView: UIView?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        configSubviews()
    }

    func configSubviews() {
        
        let titleLabel = UILabel(frame: CGRect.zero)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints({
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(20)
        })
        titleLabel.textColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 1)
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel = titleLabel

        let subTitlelabel = UILabel(frame: CGRect.zero)
        contentView.addSubview(subTitlelabel)
        subTitlelabel.snp.makeConstraints({
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
//            $0.bottom.equalToSuperview().offset(-16)
        })
        subTitlelabel.textColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.8)
        subTitlelabel.font = UIFont.systemFont(ofSize: 14)
        subTitlelabel.numberOfLines = 0
        self.subTitlelabel = subTitlelabel
        
        let serviceView = UIView.init(frame: .zero)
        contentView.addSubview(serviceView)
        serviceView.snp.makeConstraints({
            $0.top.equalTo(subTitlelabel.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0)
        })
        self.serviceView = serviceView
        
        let connectButton = UIButton(type: .custom)
        contentView.addSubview(connectButton)
        connectButton.snp.makeConstraints({
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-24)
            $0.width.equalTo(120)
            $0.height.equalTo(120)
        })
        connectButton.setTitle("Connect", for: .normal)
        connectButton.setTitleColor(UIColor.init(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        connectButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        connectButton.layer.cornerRadius = 60
        connectButton.layer.borderWidth = 3
        connectButton.layer.borderColor = UIColor.purple.withAlphaComponent(1).cgColor
        connectButton.backgroundColor = UIColor.purple.withAlphaComponent(0.6)
        connectButton.isUserInteractionEnabled = false
        connectButton.addTarget(self, action: #selector(connectButtonAction), for: .touchUpInside)
        self.connectButton = connectButton

        let dfuButton = UIButton(type: .custom)
        contentView.addSubview(dfuButton)
        dfuButton.snp.makeConstraints({
            $0.centerY.equalToSuperview()
            $0.trailing.equalTo(connectButton.snp.leading).offset(-24)
            $0.width.equalTo(120)
            $0.height.equalTo(120)
        })
        dfuButton.setTitle("DFU", for: .normal)
        dfuButton.setTitleColor(UIColor.init(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        dfuButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        dfuButton.layer.cornerRadius = 60
        dfuButton.layer.borderWidth = 3
        dfuButton.layer.borderColor = UIColor.blue.withAlphaComponent(1).cgColor
        dfuButton.backgroundColor = UIColor.blue.withAlphaComponent(0.6)
        dfuButton.isUserInteractionEnabled = false
        dfuButton.isHidden = true
        dfuButton.addTarget(self, action: #selector(dfuButtonButtonAction), for: .touchUpInside)
        self.dfuButton = dfuButton
        
    }

    @objc func connectButtonAction(_ sender: UIButton) {
        connectAction?()
    }

    @objc func dfuButtonButtonAction(_ sender: UIButton) {
        dfuAction?()
    }

    func configCell(_ device: MMTToolForBleDevice?) {
        guard let device = device else {
            return
        }
        titleLabel?.text = device.description
        subTitlelabel?.text = device.advertisementData?.sortAsciiDescription()
        
        switch device.connectStatus {
        case .connected:
            connectButton?.setTitle("connected", for: .normal)
            connectButton?.isUserInteractionEnabled = true
            connectButton?.backgroundColor = UIColor.orange.withAlphaComponent(0.5)
            connectButton?.layer.borderColor = UIColor.orange.cgColor
            connectButton?.setTitleColor(UIColor.init(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
            dfuButton?.isUserInteractionEnabled = true
            dfuButton?.isHidden = false
        case .connecting:
            connectButton?.setTitle("connecting", for: .normal)
            connectButton?.isUserInteractionEnabled = false
            connectButton?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
            connectButton?.layer.borderColor = UIColor.lightGray.cgColor
            connectButton?.setTitleColor(UIColor.init(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
            dfuButton?.isUserInteractionEnabled = false
            dfuButton?.isHidden = true
        case .scan:
            connectButton?.setTitle("scan", for: .normal)
            connectButton?.isUserInteractionEnabled = true
            connectButton?.backgroundColor = UIColor.purple.withAlphaComponent(0.5)
            connectButton?.layer.borderColor = UIColor.purple.cgColor
            connectButton?.setTitleColor(UIColor.init(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
            dfuButton?.isUserInteractionEnabled = false
            dfuButton?.isHidden = true
        case .disconnected:
            connectButton?.setTitle("disconnected", for: .normal)
            connectButton?.isUserInteractionEnabled = false
            connectButton?.backgroundColor = UIColor.red.withAlphaComponent(0.5)
            connectButton?.layer.borderColor = UIColor.red.cgColor
            connectButton?.setTitleColor(UIColor.init(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
            dfuButton?.isUserInteractionEnabled = false
            dfuButton?.isHidden = true
        }
        
        var serviceCount = 0
        
        self.serviceView?.subviews.forEach({
            $0.isHidden = true
        })
        
        for i in 0..<(device.peripheral.services?.count ?? 0) {
            var top = serviceCount * 40
            serviceCount += 1
            let service = device.peripheral.services?[i]
            let serviceTag = self.tagBase + i * 100
            var serviceLabel = self.serviceView?.viewWithTag(serviceTag) as? UILabel
            if serviceLabel == nil {
                serviceLabel = UILabel.init(frame: .zero)
                self.serviceView?.addSubview(serviceLabel!)
                serviceLabel?.tag = serviceTag
                serviceLabel?.snp.makeConstraints({
                    $0.leading.equalToSuperview().offset(10)
                    $0.top.equalTo(top)
                    $0.height.equalTo(40)
                })
            }
            serviceLabel?.textColor = UIColor.init(white: 0, alpha: 1)
            serviceLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            serviceLabel?.isHidden = false
            serviceLabel?.text = "  \(service?.uuid.uuidString ?? "")"
            
            for j in 0..<(service?.characteristics?.count ?? 0) {
                top = serviceCount * 40
                serviceCount += 1
                let character = service?.characteristics?[j]
                let characterTag = serviceTag + j
                
                var characterLabel = self.serviceView?.viewWithTag(characterTag) as? UILabel
                if characterLabel == nil {
                    characterLabel = UILabel.init(frame: .zero)
                    self.serviceView?.addSubview(characterLabel!)
                    characterLabel?.tag = characterTag
                    characterLabel?.snp.makeConstraints({
                        $0.leading.equalToSuperview().offset(10)
                        $0.top.equalTo(top)
                        $0.height.equalTo(40)
                    })
                }
                characterLabel?.textColor = UIColor.init(white: 0.4, alpha: 1)
                characterLabel?.font = UIFont.boldSystemFont(ofSize: 15)
                characterLabel?.isHidden = false
                characterLabel?.text = "      \(character?.uuid.uuidString ?? "")"
            }
        }
        
        self.serviceView?.snp.remakeConstraints({
            $0.top.equalTo(subTitlelabel!.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(serviceCount * 40)
        })
        
//        titleLabel?.text = device.deviceName.safeValue + "  " + device.mac.safeValue + "  " + device.macExtra.safeValue + "  " + device.connectStatus.titleValue
    }
    
    class func cellHeightFor(_ device: MMTToolForBleDevice?) -> CGFloat {
        let subTitle = device?.advertisementData?.sortAsciiDescription()
        let count = subTitle?.count(where: {
            return $0 == "\n"
        }) ?? 10
        var serviceCount = 0
        device?.peripheral.services?.forEach({ service in
            serviceCount += 1
            service.characteristics?.forEach({ character in
                serviceCount += 1
            })
        })
        return CGFloat(40 + 21 * count + 10 + 40 * serviceCount)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
