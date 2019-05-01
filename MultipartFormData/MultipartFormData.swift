//
//  MultipartFormData.swift
//  MultipartFormData
//
//  Created by Wesley Byrne on 5/1/19.
//  Copyright © 2019 Lingo. All rights reserved.
//

import Foundation


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

protocol MultipartFormDataSource {
    var name: String { get }
    var url: URL { get }
}

extension URL: MultipartFormDataSource {
    var name: String { return self.lastPathComponent }
    var url: URL { return self }
}

public class MultipartFormData {

    enum Error: Swift.Error {
        case unknown
    }

    public struct Source: MultipartFormDataSource {
        let name: String
        let url: URL
    }

    let properties: [String: Any]
    let sources: [String: MultipartFormDataSource]

    let boundary: String = "Boundary-\(NSUUID().uuidString)"

    var contentType: String {
        return "multipart/form-data; boundary=\(self.boundary)"
    }

    init(properties: [String: Any] = [:], sources: [String: MultipartFormDataSource] = [:]) {
        self.properties = properties
        self.sources = sources
    }

    func data() throws -> Data {
        var data: Data = Data()
        try self.process(with: &data)
        return data
    }

    /// Write the data for use in an upload task
    ///
    /// - Parameter to: A file url to write to
    func write(to destination: URL) throws {
        guard FileManager.default.createFile(atPath: destination.path, contents: nil, attributes: nil) else {
            throw Error.unknown
        }
        var writer = try FileHandle(forWritingTo: destination)
        try self.process(with: &writer)
        writer.closeFile()
    }

    private func process<T: Writable>(with target: inout T) throws {
        self.writeProperties(to: &target)
        try self.writeSources(to: &target)
        target.append("--\(boundary)--\r\n")
    }

    private func writeProperties<T: Writable>(to target: inout T) {
        for (key, value) in self.properties {
            target.append("--\(boundary)\r\n")
            target.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            target.append("\(value)\r\n")
        }
    }

    private func writeSources<T: Writable>(to target: inout T) throws {
        for (key, source) in sources {
            let mimetype = MultipartFormData.mimeType(for: source.url)

            target.append("--\(boundary)\r\n")
            target.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(source.name)\"\r\n")
            target.append("Content-Type: \(mimetype)\r\n\r\n")
            try target.appendFile(at: source.url)
            target.append("\r\n")
        }
    }

    private class func mimeType(for url: URL) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream";
    }
}
