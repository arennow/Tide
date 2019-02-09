//
//  AgeConfig.swift
//  Tide
//
//  Created by Aaron Rennow on 2/9/19.
//  Copyright © 2019 Lithiumcube. All rights reserved.
//

import Foundation

struct AgeConfig: Decodable {
	enum Errors: String, CustomErrorPrintable {
		case noSuchFile = "Config file not found"
	}
	
	let yellow: Age
	let orange: Age
	let red: Age
	let delete: Age
	
	struct Age: Decodable {
		enum Errors: String, CustomErrorPrintable {
			case unintelligible
			case badFormat
		}
		
		enum Unit: String {
			case day = "d"
			case week = "w"
		}
		
		let quantity: Int
		let unit: Unit
		
		var numberOfDays: Int {
			switch self.unit {
			case .day: return self.quantity
			case .week: return self.quantity * 7
			}
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			let rawSwift = try container.decode(String.self)
			let rawObjc = rawSwift as NSString
			
			let regex = try! NSRegularExpression(pattern: "^(\\d+)(\\w+)$", options: [])
			let match = regex.firstMatch(in: rawSwift, options: [], range: rawObjc.fullRange)
			
			if let match = match, match.numberOfRanges == 3 { // The first one is the whole match
				let quantityString = rawObjc.substring(with: match.range(at: 1))
				guard let quantity = Int(quantityString) else { throw Errors.unintelligible }
				self.quantity = quantity
				
				
				let unitString = rawObjc.substring(with: match.range(at: 2))
				guard let unit = Unit(rawValue: unitString) else { throw Errors.unintelligible }
				self.unit = unit
			} else {
				throw Errors.badFormat
			}
		}
	}
	
	static func from(_ url: URL) throws -> AgeConfig {
		guard let json = FileManager.default.contents(atPath: url.path) else { throw Errors.noSuchFile }
		
		let decoder = JSONDecoder()
		do {
			return try decoder.decode(self, from: json)
		} catch DecodingError.keyNotFound(let key, _) {
			throw GeneralError(message: "Missing key: \(key.stringValue)")
		} catch DecodingError.typeMismatch(_, let context) {
			let pieces = [context.codingPath.last?.stringValue, context.debugDescription]
			throw GeneralError(message: pieces.compactMap({$0}).joined(separator: ": "))
		} catch {
			throw error
		}
	}
}
