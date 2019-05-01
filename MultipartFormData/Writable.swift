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

extension Writable {
    mutating func appendFile(at url: URL, chunkSize: Int = 1000000) throws {
        let reader = try FileHandle(forReadingFrom: url)
        var data = reader.readData(ofLength: chunkSize)
        while !data.isEmpty {
            self.append(data)
            data = reader.readData(ofLength: chunkSize)
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

