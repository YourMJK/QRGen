//
//  QRCodeProtocol.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation
#if canImport(AppKit)
import CoreGraphics
#endif


public protocol QRCodeProtocol {
	/// The version number of this QR Code, which is between 1 and 40 (inclusive). This determines the size of this barcode.
	var version: Int { get }
	
	/// The width and height of this QR Code, measured in modules, between 21 and 177 (inclusive). This is equal to version * 4 + 17.
	var size: Int { get }
	
	#if canImport(AppKit)
	/// The QR code drawn as a bitmap image where each module is exactly one black or white pixel (without a border).
	var cgimage: CGImage { get }
	#endif
	
	/// The modules of this QR Code (false = white, true = black).
	subscript(_ x: Int, _ y: Int) -> Bool { get }
}

public extension QRCodeProtocol {
	/// The version number of this QR Code, which is between 1 and 40 (inclusive). This determines the size of this barcode.
	var version: Int {
		Self.version(from: size)
	}
	
	/// The modules of this QR Code (false = white, true = black).
	subscript(_ point: IntPoint) -> Bool { 
		self[point.x, point.y]
	}
}

public extension QRCodeProtocol {
	func safeAreas() -> [IntRect] {
		Self.safeAreas(for: size)
	}
	
	static func safeAreas(for size: Int) -> [IntRect] {
		let version = version(from: size)
		
		var safeAreas = [IntRect]()
		func addSafeArea(x: Int, y: Int, width: Int, height: Int) {
			safeAreas.append(IntRect(x: x, y: y, width: width, height: height))
		}
		
		// Position markers
		let positionMarkerSize = 7
		func addPositionMarker(x: Int, y: Int) {
			addSafeArea(x: x, y: y, width: positionMarkerSize, height: positionMarkerSize)
		}
		addPositionMarker(x: 0, y: 0)
		addPositionMarker(x: 0, y: size-positionMarkerSize)
		addPositionMarker(x: size-positionMarkerSize, y: 0)
		
		// Alignment markers
		if version > 1 {
			let alignmentMarkerCount = (version / 7) + 1
			let alignmentMarkerOffset = positionMarkerSize - 1
			let alignmentMarkerDistance = (size - alignmentMarkerOffset*2) - 1
			let alignmentMarkerSpacing: Int = {
				// Equal spacing rounded first to nearest integer, then to next even integer
				let roundedEqualSpacing = lround(Double(alignmentMarkerDistance) / Double(alignmentMarkerCount))
				return roundedEqualSpacing + (roundedEqualSpacing & 0b1)
			}()
			let alignmentMarkerPositions = ([0] + (1...alignmentMarkerCount).map {
				alignmentMarkerDistance - alignmentMarkerSpacing * (alignmentMarkerCount - $0)
			}).map { $0 + alignmentMarkerOffset }
			
			let alignmentMarkerSize = 5
			func addAlignmentMarker(cx: Int, cy: Int) {
				addSafeArea(x: cx-alignmentMarkerSize/2, y: cy-alignmentMarkerSize/2, width: alignmentMarkerSize, height: alignmentMarkerSize)
			}
			for j in 0...alignmentMarkerCount {
				for i in 0...alignmentMarkerCount {
					switch (i, j) {
						case (0, 0): continue
						case (0, alignmentMarkerCount): continue
						case (alignmentMarkerCount, 0): continue
						default: addAlignmentMarker(cx: alignmentMarkerPositions[i], cy: alignmentMarkerPositions[j])
					}
				}
			}
		}
		
		return safeAreas
	}
	
	private static func version(from size: Int) -> Int {
		let (version, remainder) = (size - 17).quotientAndRemainder(dividingBy: 4)
		precondition(remainder == 0 && version >= 1, "\(size) is not a valid QR code version size")
		return version
	}
}
