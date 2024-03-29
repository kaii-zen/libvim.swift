[![macOS 14](https://github.com/kaii-zen/libvim.swift/actions/workflows/swift.yml/badge.svg)](https://github.com/kaii-zen/libvim.swift/actions/workflows/swift.yml)

# libvim.swift

libvim.swift is a Swift package that provides a wrapper around [libvim](https://github.com/onivim/libvim): the core Vim editing engine implemented as a minimal C library.
Note that the current scope of this is limited to hiding away C types and pointer interaction; that is, the API itself is more or less identical to the C API provided by libvim (i.e., it is not "Swifty").

## Features (section generated by ChatGPT 🙃)

- **Integration**: Easily integrate Vim functionalities into your Swift applications.
- **Customization**: Customize Vim behaviors according to your application's needs.
- **Efficiency**: Leverage the powerful text editing capabilities of Vim within your Swift codebase.

## Installation

You can install `libvim.swift` using [Swift Package Manager](https://www.swift.org/documentation/package-manager/).

```swift
dependencies: [
    .package(url: "https://github.com/kaii-zen/libvim.swift", from: "0.0.1")
]
```

## Usage

```swift
import libvim

// Example usage
vimInit()
vimInput("i")
vimInput("H")
vimInput("e")
vimInput("l")
vimInput("l")
vimInput("o")
vimInput(",")
vimInput(" ")
vimInput("W")
vimInput("o")
vimInput("r")
vimInput("l")
vimInput("d")
vimInput("!")
vimKey("<esc>")

print(vimBufferGetLine(vimBufferGetCurrent, 1)) // -> Hello, World!
```

For more rudimentary examples have a look at the [tests](Tests/libvimTests).
For a basic UIKit example, see [Example/](Example).

## Requirements

- Swift 5.10+
- macOS 14+
- An Apple Silicon Mac

(there is probably no real reason for this, it's just the versions I started with)

## Contributing

Contributions to libvim.swift are welcomed and encouraged! To contribute:

1. Fork the repository.
2. Create your feature branch: `git checkout -b feature/new-feature`.
3. Commit your changes: `git commit -am 'Add new feature'`.
4. Push to the branch: `git push origin feature/new-feature`.
5. Submit a pull request.

## License

libvim.swift is licensed under the [MIT License](LICENSE).

## Acknowledgements

- Bram Moolenaar for authoring and maintaining the iconic Vim text editor for over 30 years; up until his passing on August 3rd 2023.
- The onivim project for creating libvim: The core Vim editing engine as a minimal C library.
- Contributors to Swift Package Manager for enabling easy dependency management in Swift projects.
