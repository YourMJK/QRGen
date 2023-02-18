// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "QRGen",
	products: [
		.library(name: "QRGen", targets: ["QRGen"]),
	],
	dependencies: [
		.package(url: "https://github.com/YourMJK/QRCodeGenerator", branch: "master"),
	],
	targets: [
		.target(
			name: "QRGen",
			dependencies: [
				"QRCodeGenerator",
			],
			path: "QRGen"
		),
	]
)
