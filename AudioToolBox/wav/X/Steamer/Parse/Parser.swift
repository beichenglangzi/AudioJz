//
//  Parser.swift
//  AudioStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

/// The `Parser` is a concrete implementation of the `Parsing` protocol used to convert binary data into audio packet data. This class uses the Audio File Stream Services to progressively parse the properties and packets of the incoming audio data.
public class Parser: Parsing {
    static let logger = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser")
    static let loggerPacketCallback = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.Packets")
    static let loggerPropertyListenerCallback = OSLog(subsystem: "com.fastlearner.streamer", category: "Parser.PropertyListener")
    
    // MARK: - Parsing props
    
    public internal(set) var dataFormatD: AVAudioFormat?
    public internal(set) var packetsX = [Data]()
    public var totalPacketCount: AVAudioPacketCount? {
        guard let _ = dataFormatD else {
            return nil
        }
        
        return max(AVAudioPacketCount(packetCount), AVAudioPacketCount(packetsX.count))
    }
    
    // MARK: - Properties
    
    /// A `UInt64` corresponding to the total frame count parsed by the Audio File Stream Services
    public internal(set) var frameCount: UInt64 = 0
    
    /// A `UInt64` corresponding to the total packet count parsed by the Audio File Stream Services
    public internal(set) var packetCount: UInt64 = 0
    
    
    
    // 把一个文件，弄成一个 ID, 拿这个 ID , 去处理事情
    
    // 一个文件，对应一个AudioFileStreamID
    
    
    /// The `AudioFileStreamID` used by the Audio File Stream Services for converting the binary data into audio packets
    fileprivate var streamID: AudioFileStreamID?
    
    // MARK: - Lifecycle
    
    /// Initializes an instance of the `Parser`
    ///
    /// - Throws: A `ParserError.streamCouldNotOpen` meaning a file stream instance could not be opened
    public init() throws {
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        guard AudioFileStreamOpen(context, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileWAVEType, &streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }
    
    // MARK: - Methods
    
    public func parse(data: Data) throws {
        os_log("%@ - %d", log: Parser.logger, type: .debug, #function, #line)
        
        let streamID = self.streamID!
        let count = data.count
        _ = try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            let result = AudioFileStreamParseBytes(streamID, UInt32(count), bytes, [])
            guard result == noErr else {
                os_log("Failed to parse bytes", log: Parser.logger, type: .error)
                throw ParserError.failedToParseBytes(result)
            }
        }
    }

}
