//
//  PixelSVG.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation

class BinaryPixelSVG {
	
	enum PixelStyle {
		case square
		case circle
	}
	
	
	let width: Int
	let height: Int
	private var contentBuilerString: String
	private let floatFormatter: NumberFormatter
	
	init(width: Int, height: Int) {
		self.width = width
		self.height = height
		self.contentBuilerString =
		"""
		<?xml version="1.0" encoding="UTF-8" standalone="no"?>
		<svg width="100%" height="100%" viewBox="0 0 \(width) \(height)" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
		
		"""
		self.floatFormatter = {
			let formatter = NumberFormatter()
			formatter.locale = Locale(identifier: "en_US_POSIX")
			formatter.maximumFractionDigits = 2
			formatter.minimumIntegerDigits = 1
			return formatter
		}()
	}
	
	
	private func format(_ number: Double) -> String {
		floatFormatter.string(from: number as NSNumber)!
	}
	
	
	var content: String {
		contentBuilerString + "</svg>\n"
	}
	
	func addPixel(x: Int, y: Int, style: PixelStyle = .square, margin: Double = 0) {
		let margin = min(max(margin, 0), 1)
		let scale = 1 - margin
		switch style {
			case .square:
				let size = format(scale)
				let xPos = format(Double(x) + margin/2)
				let yPos = format(Double(y) + margin/2)
				contentBuilerString += "\t<rect x=\"\(xPos)\" y=\"\(yPos)\" width=\"\(size)\" height=\"\(size)\"/>\n"
			case .circle:
				let radius = format(scale * 0.5)
				contentBuilerString += "\t<circle cx=\"\(x).5\" cy=\"\(y).5\" r=\"\(radius)\"/>\n"
		}
	}
	
	func addPixels(isPixel: (_ x: Int, _ y: Int) -> (style: PixelStyle, margin: Double)?) {
		for y in 0..<height {
			for x in 0..<width {
				if let pixelFormat = isPixel(x, y) {
					addPixel(x: x, y: y, style: pixelFormat.style, margin: pixelFormat.margin)
				}
			}
		}
	}
}


extension BinaryPixelSVG {
	struct Point: Comparable {
		let x: Int
		let y: Int
		
		/// NOTE: Not a strict total order (like `Comparable` actually implies) but a strict partial order (no totality)
		static func < (lhs: Self, rhs: Self) -> Bool {
			(lhs <= rhs) && lhs != rhs
		}
		static func > (lhs: Point, rhs: Point) -> Bool { rhs < lhs }
		
		/// NOTE: Non-strict partial order (no totality)
		static func <= (lhs: Point, rhs: Point) -> Bool {
			lhs.x <= rhs.x && lhs.y <= rhs.y
		}
		static func >= (lhs: Point, rhs: Point) -> Bool { rhs <= lhs }
	}
	
	func addPixel(at point: Point, style: PixelStyle = .square, margin: Double = 0) {
		addPixel(x: point.x, y: point.y, style: style, margin: margin)
	}
	
	func addPixels(isPixel: (Point) -> (style: PixelStyle, margin: Double)?) {
		addPixels { x, y in
			isPixel(Point(x: x, y: y))
		}
	}
}
