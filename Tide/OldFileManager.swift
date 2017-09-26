//
//  OldFileManager.swift
//  Tide
//
//  Created by Aaron Rennow on 2017-09-23.
//  Copyright © 2017 Lithiumcube. All rights reserved.
//

import Foundation

class OldFileManager {
	fileprivate enum Fate {
		enum Color: String {
			case none	= ""
			case yellow	= "<00 00 00 00 00 00 00 00 00 0A 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00>"
			case orange	= "<00 00 00 00 00 00 00 00 00 0E 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00>"
			case red	= "<00 00 00 00 00 00 00 00 00 0C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00>"
			
			func data() -> Data {
				switch self {
				case .none:
					return Data()
					
				default:
					let data = self.rawValue.propertyList() as! NSData as Data
					precondition(data.count == 32)
					return data
				}
			}
		}
		
		case keep(Color)
		case delete
	}
	
	private static func fate(for date: Date) -> Fate {
		let oneWeek: TimeInterval = 60*60*24*7
		
		if date > Date(timeIntervalSinceNow: -oneWeek) {
			return .keep(.none)
		} else if date > Date(timeIntervalSinceNow: -2*oneWeek) {
			return .keep(.yellow)
		} else if date > Date(timeIntervalSinceNow: -3*oneWeek) {
			return .keep(.orange)
		} else if date > Date(timeIntervalSinceNow: -4*oneWeek) {
			return .keep(.red)
		} else {
			return .delete
		}
	}
	
	let rootURL: URL
	
	init(rootURL: URL) {
		self.rootURL = rootURL
	}
	
	func scan(options: Options) throws {
		let fm = FileManager.default
		
		let rootComponentsCount = options.rootURL.pathComponents.count
		
		let conts = try fm.contentsOfDirectory(at: self.rootURL,
		                                       includingPropertiesForKeys: [.contentModificationDateKey],
		                                       options: .skipsHiddenFiles)
		
		for url in conts {
			guard let modificationDate: Date = try url.resource(for: .contentModificationDateKey) else {
				print("Couldn't get modification date for \(url)")
				continue
			}
			
			let relativePath = url.pathComponents[rootComponentsCount...].joined()
			
			let fate = OldFileManager.fate(for: modificationDate)
			
			switch fate {
			case .keep(let color):
//				let oldValue: Fate.Color?
//				do {
//					let dataSize = getxattr(url.path, XATTR_FINDERINFO_NAME, nil, 0, 0, 0)
//					if dataSize > 0 {
//						withHeapMemory(ofLength: dataSize) { (ptr, length) in
//							let res = getxattr(url.path, XATTR_FINDERINFO_NAME, ptr, length, 0, 0)
//
//							if res != -1 {
//
//							} else {
//								oldValue = nil
//							}
//						}
//					} else {
//						oldValue = nil
//					}
//				}
				
				if options.verbosity >= 2 {
					if options.simulate {
						print("\(relativePath): would mark \(color)")
					} else {
						print("\(relativePath): marking \(color)")
					}
				}
				
				let data = color.data()
				data.withUnsafeBytes { bytes in
					_ = setxattr(url.path, XATTR_FINDERINFO_NAME, bytes, data.count, 0, 0)
				}
				
			case .delete:
				if options.deleteOldItems {
					if options.simulate {
						if options.verbosity >= 1 {
							print("\(relativePath): would delete")
						}
					} else {
						if options.verbosity >= 1 {
							print("\(relativePath): deleting")
						}
						
						try fm.removeItem(at: url)
					}
				} else {
					if options.verbosity >= 1 {
						print("\(relativePath): could delete")
					}
				}
			}
		}
	}
}
