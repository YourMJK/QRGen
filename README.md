# QRGen
Swift Package library to generate stylized QR codes (SVG) from data or text.  

CLI tool for macOS and Linux: [**QRGen-cli**](https://github.com/YourMJK/QRGen-cli)

## Prerequisites

Requires Swift toolchain version 5.5 or higher.

`QRGen.GeneratorType.coreImage` and `QRGen.createRasterImage` require Apple's `CoreImage` framework, which is not available on Linux.

## Examples

``` Swift
// Example 1
let qrGen = QRGen()
let qrCode = try qrGen.generate(with: .text("http://example.org"))

let svg = qrGen.createSVG(qrCode: qrCode)
try svg.write(to: url, atomically: true, encoding: .utf8)
```
``` Swift
// Example 2
let qrGen = QRGen(
    generatorType: .nayuki,
    correctionLevel: .L,
    minVersion: 1,
    maxVersion: 3,
    optimize: true,
    strict: false,
    style: .liquidDots,
    pixelMargin: 0,
    cornerRadius: 100,
    ignoreSafeAreas: false,
    noShapeOptimization: false
)
let geoContent = QRContent.geo(coordinates: .init(latitude: 40.71872, longitude: -73.98905), altitude: nil)
let qrCode = try qrGen.generate(with: .text(geoContent))

let size = qrCode.size
for y in 0..<size {
    for x in 0..<size {
        let character = qrCode[x, y] ? "⬛️" : "⬜️"
        print(character, terminator: "")
    }
    print("")
}
```
