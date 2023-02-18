//
//  BCQRCode.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation
#if canImport(AppKit)
import AppKit
#endif
import struct QRCodeGenerator.QRCode

typealias BCQRCode = QRCode

extension BCQRCode: QRCodeProtocol {
	#if canImport(AppKit)
	public var cgimage: CGImage {
		let nsimage = self.makeImage(border: 0)
		return nsimage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
	}
	#endif
}
