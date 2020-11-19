# MultipartFormData

![Development](https://github.com/WCByrne/MultipartFormData/workflows/Development/badge.svg)

Generate multipart form data in Swift.

This project aims to abstract the the creation of multipart form data as a standalone function. That said it does includes some functions for creating `URLSessionUpload` tasks which make use of the internal form data generation.

## Guide

### Poperties

The following types can be added to the form data
```swift
enum Property {
    /// A standard form data property
    case property(String)
    /// A file
    case file(MultipartFormDataFile)
    /// Any data and it's associated content type
    /// This can be used to include encoded JSON data with application/json
    case data(Data, String)
}
```

### Creating form data

```swift
let avatarFileURL = URL() //the file url on disc
let form = MultipartFormData(properties: [
    "name": .property("Mary"),
    "age": .property("32")
    "avatar": .file(avatarFileURL)
])
```
Or using json...
```swift
let jsonData = try JSONEncoder().encode(["name": "Mary", "age": "32"])
let avatarFileURL = URL() //the file url on disc
let form = MultipartFormData(properties: [
    "userData": .data(jsonData, "application/json")
    "avatar": .file(avatarFileURL)
])
```

customize a file name
```swift
let jsonData = try JSONEncoder().encode(["name": "Mary", "age": "32"])
let avatarFileURL = URL() //the file url on disc
let form = MultipartFormData(properties: [
    "userData": .data(jsonData, "application/json")
    "avatar": .file(MultipartFormData.File(url: avatarFileURL, name: "Avatar"))
])
```

Append parts of a file
```swift
let fileUrl = URL() //the file url on disc
let fileSize = // the size of our file in bytes
let chunkSize = 1024 * 1024 * 5 // 5 mb chunks
let chunkCount = Int((Double(fileSize) / Double(chunkSize)).rounded(.up))

for chunkIndex in 0..<chunkCount {
    let fileChunk = MultipartFormData.File(url: fileUrl,
                                            offset: UInt64(chunkSize * chunkIndex),
                                            length: UInt64(chunkSize))
    let form = MultipartFormData(properties: [
        "chunk_index": .property("\(chunkIndex)")
        "chunk": .file(fileChunk)
    ])
    // ...send request
}
```

### Using form data

The form data can either be returned as data OR written to disc for use in an upload task. Writing to disc is preferred for larger forms as it avoids bringing all the data into memory at one time. Any files included in the form data will be read progressively to the new temporary file before being uploaded.

```swift
// Prepare your requst
let form = MultiPartFormData(properties: [:])
var request = URLRequest(url: URL(string: "api.myservice.com/users")!)
request.addValue(form.contentType, forHTTPHeaderField: "Content-Type")

// Add data directly
request.httpBody = form.data()
let task = URLSession.shared.dataTask(with: request)

// OR write the data to disk for upload (better for large forms/files)
let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
form.write(to: tempURL)
let task = URLSession.shared.uploadTask(with: request, fromFile: tempURL)

task.resume()
```


