//
//  Sources.swift
//  MultipartFormDataTests
//
//  Created by Wesley Byrne on 5/1/19.
//  Copyright © 2019 Lingo. All rights reserved.
//

import Foundation

/// An object that represents a file
///
/// MultipartFormDataFile abstracts references to a file making it possible to use a URL or a MultipartFormData.File object.
///
/// The name for a url is considered the last path component
///
/// To provide a custom file name, use MultipartFormData.File or your own custom object that conforms to this protocol
public protocol MultipartFormDataFile {
    var name: String { get }
    var url: URL { get }
}

extension URL: MultipartFormDataFile {
    public var name: String { return self.lastPathComponent }
    public var url: URL { return self }
}

public extension MultipartFormData {
    enum Error: Swift.Error {
        case unknown
        case fileNotFound
        case fileWriteFailed
    }

    /// A file object for naming a file differently than it's file path
    struct File: MultipartFormDataFile {
        public let name: String
        public let url: URL
    }

    /// The types of properties allows in multipart form data
    /// The keys for each property are derived from the properties dictionary on the MultipartFormdata object.
    enum Property {
        /// A standard form data property
        case property(String)
        /// A file
        case file(MultipartFormDataFile)
        /// Any data and it's associated content type
        /// This can be used to include encoded JSON data with application/json
        case data(Data, String)
    }
}
