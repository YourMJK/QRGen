//
//  IntPoint.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation


public struct IntPoint: Equatable, Hashable {
	public var x: Int
	public var y: Int
}

public extension IntPoint {
	static let zero = Self(x: 0, y: 0)
}

public extension IntPoint {
	func offsetBy(dx: Int, dy: Int) -> IntPoint {
		IntPoint(x: x+dx, y: y+dy)
	}
}
