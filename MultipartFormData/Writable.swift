//
//  Writable.swift
//  SwiftMark
//
//  Created by Wesley Byrne on 5/1/19.
//  Copyright © 2019 The Noun Project. All rights reserved.
//

import Foundation

protocol Writable {
    mutating func append(_ string: String)
    mutating func append(_ data: Data)
}

extension FileHandle {
    var currentOffset: UInt64 {
        if #available(OSX 10.15.4, *) {
            return try! self.offset()
        } else {
            return self.offsetInFile
        }
    }
}

extension Writable {
    mutating func appendFile(_ file: MultipartFormDataFile) throws {
        let reader = try FileHandle(forReadingFrom: file.url)
        
        if let offset = file.offset {
            if #available(OSX 10.15, *) {
                try reader.seek(toOffset: offset)
            } else {
                reader.seek(toFileOffset: offset)
            }
        }
        
        func getChunkSize() throws -> Int {
            if let length = file.length {
                let max = (file.offset ?? 0) + length
                let current = reader.currentOffset
                if current >= max { return 0 }
                return Int(min(max - current, 1000000))
            }
            return 1000000
        }
        
        var data = try reader.readData(ofLength: getChunkSize())
        while !data.isEmpty {
            self.append(data)
            data = try reader.readData(ofLength: getChunkSize())
        }
        reader.closeFile()
    }
}

extension FileHandle: Writable {
    func write(_ string: String) {
        guard let d = string.data(using: .utf8) else { return }
        self.write(d)
    }

    func append(_ data: Data) {
        self.write(data)
    }
    func append(_ string: String) {
        self.write(string)
    }
}

extension Data: Writable {
    mutating func append(_ string: String) {
        guard let data = string.data(using: .utf8, allowLossyConversion: true) else { return }
        self.append(data)
    }
}
