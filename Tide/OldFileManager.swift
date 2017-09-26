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
		enum Color {
			case none
			case yellow
			case orange
			case red
			
			func data() -> Data? {
				var sourceData = Array<UInt8>(repeating: 0, count: 32)
				
				let ninthByte: UInt8
				
				switch self {
				case .none:		return nil
				case .yellow:	ninthByte = 0x0a
				case .orange:	ninthByte = 0x0e
				case .red:		ninthByte = 0x0c
				}
				
				sourceData[9] = ninthByte
				
				let data = Data(sourceData)
				precondition(data.count == 32)
				return data
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
				
				if let data = color.data() {
					data.withUnsafeBytes { bytes in
						_ = setxattr(url.path, XATTR_FINDERINFO_NAME, bytes, data.count, 0, 0)
					}
				} else {
					removexattr(url.path, XATTR_FINDERINFO_NAME, 0)
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
