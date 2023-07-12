// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "QRGen",
	products: [
		.library(name: "QRGen", targets: ["QRGen"]),
	],
	dependencies: [
		.package(url: "https://github.com/YourMJK/QRCodeGenerator", from: "1.1.0"),
		.package(url: "https://github.com/YourMJK/IntGeometry", from: "1.0.0"),
	],
	targets: [
		.target(
			name: "QRGen",
			dependencies: [
				"QRCodeGenerator",
				"IntGeometry",
			],
			path: "QRGen"
		),
	]
)
