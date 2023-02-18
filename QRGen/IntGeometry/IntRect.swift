//
//  IntRect.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation


public struct IntRect: Equatable {
	public var origin: IntPoint
	public var size: IntSize
	public init(origin: IntPoint, size: IntSize) {
		self.origin = origin
		self.size = size
	}
}

public extension IntRect {
	static let zero = Self(origin: .zero, size: .zero)
	
	init(x: Int, y: Int, width: Int, height: Int) {
		self.origin = IntPoint(x: x, y: y)
		self.size = IntSize(width: width, height: height)
	}
	
	init(point1: IntPoint, point2: IntPoint) {
		let minX = Swift.min(point1.x, point2.x)
		let minY = Swift.min(point1.y, point2.y)
		let maxX = Swift.max(point1.x, point2.x)
		let maxY = Swift.max(point1.y, point2.y)
		self.origin = IntPoint(x: minX, y: minY)
		self.size = IntSize(width: maxX-minX, height: maxY-minY)
	}
}

public extension IntRect {
	var minX: Int {
		origin.x
	}
	var minY: Int {
		origin.y
	}
	var minPoint: IntPoint {
		origin
	}
	var maxX: Int {
		origin.x + size.width
	}
	var maxY: Int {
		origin.y + size.height
	}
	var maxPoint: IntPoint {
		IntPoint(x: maxX, y: maxY)
	}
	
	var width: Int {
		size.width
	}
	var height: Int {
		size.height
	}
	var isEmpty: Bool {
		size.isEmpty
	}
}

public extension IntRect {
	func offsetBy(dx: Int, dy: Int) -> IntRect {
		IntRect(origin: origin.offsetBy(dx: dx, dy: dy), size: size)
	}
	func insetBy(dx: Int, dy: Int) -> IntRect {
		IntRect(x: origin.x-dx, y: origin.y-dy, width: size.width-dx*2, height: size.height-dy*2)
	}
	
	func union(_ r2: IntRect) -> IntRect {
		let minX = Swift.min(self.minX, r2.minX)
		let minY = Swift.min(self.minY, r2.minY)
		let maxX = Swift.max(self.maxX, r2.maxX)
		let maxY = Swift.max(self.maxY, r2.maxY)
		return IntRect(origin: IntPoint(x: minX, y: minY), size: IntSize(width: maxX-minX, height: maxY-minY))
	}
	func intersection(_ r2: IntRect) -> IntRect {
		let minX = Swift.max(self.minX, r2.minX)
		let minY = Swift.max(self.minY, r2.minY)
		let maxX = Swift.min(self.maxX, r2.maxX)
		let maxY = Swift.min(self.maxY, r2.maxY)
		let width = maxX-minX
		let height = maxY-minY
		if width < 0 || height < 0 { return .zero }
		return IntRect(origin: IntPoint(x: minX, y: minY), size: IntSize(width: width, height: height))
	}
	
	func contains(_ point: IntPoint) -> Bool {
		minX <= point.x && minY <= point.y && point.x < maxX && point.y < maxY
	}
	func contains(_ rect2: IntRect) -> Bool {
		union(rect2) == self
	}
	func intersects(_ rect2: IntRect) -> Bool {
		!intersection(rect2).isEmpty
	}
}

extension IntRect: RandomAccessCollection {
	public typealias Element = IntPoint
	public typealias Index = Int
	
	public var startIndex: Int {
		0
	}
	public var endIndex: Int {
		width * height
	}
	
	public subscript(index: Int) -> IntPoint {
		get {
			precondition(startIndex <= index && index < endIndex, "Index out of range")
			let (j, i) = index.quotientAndRemainder(dividingBy: width)
			return IntPoint(x: origin.x + i, y: origin.y + j)
		}
	}	
}

public extension IntRect {
	struct Iterator: IteratorProtocol {
		public typealias Element = IntRect.Element
		
		private let rangeX: Range<Int>
		private let rangeY: Range<Int>
		private var x: Int
		private var y: Int
		
		init(_ rect: IntRect) {
			self.rangeX = (rect.minX..<rect.maxX)
			self.rangeY = (rect.minY..<rect.maxY)
			self.x = rangeX.lowerBound
			self.y = rangeY.lowerBound
		}
		
		public mutating func next() -> Element? {
			if x >= rangeX.upperBound {
				x = rangeX.lowerBound
				y += 1
			}
			guard x < rangeX.upperBound, y < rangeY.upperBound else { return nil }
			let point = IntPoint(x: x, y: y)
			x += 1
			return point
		}
	}
	
	func makeIterator() -> Iterator {
		Iterator(self)
	}
}
