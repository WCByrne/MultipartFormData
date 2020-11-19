//
//  MultipartFormDataTests.swift
//  MultipartFormDataTests
//
//  Created by Wesley Byrne on 5/1/19.
//  Copyright © 2019 Lingo. All rights reserved.
//

import XCTest
@testable import MultipartFormData

class TestMultipartFormData: XCTestCase {

    private func redactUUID(msg: String) -> String {
        let uuid = "[A-Za-z0-9]"
        let regex = try! NSRegularExpression(pattern: "\(uuid){8}-\(uuid){4}-\(uuid){4}-\(uuid){4}-\(uuid){12}", options: [])
        let range = NSRange(msg.startIndex..<msg.endIndex, in: msg)
        return regex.stringByReplacingMatches(in: msg, options: [], range: range, withTemplate: "<UUID>")
    }

    func testGetDataWithProperties() {

        let props: [String: MultipartFormData.Property] = [
            "name": .property("steve"),
            "age": .property("40")
        ]
        let formData = MultipartFormData(properties: props)
        do {
            let data = try formData.data()
            let output = redactUUID(msg: String(data: data, encoding: .utf8)!)

            let expected = [
                "--Boundary-<UUID>\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nsteve\r\n",
                "--Boundary-<UUID>\r\nContent-Disposition: form-data; name=\"age\"\r\n\r\n40\r\n",
                "--Boundary-<UUID>--\r\n"
            ]
            for str in expected {
                XCTAssertTrue(output.contains(str))
            }

            XCTAssertEqual(expected.joined().count, output.count)
            let endsWith = expected.last!
            XCTAssertTrue(output.hasSuffix(endsWith))
        } catch {
            XCTFail("Failed to create formData")
        }
    }

    func testWriteWithProperties() {
        let props: [String: MultipartFormData.Property] = [
            "name": .property("steve"),
            "age": .property("40")
        ]
        let formData = MultipartFormData(properties: props)
        do {
            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            try formData.write(to: url)
            let output = redactUUID(msg: try String(contentsOf: url))

            let expected = [
                "--Boundary-<UUID>\r\nContent-Disposition: form-data; name=\"name\"\r\n\r\nsteve\r\n",
                "--Boundary-<UUID>\r\nContent-Disposition: form-data; name=\"age\"\r\n\r\n40\r\n",
                "--Boundary-<UUID>--\r\n"
            ]
            for str in expected {
                XCTAssertTrue(output.contains(str))
            }

            XCTAssertEqual(expected.joined().count, output.count)
            let endsWith = expected.last!
            XCTAssertTrue(output.hasSuffix(endsWith))
        } catch {
            XCTFail("Failed to create formData")
        }
    }

    func testWriteWithSources() {
        do {
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            let data = "This is some data".data(using: .utf8)!
            try data.write(to: fileURL)
            let formData = MultipartFormData(properties: ["file": .file(fileURL)])

            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            try formData.write(to: url)
            let output = redactUUID(msg: try String(contentsOf: url))

            let expected = [
                "--Boundary-<UUID>\r\nContent-Disposition: form-data; name=\"file\"; filename=\"<UUID>\"\r\nContent-Type: application/octet-stream\r\n\r\nThis is some data\r\n", // swiftlint:disable:this line_length
                "--Boundary-<UUID>--\r\n"
            ]
            for str in expected {
                XCTAssertTrue(output.contains(str))
            }

            XCTAssertEqual(expected.joined().count, output.count)
            let endsWith = expected.last!
            XCTAssertTrue(output.hasSuffix(endsWith))
        } catch {
            XCTFail("Failed to create formData")
        }
    }
    
    func testWriteWithCustomNameFile() {
        do {
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            let data = "This is some data".data(using: .utf8)!
            try data.write(to: fileURL)
            let file = MultipartFormData.File(url: fileURL, name: "My File")
            let formData = MultipartFormData(properties: ["file": .file(file)])

            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            try formData.write(to: url)
            let output = redactUUID(msg: try String(contentsOf: url))

            let expected = [
                "--Boundary-<UUID>\r\nContent-Disposition: form-data; name=\"file\"; filename=\"My File\"\r\nContent-Type: application/octet-stream\r\n\r\nThis is some data\r\n", // swiftlint:disable:this line_length
                "--Boundary-<UUID>--\r\n"
            ]
            for str in expected {
                XCTAssertTrue(output.contains(str))
            }

            XCTAssertEqual(expected.joined().count, output.count)
            let endsWith = expected.last!
            XCTAssertTrue(output.hasSuffix(endsWith))
        } catch {
            XCTFail("Failed to create formData")
        }
    }
    
    func testWriteWithPartialFileSources() {
        do {
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            let data = "data 1data 2data 3data 4".data(using: .utf8)!
            try data.write(to: fileURL)
            // Trying to target "data 2"
            let length: UInt64 = UInt64(data.count/4)
            let offset = length
            let file = MultipartFormData.File(url: fileURL, offset: offset, length: length)
            let formData = MultipartFormData(properties: ["file": .file(file)])

            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            try formData.write(to: url)
            let output = redactUUID(msg: try String(contentsOf: url))

            let expected = [
                "--Boundary-<UUID>\r\nContent-Disposition: form-data; name=\"file\"; filename=\"<UUID>\"\r\nContent-Type: application/octet-stream\r\n\r\ndata 2\r\n", // swiftlint:disable:this line_length
                "--Boundary-<UUID>--\r\n"
            ]
            for str in expected {
                XCTAssertTrue(output.contains(str))
            }

            XCTAssertEqual(expected.joined().count, output.count)
            let endsWith = expected.last!
            XCTAssertTrue(output.hasSuffix(endsWith))
        } catch {
            XCTFail("Failed to create formData")
        }
    }

}
