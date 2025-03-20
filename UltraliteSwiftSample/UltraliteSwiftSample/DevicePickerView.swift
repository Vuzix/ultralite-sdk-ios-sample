//
//  ContentView.swift
//  Exercise Watch App
//
//  Created by Joe Martin on 1/11/23.
//

import SwiftUI
import CoreBluetooth
import UltraliteSDK


struct UltralitePeripheral: Identifiable, Hashable {
    var name: String {
        return peripheral.name ?? "peripheral: \(id.uuidString)"
    }
    let id = UUID()
    let peripheral: CBPeripheral
}


struct DevicePickerView: View {
    
    @EnvironmentObject var model: BleScanServiceModel
    
    @State private var paths = NavigationPath()
    
    @State private var dataProvider: [CBPeripheral] = []
    
    var connectedName: String {
        return UltraliteManager.shared.currentDevice?.getName() ?? "Vuzix Smart Glasses"
    }
    
    var batteryLevel: Int {
        return UltraliteManager.shared.currentDevice?.batteryLevel.value ?? 0
    }
    
    func getBatteryLevelString(value: Int) -> String {
        return value == -1 ? "-" : "\(value)%"
    }
    
    func getBatteryLevelImage(value: Int) -> UIImage {
        if value >= 95 {
            return UIImage(named: "battery100")!
        }
        else if value >= 80 {
            return UIImage(named: "battery80")!
        }
        else if value >= 60 {
            return UIImage(named: "battery60")!
        }
        else if value >= 40 {
            return UIImage(named: "battery40")!
        }
        else if value >= 20 {
            return UIImage(named: "battery20")!
        }
        else {
            return UIImage.animatedImage(with: [UIImage(named: "battery0")!, UIImage(named: "battery20")!], duration: 0.5)!
        }
    }
    
    var body: some View {
        NavigationStack(path: $paths) {
            VStack {
                if model.connectedPeripheral == nil {
                    List(dataProvider) { peripheral in
                        Button(peripheral.name ?? "Vuzix") {
                            model.linkToPeripheral(peripheral: peripheral)
                        }
                    }
                }
                else {
                    VStack {
                        VStack {
                            Text(connectedName)
                                .padding(EdgeInsets(top: 4, leading: 2, bottom: 0, trailing: 2))
                                .lineLimit(nil)
                            HStack{
                                Image(uiImage: getBatteryLevelImage(value: model.batteryLevel))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20.0, height: 14.0)
                                Text(getBatteryLevelString(value: model.batteryLevel))
                                Spacer()
                                Button("Unlink") {
                                    model.unlink()
                                }
                                .padding()
                                .foregroundColor(Color(uiColor: .lightGray))
                                .font(Font.system(size: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color(uiColor: .lightGray), lineWidth: 1)
                                )
                                .buttonStyle(PlainButtonStyle())
                                
                            }
                            .padding(10)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .overlay( /// apply a rounded border
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.green, lineWidth: 1)
                        )
                        
                        Button("Start Activity") {
                            paths.append(model.connectedUltralite!)
                        }
                    }
                    .navigationTitle("Connected")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .navigationDestination(for: Ultralite.self) { ultralite in
                ContentView()
            }
            .padding()
            .navigationTitle("Searching for Vuzix ...")
            .onReceive(model.$connectedPeripheral, perform: { peripheral in
                if let peripheral = peripheral {
                    print("we have a connected peripheral, changing dataProvider")
                    dataProvider = [peripheral]
                }
                else {
                    print("scanning...")
                    dataProvider = Array(model.scannedPeripherals)
                }
            })
            .onReceive(model.$scannedPeripherals, perform: { peripherals in
                dataProvider = Array(peripherals)
            })
            .onReceive(model.$reset) { reset in
                if reset {
                    paths = NavigationPath()
                    model.reset = false
                }
            }
            .onReceive(model.$batteryLevel) { level in
                getBatteryLevelString(value: level)
            }
        }
    }
       
}

struct DevicePickerView_Previews: PreviewProvider {
    static var previews: some View {
        let store = BleScanServiceModel()
        DevicePickerView().environmentObject(store)
    }
}
