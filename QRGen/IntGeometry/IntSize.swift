//
//  IntSize.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation


public struct IntSize: Equatable {
	public var width: Int {
		willSet { precondition(newValue >= 0, "Width of IntSize must be positive") }
	}
	public var height: Int {
		willSet { precondition(newValue >= 0, "Height of IntSize must be positive") }
	}
	
	public init(width: Int, height: Int) {
		precondition(width >= 0 && height >= 0, "Width and height of IntSize must be positive")
		self.width = width
		self.height = height
	}
}

public extension IntSize {
	static let zero = Self(width: 0, height: 0)
}

public extension IntSize {
	var isEmpty: Bool {
		width == 0 || height == 0
	}
}
