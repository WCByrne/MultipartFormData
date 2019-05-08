//
//  URLSession+multipart.swift
//  MultipartFormData
//
//  Created by Wesley Byrne on 5/2/19.
//  Copyright © 2019 Lingo. All rights reserved.
//

import Foundation

public extension URLSession {

    /// Create an upload task with multipart form-data
    ///
    /// Note `resume()` must be called to initiate the taks
    ///
    /// - Parameter url: The URL for the request
    /// - Parameter method: The method for the request (default POST)
    /// - Parameter properties: Properties to include in the form data
    /// - Returns: An upload task in a ready state
    func uploadTask(url: URL, method: String = "POST", properties: [String: MultipartFormData.Property]) throws -> URLSessionUploadTask {
        var request = URLRequest(url: url)
        request.httpMethod = method
        return try self.uploadTask(with: request, properties: properties)
    }

    /// Create an upload task with multipart form-data and a prepared URL request
    ///
    /// Content type will be added or overriden (if exiting) to `multipart/form-data`
    ///
    /// `resume()` must be called to initiate the taks
    ///
    /// - Parameter request: A URL request
    /// - Parameter properties: Properties to include in the form data
    /// - Returns: An upload task in a ready state
    func uploadTask(with request: URLRequest, properties: [String: MultipartFormData.Property]) throws -> URLSessionUploadTask {
        let url = URL(string: NSTemporaryDirectory())!.appendingPathComponent(UUID().uuidString)
        let data = MultipartFormData(properties: properties)
        try data.write(to: url)
        var req = request
        req.setValue(data.contentType, forHTTPHeaderField: "Content-Type")
        return self.uploadTask(with: req, fromFile: url)
    }
}
