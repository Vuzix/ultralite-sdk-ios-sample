//
//  UltraliteSwiftSampleApp.swift
//  UltraliteSwiftSample
//
//  Created by Joe Martin on 10/28/24.
//

import SwiftUI
import UltraliteSDK

@main
struct UltraliteSwiftSampleApp: App {
    @StateObject var model = BleScanServiceModel()
    
    var body: some Scene {
        WindowGroup {
            //ContentView()
            DevicePickerView().environmentObject(model)
        }
    }
}
