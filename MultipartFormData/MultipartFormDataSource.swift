//
//  MultipartFormDataSource.swift
//  SwiftMark
//
//  Created by Wesley Byrne on 5/1/19.
//  Copyright © 2019 The Noun Project. All rights reserved.
//

import Foundation

public protocol MultipartFormDataSource {
    var name: String { get }
    var url: URL { get }
}

extension URL: MultipartFormDataSource {
    public var name: String { return self.lastPathComponent }
    public var url: URL { return self }
}
