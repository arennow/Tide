//
//  AgeConfig.swift
//  Tide
//
//  Created by Aaron Rennow on 2/9/19.
//

/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org/>
*/

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
			let string = try container.decode(String.self)
			
			guard let match = try /^(\d+)(\w+)$/.firstMatch(in: string) else { throw Errors.badFormat }
			
			guard let quantity = Int(match.1) else { throw Errors.unintelligible }
			self.quantity = quantity
			
			guard let unit = Unit(rawValue: String(match.2)) else { throw Errors.unintelligible }
			self.unit = unit
		}
	}
	
	static func fromURL(_ url: URL) throws -> AgeConfig {
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
