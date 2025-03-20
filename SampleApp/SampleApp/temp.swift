import Foundation
import UltraliteSDK
import UIKit
import CoreGraphics
 
 
class VuzixTextManager{
    public var vuzixDevice:Ultralite?
    private var layoutManager: NSLayoutManager
    private var textContainer: NSTextContainer
    private var textStorage: NSTextStorage
    private var slices: [(CGImage, CGRect)] = []
    private var shouldScroll = false
    private var size: CGSize! // size of the textContainer
    private var numSlices = 10
    private var sliceHeight = 48
    
    public init(vuzixDevice: Ultralite) {
        self.vuzixDevice = vuzixDevice
        self.textStorage = NSTextStorage(string: "Hello, world!")
        self.size = CGSize(width: Ultralite.DISPLAY_WIDTH, height: Ultralite.DISPLAY_HEIGHT)
        self.textContainer = NSTextContainer(size: self.size)
        self.layoutManager = NSLayoutManager()
        self.layoutManager.addTextContainer(textContainer)
        self.textStorage.addLayoutManager(layoutManager)
        self.textContainer.lineFragmentPadding = 0
        self.textContainer.lineBreakMode = .byWordWrapping
    }
    
    
    public func requestControl(){
        let success = self.vuzixDevice?.requestControl(
            layout: .scroll,
            timeout: 10,
            hideStatusBar: false,
            showTapAnimation: true,
            maxNumTaps: 2
        )
        
        self.vuzixDevice?.scrollLayout?.config(sliceHeight: self.sliceHeight, numSlicesVisible: self.numSlices, duration: 150, autoScroll: false)
        
        print("Request control: \(success ?? false)")
    }
    
    private func createBitmapSlices() {
        let oldSlicesCount = self.slices.count
        UIGraphicsBeginImageContext(self.size)
        let range = self.layoutManager.glyphRange(for: textContainer)
        print("Glyph range: \(range)")
        self.layoutManager.drawGlyphs(forGlyphRange: range, at: .zero)
        
        // Save the context as a new UIImage
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // create the slices from the image.
        if let cgImage = image?.cgImage {
            self.slices = cgImage.slice(sliceHeight: self.sliceHeight, startFromBottom: true)  // Public in SDK -- CGImage.slice -> sends back [(CGImage, CGRect)]
            print("CGImage size: \(cgImage.width)x\(cgImage.height)")
        }
        print("Image size: \(String(describing: image?.size))")
        print("Number of slices created: \(slices.count)")
        if self.slices.count == oldSlicesCount + 1 {
            shouldScroll = true
        }
        // fix the last one, as the height will not be perfect, due to floats
        var last = self.slices.popLast()
        if let lastItem = last, lastItem.0.height != self.sliceHeight {
            if let fixed = lastItem.0.resizeCanvas(size: CGSize(width: lastItem.0.width, height: self.sliceHeight)) {
                last?.0 = fixed
                self.slices.append(last!)
                return
            }
        }
        
        if let last = last {
            self.slices.append(last)
        }
        
    }
 
    public func sendText(text: String, fontSize:CGFloat){
        print("Received \(text)")
        // Update the textStorage with the new text
        self.textStorage.replaceCharacters(in: NSRange(location: 0, length: textStorage.length), with: text)
        self.textStorage.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: textStorage.length))
        
        // Create new slices based on the updated text
        self.createBitmapSlices()
 
        // Send the updated slices
        if !self.slices.isEmpty {
            print("Slices count: \(self.slices.count)")
            for (index, slice) in self.slices.enumerated() {
                print("Sending slice - width: \(slice.0.width), height: \(slice.0.height)")
                self.vuzixDevice?.scrollLayout?.sendImage(image: slice.0, slicePosition: index, scrollFirst: false)
            }
        }
    }
 }
