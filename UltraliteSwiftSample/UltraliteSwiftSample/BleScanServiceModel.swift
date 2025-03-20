//
//  BleStack.swift
//  Exercise Watch App
//
//  Created by Joe Martin on 1/12/23.
//

import Foundation
import CoreBluetooth
import UltraliteSDK

extension CBPeripheral: @retroactive Identifiable {
    
}

class BleScanServiceModel: ObservableObject {
    
    @Published var state: String = "unknown"
    
    @Published var reset: Bool = false
    
    @Published var scannedPeripherals: Set<CBPeripheral> = []
    
    @Published var isConnected: Bool = false
    
    @Published var connectedPeripheral: CBPeripheral? = nil
    
    @Published var connectedUltralite: Ultralite? = nil
    
    @Published var batteryLevel: Int = 0
    
    private var connectionListener: BondListener<Bool>?
    private var isReadyListener: BondListener<Bool>?
    private var isConnectedListener: BondListener<Bool>?
    private var batteryLevelListener: BondListener<Int>?
    
    init() {

        if UltraliteManager.shared.isReady.value == true {
            updateView(isConnected: UltraliteManager.shared.currentDevice?.isConnected.value ?? false)
        }
        else {
            isReadyListener = BondListener(listener: { [weak self] isReady in
                self?.updateView(isConnected: UltraliteManager.shared.currentDevice?.isConnected.value ?? false)
            })
            UltraliteManager.shared.isReady.bind(listener: isReadyListener!)
        }
        
        if let device = UltraliteManager.shared.currentDevice {
            // we are just waiting to be connected, since we are linked
            isConnectedListener = BondListener(listener: {[weak self] isConnected in
                if isConnected {
                    print("isConnected")
                    self?.connectedUltralite = device
                    self?.connectedPeripheral = device.peripheral
                    self?.isConnected = true
                }
                else {
                    print("not isConnected")
                    self?.connectedUltralite = nil
                    self?.connectedPeripheral = nil
                    self?.isConnected = false
                }
                self?.updateView(isConnected: isConnected)
            })
            device.isConnected.bind(listener: isConnectedListener!)
        }
    }
    
    func updateView(isConnected: Bool) {
        print("updateView: \(isConnected)")
        self.isConnected = isConnected
        
        if !isConnected {
            connectedPeripheral = nil
            connectedUltralite = nil
            if !UltraliteManager.shared.isScanning.value {
                print("starting scan")
                scannedPeripherals = []
                _ = UltraliteManager.shared.startScan { [weak self] peripheral in
                    DispatchQueue.main.async { [weak self] in 
                        self?.scannedPeripherals.insert(peripheral)  // append(peripheral)
                    }
                }
            }
            
            if let batteryLevelListener = batteryLevelListener {
                UltraliteManager.shared.currentDevice?.batteryLevel.unbind(listener: batteryLevelListener)
                self.batteryLevelListener = nil
            }
        }
        else {
            print("Stop Scan")
            UltraliteManager.shared.stopScan()
            scannedPeripherals = []
            connectedUltralite = UltraliteManager.shared.currentDevice
            connectedPeripheral = UltraliteManager.shared.currentDevice?.peripheral
            
            batteryLevelListener = BondListener(listener: { [weak self] level in
                self?.batteryLevel = level
            })
            UltraliteManager.shared.currentDevice?.batteryLevel.bind(listener: batteryLevelListener!)
        }
    }

    func linkToPeripheral(peripheral: CBPeripheral) {
        print("Connecting to Ultralite")
        UltraliteManager.shared.link(device: peripheral) { [weak self] ultralite in
            DispatchQueue.main.async{ [weak self] in
                self?.scannedPeripherals = []
                self?.connectedUltralite = ultralite
                self?.connectedPeripheral = ultralite?.peripheral
                self?.isConnected = true
            }
        }
    }
    
    func unlink() {
        UltraliteManager.shared.unlink()
        connectedUltralite = nil
        connectedPeripheral = nil
        isConnected = false
        updateView(isConnected: false)
    }
    
    
    func deviceStateToString(state: DeviceState) -> String {
        switch (state) {
            
        case .bluetoothNotAuthorized:
            return "bluetooth not authorized"
        case .bluetoothOff:
            return "bluetooth off"
        case .scanning:
            return "scanning"
        case .notConnected:
            return "not connected"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .unknown:
            return "unknown"
        case .notBonded:
            return "not bonded"
        case .notBondedNoInput:
            return "not bonded no input"
        case .authenticationFailed:
            return "authentication failed"
        }
    }
}
