//
//  QRContent.swift
//  QRGen
//
//  Created by Max-Joseph on 15.01.23.
//

import Foundation

public struct QRContent {
	public enum WifiEncryption: String, CaseIterable {
		case wep
		case wpa
		//case wpa2eap(eapMethod: String?, anonymousIdentity: String?, identity: String?, phase2Method: String?)
	}
	public struct GeoCoordinates {
		public let latitude: Double
		public let longitude: Double
		public init(latitude: Double, longitude: Double) {
			self.latitude = latitude
			self.longitude = longitude
		}
	}
	
	
	public static func wifi(ssid: String, password: String?, encryption: WifiEncryption?, hidden: Bool = false) -> String {
		var content = "WIFI:"
		func addParameter(_ parameter: String, value: String) {
			var escapedValue = value
			for special in ["\\", ";", ",", "\"", ":"] {
				escapedValue = escapedValue.replacingOccurrences(of: special, with: "\\"+special)
			}
			content += "\(parameter):\(escapedValue);"
		}
		
		addParameter("S", value: ssid)
		switch (encryption, password) {
				
			case (.wep, .some(let password)):
				addParameter("T", value: "WEP")
				addParameter("P", value: password)
			case (.wpa, .some(let password)):
				addParameter("T", value: "WPA")
				addParameter("P", value: password)
//			case (.wpa2eap(let eapMethod, let anonymousIdentity, let identity, let phase2Method), let password):
//				addParameter("T", value: "WPA2-EAP")
//				for (parameter, value) in [("P", password), ("E", eapMethod), ("A", anonymousIdentity), ("I", identity), ("PH2", value: phase2Method)] {
//					guard let value else { continue }
//					addParameter(parameter, value: value)
//				}
			case (.none, _): fallthrough
			case (_, .none):
				//addParameter("T", value: "nopass")
				break
		}
		if hidden {
			addParameter("H", value: "true")
		}
		content += ";"
		
		return content
	}
	
	
	public static func event(name: String?, start: Date, end: Date?, location: String?, coordinates: GeoCoordinates?) -> String {
		var lines = [String]()
		func addParameter(_ parameter: String, _ value: String) {
			lines.append("\(parameter):\(value)")
		}
		func addParameter(_ parameter: String, date: Date) {
			let formatter = ISO8601DateFormatter()
			formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime, .withTimeZone]
			addParameter(parameter, formatter.string(from: date))
		}
		
		addParameter("BEGIN", "VEVENT")
		if let name {
			addParameter("SUMMARY", name)
		}
		addParameter("DTSTART", date: start)
		if let end {
			addParameter("DTEND", date: end)
		}
		if let location {
			addParameter("LOCATION", location)
		}
		if let coordinates {
			addParameter("GEO", String(format: "%.5f;%.5f", coordinates.latitude, coordinates.longitude))
		}
		addParameter("END", "VEVENT")
		
		lines.append("")
		let content = lines.joined(separator: "\r\n")
		
		return content
	}
	
	public static func geo(coordinates: GeoCoordinates, altitude: Int?) -> String {
		var content = String(format: "geo:%.5f,%.5f", coordinates.latitude, coordinates.longitude)
		if let altitude {
			content += ",\(altitude)"
		}
		return content
	}
}
