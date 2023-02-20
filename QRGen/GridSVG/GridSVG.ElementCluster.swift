//
//  GridSVG.ElementCluster.swift
//  QRGen
//
//  Created by Max-Joseph on 28.08.22.
//

import Foundation
import IntGeometry


extension GridSVG {
	/// A cluster of connected `Element`s
	struct ElementCluster {
		/// A mutable collection of elements with O(1) access to elements by their grid position
		class GridDictionary {
			let keys: [IntPoint: [Int]]
			var dict: [Int: Element]
			
			init (from elements: [Element]) {
				var keys = [IntPoint: [Int]]()
				var dict = [Int: Element]()
				for (index, element) in elements.enumerated() {
					dict[index] = element
					keys[element.position, default: []].append(index)
				}
				self.keys = keys
				self.dict = dict
			}
			
			func forEachElement(at position: IntPoint, _ closure: (Int, Element) throws -> Void) rethrows {
				try keys[position]?.forEach { key in
					guard let element = dict[key] else { return }
					try closure(key, element)
				}
			}
		}
		
		
		let elements: [Element]
		
		init (from elements: inout GridDictionary, containing element: Element) {
			var clusterElements = [Element]()
			
			func addNeighbors(of element: Element) {
				// Add element to cluster
				clusterElements.append(element)
				// Find mutual neighbors
				var neighborKeys = Set<Int>()
				for quandrant in element.connectingQuadrants {
					// Check neighboring positions of quadrant
					for direction in quandrant.neighbors {
						let offset = direction.offset
						let position = element.position.offsetBy(dx: offset.x, dy: offset.y)
						// Check all elements at neighboring position
						elements.forEachElement(at: position) { neighborKey, neighborElement in
							// Check if neighborhood is mutual
							let mirroredQuadrant = quandrant.mirror(in: direction)
							guard neighborElement.connectingQuadrants.contains(mirroredQuadrant) else { return }
							neighborKeys.insert(neighborKey)
						}
					}
				}
				// Remove neighbors from search pool
				let neighborElements = neighborKeys.sorted().map { elements.dict.removeValue(forKey: $0)! }
				// Call recursively for each neighbor
				for neighborElement in neighborElements {
					addNeighbors(of: neighborElement)
				}
			}
			addNeighbors(of: element)
			
			self.elements = clusterElements
		}
		
		static func findClusters(in elements: [Element]) -> [ElementCluster] {
			var clusters = [ElementCluster]()
			var elementsDict = GridDictionary(from: elements)
			
			// Create clusters until search pool is empty, each time starting at first most element
			while let key = elementsDict.dict.keys.min() {
				let element = elementsDict.dict.removeValue(forKey: key)!
				clusters.append(ElementCluster(from: &elementsDict, containing: element))
			}
			
			return clusters
		}
	}
}


extension GridSVG.ElementCluster {
	private struct CurveEndpoints: Equatable, Hashable {
		let endpoints: Set<DecimalPoint>
		init (curve: GridSVG.Curve) {
			self.endpoints = [curve.start, curve.end]
		}
	}
	private struct Index: Comparable, Equatable, Hashable {
		let curve: Int
		let element: Int
		static func < (lhs: Self, rhs: Self) -> Bool {
			lhs.element == rhs.element ? lhs.curve < rhs.curve : lhs.element < rhs.element
		}
	}
	
	/// The SVG paths making up the combined shape of the cluster's elements
	func combinedPaths() -> [GridSVG.Path] {
		guard elements.count > 1 else {
			return elements.map(\.path)
		}
		
		var boundaryCurvesIndices = [CurveEndpoints: Index]()
		var boundaryCurvesEndpoints = [DecimalPoint: [CurveEndpoints]]()
		var boundaryPaths = [GridSVG.Path]()
		
		// Find curves on the boundary of the cluser by removing curves with the same start and end point 
		for (elementIndex, element) in elements.enumerated() {
			for (curveIndex, curve) in element.path.curves.enumerated() {
				let endpoints = CurveEndpoints(curve: curve)
				guard boundaryCurvesIndices.removeValue(forKey: endpoints) == nil else { continue }
				boundaryCurvesIndices[endpoints] = Index(curve: curveIndex, element: elementIndex)
			}
		}
		
		// Map each endpoint to an even number of possible keys of boundaryCurvesIndices
		for (curveEndpoints, _) in boundaryCurvesIndices.sorted(by: { $0.value < $1.value }) {
			for endpoint in curveEndpoints.endpoints {
				boundaryCurvesEndpoints[endpoint, default: []].append(curveEndpoints) 
			}
		}
		precondition(boundaryCurvesEndpoints.values.map(\.count).allSatisfy { $0 % 2 == 0 }, "Degree of boundary path nodes is not even")
		
		// Construct a path for each connected loop of boundary curves, each time starting at the first most curve
		while let startCurveEndpoints = boundaryCurvesIndices.min(by: { $0.value < $1.value })?.key {
			let startIndex = boundaryCurvesIndices.removeValue(forKey: startCurveEndpoints)!
			
			var curves = [GridSVG.Curve]()
			var nextIndex: Index? = startIndex
			var nextStartPoint = elements[startIndex.element].path.curves[startIndex.curve].end
			while let index = nextIndex { 
				var curve = elements[index.element].path.curves[index.curve]
				// Reverse curve if necessary
				if curve.start != nextStartPoint {
					curve = curve.reverse()
					precondition(curve.start == nextStartPoint, "Gap in boundary path")
				}
				curves.append(curve)
				
				// Find the next curve's index
				nextStartPoint = curve.end
				nextIndex = {
					for curveEndpoints in boundaryCurvesEndpoints[nextStartPoint]! {
						if let index = boundaryCurvesIndices.removeValue(forKey: curveEndpoints) {
							return index
						}
					}
					return nil
				}()
			}
			precondition(curves.last?.end == curves.first?.start, "Boundary path is not closed")
			
			// Optimize strings of colinear straight lines into single straight lines
			var optimizedCurves = [GridSVG.Curve]()
			var lineStart: DecimalPoint?
			var lineAxis: (x: Bool, y: Bool)?
			func curveProperties(_ curve: GridSVG.Curve) -> (axis: (x: Bool, y: Bool), isLineOnAxis: Bool, isSameAxis: Bool) {
				let vector = (x: curve.end.x - curve.start.x, y: curve.end.y - curve.start.y)
				let axis = (x: vector.y == 0, y: vector.x == 0)
				let isLineOnAxis = curve is GridSVG.Line && (axis.x || axis.y)
				let isSameAxis = lineAxis.map { $0 == axis } ?? true
				return (axis, isLineOnAxis, isSameAxis)
			}
			for curve in curves {
				let properties = curveProperties(curve)
				if !properties.isLineOnAxis || !properties.isSameAxis, let start = lineStart {
					// String of colinear lines is over: add new combining line
					optimizedCurves.append(GridSVG.Line(start: start, end: curve.start))
					lineStart = nil
					lineAxis = nil
				}
				guard properties.isLineOnAxis else {
					// Curve is not a straight line: add unchanged
					optimizedCurves.append(curve)
					continue
				}
				if lineStart == nil {
					// Curve is first straight line of string
					lineStart = curve.start
					lineAxis = properties.axis
				}
			}
			if let lineStart = lineStart {
				// Last curve was straight line
				let firstCurve = optimizedCurves.first!
				let properties = curveProperties(firstCurve)
				if properties.isLineOnAxis && properties.isSameAxis {
					// String is colinear with first string: replace both with new combining line 
					optimizedCurves[0] = GridSVG.Line(start: lineStart, end: firstCurve.end)
				} else {
					// String of colinear lines is over: add new combining line
					optimizedCurves.append(GridSVG.Line(start: lineStart, end: firstCurve.start))
				}
			}
			
			// Create new boundary path from optimized curves
			boundaryPaths.append(GridSVG.Path(curves: optimizedCurves))
		}
		
		return boundaryPaths
	}
	
	var formatted: String {
		"<path d=\"\(combinedPaths().map(\.formatted).joined())\"/>"
	}
}
