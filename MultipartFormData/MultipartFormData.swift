//
//  MultipartFormData.swift
//  MultipartFormData
//
//  Created by Wesley Byrne on 5/1/19.
//  Copyright © 2019 Lingo. All rights reserved.
//

import Foundation

public class MultipartFormData {

    enum Error: Swift.Error {
        case unknown
    }

    public struct Source: MultipartFormDataSource {
        public let name: String
        public let url: URL
    }

    public let properties: [String: Any]
    public let sources: [String: MultipartFormDataSource]

    public let boundary: String = "Boundary-\(NSUUID().uuidString)"

    public var contentType: String {
        return "multipart/form-data; boundary=\(self.boundary)"
    }

    public init(properties: [String: Any] = [:], sources: [String: MultipartFormDataSource] = [:]) {
        self.properties = properties
        self.sources = sources
    }

    public func data() throws -> Data {
        var data: Data = Data()
        try self.process(with: &data)
        return data
    }

    /// Write the data for use in an upload task
    ///
    /// - Parameter to: A file url to write to
    public func write(to destination: URL) throws {
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
