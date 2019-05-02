# MultipartFormData

[![Build Status](https://travis-ci.org/WCByrne/MultipartFormData.svg?branch=master)](https://travis-ci.org/WCByrne/MultipartFormData)

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

### Output

The form data can either be returned as data or written to disc for use in an upload task. Writing directly to disc is preferred as it avoids bringing all the data into memory at one time.

```swift
let data = form.data()

// Create a temp file url to write to
let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
form.write(to: tempURL)

// Then to create the upload task
var request = URLRequest(url: URL(string: "api.myservice.com/users")!)
request.addValue(form.contentType, forHTTPHeaderField: "Content-Type")
let task = URLSession.shared.uploadTask(with: request, fromFile: tempURL)
task.resume()
```


