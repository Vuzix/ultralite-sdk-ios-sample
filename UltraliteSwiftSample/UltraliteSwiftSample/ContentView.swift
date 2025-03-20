//
//  ContentView.swift
//  UltraliteWatchSample Watch App
//
//  Created by Joe Martin on 10/29/24.
//

import SwiftUI
import UltraliteSDK

struct ContentView: View {
    
    let drawing = Drawing()
    
    var body: some View {
        VStack {
            Image(systemName: "iphone")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, iPhone!")
            Button("start") {
                drawing.startDrawing()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}


class Drawing {
    
    var isPresenting = false
    
    public func startDrawing() {
        
        if isPresenting {
            return
        }
        
        isPresenting = true
        startControl()
        Task.init() { [weak self] in
            await self?.pause(1)
            
            await self?.sayHello()
            await self?.showPicture()
            await self?.endOfShow()
            
            self?.stopControl()
            self?.isPresenting = false
        }
        
    }
    
    func startControl() {
        _ = UltraliteManager.shared.currentDevice?.requestControl(layout: .canvas, timeout: 200)
    }
    
    func stopControl() {
        UltraliteManager.shared.currentDevice?.releaseControl()
    }
    
    func pause(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
    }
    
    func sayHello() async {
        guard let canvas = UltraliteManager.shared.currentDevice?.canvas else {
            return
        }
        
        canvas.drawStaticText(text: "Hello from iPhone", font: UIFont(name: "Noto Sans Brahmi Regular", size: 40)!, color: CGColor(gray: 1.0, alpha: 1.0), x: 100, y: 100)
        canvas.commit()
        
        await pause(7)
    }
    
    func showPicture() async {
        guard let canvas = UltraliteManager.shared.currentDevice?.canvas else {
            return
        }
        
        canvas.clearBackground()
        canvas.drawStaticText(text: "This is Futura extra bold", font: UIFont(name: "Futura-CondensedExtraBold", size: 40)!, color: CGColor(gray: 1.0, alpha: 1.0), x: 100, y: 100)
        canvas.drawStaticText(text: "with image of iphone.", font: UIFont(name: "Futura-CondensedExtraBold", size: 40)!, color: CGColor(gray: 1.0, alpha: 1.0), x: 100, y: 150)
        canvas.drawBackground(image: UIImage.init(systemName: "iphone")!.cgImage!, x: 150, y: 200)
        canvas.commit()
        
        await pause(7)
    }
    
    func endOfShow() async {
        guard let canvas = UltraliteManager.shared.currentDevice?.canvas else {
            return
        }
        
        canvas.clearBackground()
        
        canvas.drawStaticText(text: "Goodbye Friend", font: UIFont(name: "Helvetica Bold", size: 40)!, color: CGColor(gray: 1.0, alpha: 1.0), x: 100, y: 100)
        canvas.drawBackground(image: UIImage.init(systemName: "moon.zzz")!.cgImage!, x: 200, y: 150)
        canvas.commit()
        
        await pause(7)
    }
}

