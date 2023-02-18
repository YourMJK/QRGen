//
//  QRGenCode.swift
//  QRGen
//
//  Created by Max-Joseph on 11.08.22.
//

import Foundation
#if canImport(AppKit)
import CoreImage
#endif

struct QRGenCode {
	let generatorType: GeneratorType
	let correctionLevel: CorrectionLevel
	let minVersion: Int
	let maxVersion: Int
	let optimize: Bool
	let strict: Bool
	let style: Style
	let pixelMargin: UInt
	let cornerRadius: UInt
	let ignoreSafeAreas: Bool
	let writePNG: Bool
	let noShapeOptimization: Bool
	
	enum Input {
		case data(Data)
		case text(String)
	}
	enum GeneratorType: String, CaseIterable {
		#if canImport(CoreImage)
		case coreImage
		#endif
		case nayuki
	}
	enum Style: String, CaseIterable {
		case standard
		case dots
		case holes
		case liquidDots
		case liquidHoles
	}
	
	
	/// Generate QR code from input
	func generate(with input: Input) throws -> QRCodeProtocol {
		func generate<T: QRCodeGeneratorProtocol>(using generatorType: T.Type) throws -> QRCodeProtocol {
			let generator = T(correctionLevel: correctionLevel, minVersion: minVersion, maxVersion: maxVersion)
			return try {
				switch input {
					case .data(let data):
						return try generator.generate(for: data)
					case .text(let string):
						return try generator.generate(for: string, optimize: optimize, strictEncoding: strict)
				}
			}()
		}
		switch generatorType {
			#if canImport(CoreImage)
			case .coreImage: return try generate(using: CIQRCodeGenerator.self)
			#endif
			case .nayuki:    return try generate(using: BCQRCodeGenerator.self)
		}
	}
	
	
	#if canImport(AppKit)
	func createRasterImage<T: QRCodeProtocol>(qrCode: T, outputFile: URL) -> CIImage {
		CIImage(cgImage: qrCode.cgimage)
	}
	#endif
	
	
	func createSVG<T: QRCodeProtocol>(qrCode: T, outputFile: URL) -> String {
		let border = 1
		let size = qrCode.size
		let sizeWithBorder = size + border*2
		let svg = GridSVG(size: IntSize(width: sizeWithBorder, height: sizeWithBorder))
		
		// Create safe areas where not to apply styling
		let safeAreas = qrCode.safeAreas()
		func isInSafeArea(_ point: IntPoint) -> Bool {
			safeAreas.contains { $0.contains(point) }
		}
		
		// Add pixels
		let rect = IntRect(origin: .zero, size: IntSize(width: size, height: size))
		let pixelMargin = Decimal(pixelMargin)/100
		let cornerRadius = Decimal(cornerRadius)/100
		func addPixel(at point: IntPoint, shape pixelShape: GridSVG.PixelShape, isPixel: Bool = true) {
			let pixelStyle: GridSVG.PixelStyle
			if ignoreSafeAreas || !isInSafeArea(point) {
				pixelStyle = GridSVG.PixelStyle(pixelShape, margin: pixelMargin, cornerRadius: cornerRadius)
			} else if isPixel {
				switch pixelShape {
					case .square: pixelStyle = .standard
					default: pixelStyle = GridSVG.PixelStyle(.roundedCorners([], inverted: false), margin: 0, cornerRadius: cornerRadius)
				}
			} else {
				return
			}
			let pointInImageCoordinates = point.offsetBy(dx: border, dy: border)
			svg.addPixel(at: pointInImageCoordinates, style: pixelStyle)
		}
		var bridgeLiquidDiagonally = false
		
		switch style {
			// Static pixel shape
			case .standard, .dots:
				let pixelShape: GridSVG.PixelShape
				switch (style, cornerRadius) {
					case (.standard, _): pixelShape = .square
					case (.dots,   0): pixelShape = .square
					case (.dots, 100): pixelShape = .circle
					case (.dots,   _): pixelShape = .roundedCorners(.all, inverted: false)
					default: preconditionFailure("Invalid pixel shape for static style")
				}
				rect.forEach { point in
					let isPixel = qrCode[point]
					guard isPixel else { return }
					addPixel(at: point, shape: pixelShape)
				}
			
			// Dynamic pixel shape
			case .holes:
				rect.forEach { point in
					let isPixel = qrCode[point]
					let pixelShape: GridSVG.PixelShape
					if isPixel {
						pixelShape = .roundedCorners([], inverted: false)
					} else if cornerRadius != 0 {
						pixelShape = .roundedCorners(.all, inverted: true)
					} else {
						return
					}
					addPixel(at: point, shape: pixelShape, isPixel: isPixel)
				}
			
			case .liquidHoles:
				bridgeLiquidDiagonally = true
				fallthrough
			case .liquidDots:
				rect.forEach { point in
					let isPixel = qrCode[point]
					var corners: GridSVG.Corners = []
					func isNeighborPixel(dx: Int, dy: Int) -> Bool {
						let neighborPoint = point.offsetBy(dx: dx, dy: dy)
						return rect.contains(neighborPoint) && qrCode[neighborPoint]
					}
					for corner in GridSVG.Corners.all {
						let (dx, dy) = corner.offset
						let shouldRound = 
							isNeighborPixel(dx: dx, dy: 0) != isPixel &&
							isNeighborPixel(dx: 0, dy: dy) != isPixel &&
							(isNeighborPixel(dx: dx, dy: dy) != isPixel || isPixel != bridgeLiquidDiagonally)
						if shouldRound {
							corners.insert(corner)
						}
					}
					let pixelShape: GridSVG.PixelShape = .roundedCorners(corners, inverted: !isPixel)
					addPixel(at: point, shape: pixelShape, isPixel: isPixel)
				}
		}
		
		return svg.content(combineClusters: !noShapeOptimization)
	}
}
