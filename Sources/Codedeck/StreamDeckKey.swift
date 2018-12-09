//
//  StreamDeckKey.swift
//  Codedeck
//
//  Created by Sherlock, James on 26/11/2018.
//  Copyright © 2018 Sherlouk. All rights reserved.
//

import Foundation
import CoreGraphics

public class StreamDeckKey {
    
    enum Error: Swift.Error, LocalizedError {
        case rgbValueOutOfRange(value: Int)
        
        var errorDescription: String? {
            switch self {
            case .rgbValueOutOfRange(let value):
                return "RGB value was out of bounds (>= 0 and <= 255 was \(value))"
            }
        }
    }
    
    let streamDeck: StreamDeck
    let keyIndex: Int
    
    internal init(streamDeck: StreamDeck, keyIndex: Int) {
        self.streamDeck = streamDeck
        self.keyIndex = keyIndex
    }
    
    // Public
    
    public var isPressed: Bool {
        return streamDeck.keysPressed[keyIndex] == true
    }
    
    public func clear() throws {
        try setColor(red: 0, green: 0, blue: 0)
    }
    
    static let NUM_FIRST_PAGE_PIXELS = 2583
    static let NUM_SECOND_PAGE_PIXELS = 2601
    
    public func setColor(red: Int, green: Int, blue: Int) throws {
        try assertRGBValue(red)
        try assertRGBValue(green)
        try assertRGBValue(blue)
        
        let bytes: [UInt8] = [blue, green, red].map({ UInt8($0) })
        let data = Data(bytes: bytes)
        
        let firstPage = streamDeck.dataPageOne(keyIndex: keyIndex, data: data.repeated(count: StreamDeckKey.NUM_FIRST_PAGE_PIXELS))
        let secondPage = streamDeck.dataPageTwo(keyIndex: keyIndex, data: data.repeated(count: StreamDeckKey.NUM_SECOND_PAGE_PIXELS))
        
        streamDeck.write(data: firstPage)
        streamDeck.write(data: secondPage)
    }
    
    public func setImage(withActions actions: (CGContext, CGSize) -> Void) {
        guard let context = CGContext(data: nil, width: streamDeck.product.iconSize, height: streamDeck.product.iconSize, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            fatalError("Could not create a context for StreamDeck")
        }
        
        actions(context, CGSize(width: streamDeck.product.iconSize, height: streamDeck.product.iconSize))
        
        guard let rawPointer = context.data else {
            fatalError("Could not get data for the context")
        }
        
        let numberOfBytes = context.height * context.bytesPerRow
        
        let buffer = UnsafeBufferPointer(start: rawPointer.bindMemory(to: UInt8.self, capacity: numberOfBytes), count: numberOfBytes)
        let imageData = Data(buffer: buffer)
        
        let firstPageImageData = imageData[0 ..< StreamDeckKey.NUM_FIRST_PAGE_PIXELS]
        let secondPageImageData = imageData[StreamDeckKey.NUM_FIRST_PAGE_PIXELS ..< StreamDeckKey.NUM_FIRST_PAGE_PIXELS + StreamDeckKey.NUM_SECOND_PAGE_PIXELS]
        
        let firstPage = streamDeck.dataPageOne(keyIndex: keyIndex, data: firstPageImageData)
        let secondPage = streamDeck.dataPageTwo(keyIndex: keyIndex, data: secondPageImageData)
        
        streamDeck.write(data: firstPage)
        streamDeck.write(data: secondPage)
    }
    
    // Private
    
    private func assertRGBValue(_ value: Int) throws {
        guard (0...255).contains(value) else {
            throw Error.rgbValueOutOfRange(value: value)
        }
    }
    
}
