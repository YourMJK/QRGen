//
//  GridSVG.Element.swift
//  QRGen
//
//  Created by Max-Joseph on 28.08.22.
//

import Foundation
import IntGeometry


extension GridSVG {
	/// A grid element with an SVG path node at an (integer) grid position 
	struct Element {
		/// The SVG path node of the element
		let path: GridSVG.Path
		/// The position of the element within the grid
		let position: IntPoint
		/// All the quadrants of the grid cell which this element shares an edge with
		let connectingQuadrants: Corners
		
		var formatted: String {
			"<path d=\"\(path.formatted)\"/>"
		}
	}
}
