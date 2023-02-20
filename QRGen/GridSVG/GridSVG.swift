//
//  GridSVG.swift
//  QRGen
//
//  Created by Max-Joseph on 28.08.22.
//

import Foundation
import IntGeometry


class GridSVG {
	enum PixelShape {
		case square
		case circle
		case roundedCorners(_ corners: Corners, inverted: Bool)
	}
	
	struct PixelStyle {
		let shape: PixelShape
		let margin: Decimal
		let cornerRadius: Decimal
		
		init(_ shape: PixelShape, margin: Decimal = 0, cornerRadius: Decimal = 1) {
			self.shape = shape
			self.margin = min(max(margin, 0), 1)
			self.cornerRadius = min(max(cornerRadius, 0), 1)
		}
		
		static let standard = Self(.square)
	}
	
	
	let size: IntSize
	let rect: IntRect
	private var elements: [Element]
	
	init(size: IntSize) {
		self.size = size
		self.rect = IntRect(origin: .zero, size: size)
		self.elements = []
	}
	
	
	func content(combineClusters: Bool) -> String {
		var contentBuilerString =
		"""
		<?xml version="1.0" encoding="UTF-8" standalone="no"?>
		<svg width="100%" height="100%" viewBox="0 0 \(size.width) \(size.height)" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="fill-rule:evenodd;">
		
		"""
		func addLine(_ line: String) {
			contentBuilerString += "\t\(line)\n"
		}
		if combineClusters {
			for cluster in ElementCluster.findClusters(in: elements) {
				addLine(cluster.formatted)
			}
		} else {
			for element in elements {
				addLine(element.formatted)
			}
		}
		contentBuilerString += "</svg>\n"
		return contentBuilerString
	}
	
	func addPixel(at point: IntPoint, style: PixelStyle = .standard) {
		precondition(rect.contains(point), "Point lies outside of the canvas area")
		let margin = style.margin
		let marginOffset = margin / 2
		let size = 1 - margin
		let posX = Decimal(point.x) + marginOffset
		let posY = Decimal(point.y) + marginOffset
		let pos = DecimalPoint(x: posX, y: posY)
		
		func addElement(path: Path, quadrants: Corners) {
			let element = Element(path: path, position: point, connectingQuadrants: margin == 0 ? quadrants : [])
			elements.append(element)
		}
		
		switch style.shape {
			case .square:
				let path = Path.square(origin: pos, size: size)
				addElement(path: path, quadrants: .all)
			
			case .circle:
				let path = Path.roundedSquare(
					origin: pos,
					size: size,
					roundedCorners: .all,
					cornerRadius: 1
				)
				addElement(path: path, quadrants: [])
				
			case .roundedCorners(let corners, false):
				let path = Path.roundedSquare(
					origin: pos,
					size: size,
					roundedCorners: corners,
					cornerRadius: style.cornerRadius
				)
				let quadrants: Corners = style.cornerRadius == 1 ? Corners.all.subtracting(corners) : .all
				addElement(path: path, quadrants: quadrants)
				
			case .roundedCorners(let corners, true):
				Path.invertedRoundedSquare(
					origin: pos,
					size: size,
					roundedCorners: corners,
					cornerRadius: style.cornerRadius
				).forEach { (path, corners) in
					addElement(path: path, quadrants: corners)
				}
		}
	}
	
	func addPixels(isPixel: (IntPoint) -> PixelStyle?) {
		rect.forEach { point in
			if let pixelStyle = isPixel(point) {
				addPixel(at: point, style: pixelStyle)
			}
		}
	}
}
