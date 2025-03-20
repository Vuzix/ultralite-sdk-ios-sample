//
//  UltraliteWatchSampleApp.swift
//  UltraliteWatchSample Watch App
//
//  Created by Joe Martin on 10/29/24.
//

import SwiftUI

@main
struct UltraliteWatchSample_Watch_AppApp: App {
    @StateObject var model = BleScanServiceModel()
    
    var body: some Scene {
        WindowGroup {
            DevicePickerView().environmentObject(model)
        }
    }
}
