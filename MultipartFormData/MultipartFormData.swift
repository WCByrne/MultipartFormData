//
//  MultipartFormData.swift
//  MultipartFormData
//
//  Created by Wesley Byrne on 5/1/19.
//  Copyright © 2019 Lingo. All rights reserved.
//

import Foundation
#if os(iOS)
import MobileCoreServices
#endif

public class MultipartFormData {

    /// The properties to be included in the form data
    public let properties: [String: Property]

    /// The boundary used for the form data
    public let boundary: String = "Boundary-\(NSUUID().uuidString)"

    /// The content type to use for a request including the boundary
    public var contentType: String {
        return "multipart/form-data; boundary=\(self.boundary)"
    }

    public init(properties: [String: Property]) {
        self.properties = properties
    }

    /// Create the form data
    ///
    /// - returns: Data a data object with the form data
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
            throw Error.fileWriteFailed
        }
        var writer = try FileHandle(forWritingTo: destination)
        try self.process(with: &writer)
        writer.closeFile()
    }
}

extension MultipartFormData {

    private func process<T: Writable>(with target: inout T) throws {
        try self.writeProperties(to: &target)
        target.append("--\(boundary)--\r\n")
    }

    private func writeProperties<T: Writable>(to target: inout T) throws {
        for (key, value) in self.properties {
            target.append("--\(boundary)\r\n")
            switch value {
            case let .file(file):
                let mimetype = MultipartFormData.mimeType(for: file.url)
                target.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.name)\"\r\n")
                target.append("Content-Type: \(mimetype)")
                target.append("\r\n\r\n")
                do {
                    try target.appendFile(file)
                } catch {
                    throw Error.fileNotFound
                }

            case let .data(data, contentType):
                target.append("Content-Disposition: form-data; name=\"\(key)\";")
                target.append("Content-Type: \(contentType);")
                target.append("\r\n\r\n")
                target.append(data)

            case let .property(prop):
                target.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                target.append(prop)
            }
            target.append("\r\n")
        }
    }

    private class func mimeType(for url: URL) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, url.pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}
