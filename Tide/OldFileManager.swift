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
			
			private var distinguishingByte: UInt8? {
				switch self {
				case .none:		return nil
				case .yellow:	return 0x0a
				case .orange:	return 0x0e
				case .red:		return 0x0c
				}
			}
			
			func data() -> Data? {
				var sourceData = Array<UInt8>(repeating: 0, count: 32)
				
				guard let ninthByte = self.distinguishingByte else {
					return nil
				}
				
				sourceData[9] = ninthByte
				
				let data = Data(sourceData)
				precondition(data.count == 32)
				return data
			}
			
			init?(data: Data?) {
				guard let data = data else {
					return nil
				}
				
				let ninthByte = data.withUnsafeBytes { (ptr) -> UInt8 in
					return ptr[9]
				}
				
				switch ninthByte {
				case Color.yellow.distinguishingByte!: self = .yellow
				case Color.orange.distinguishingByte!: self = .orange
				case Color.red.distinguishingByte!: self = .red
				default: return nil
				}
			}
		}
		
		case keep(Color)
		case delete
	}
	
	private func fate(for date: Date) -> Fate {
		func daysAgo(_ days: Int) -> Date {
			let oneDay: TimeInterval = 60*60*24
			return Date(timeIntervalSinceNow: -oneDay * TimeInterval(days))
		}
		
		switch date {
		case daysAgo(self.ageConfig.yellow.numberOfDays)...:
			return .keep(.none)
			
		case daysAgo(self.ageConfig.orange.numberOfDays)...:
			return .keep(.yellow)
			
		case daysAgo(self.ageConfig.red.numberOfDays)...:
			return .keep(.orange)
			
		case daysAgo(self.ageConfig.delete.numberOfDays)...:
			return .keep(.red)
			
		default:
			return .delete
		}
	}
	
	let rootURL: URL
	let ageConfig: AgeConfig
	
	init(rootURL: URL, ageConfig: AgeConfig) {
		self.rootURL = rootURL
		self.ageConfig = ageConfig
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
			
			let fate = self.fate(for: modificationDate)
			
			switch fate {
			case .keep(let color):
				let oldColor: Fate.Color = {
					let dataSize = getxattr(url.path, XATTR_FINDERINFO_NAME, nil, 0, 0, 0)
					if dataSize > 0 {
						return withHeapMemory(ofLength: dataSize) { (ptr: UnsafeMutablePointer<UInt8>, length) in
							let res = getxattr(url.path, XATTR_FINDERINFO_NAME, ptr, length, 0, 0)
							
							if res != -1 {
								let data = Data(bytesNoCopy: ptr, count: length, deallocator: .none)
								
								return Fate.Color(data: data) ?? .none
							} else {
								return .none
							}
						}
					} else {
						return .none
					}
				}()
				
				guard color != oldColor else { continue }
				
				func apply() {
					if let data = color.data() {
						data.withUnsafeBytes { bytes in
							_ = setxattr(url.path, XATTR_FINDERINFO_NAME, bytes, data.count, 0, 0)
						}
					} else {
						removexattr(url.path, XATTR_FINDERINFO_NAME, 0)
					}
				}
				
				switch (options.verbose, options.deleteOldItems) {
				case (true, true):
					print("\(relativePath): marking \(color)")
					fallthrough
					
				case (false, true):
					apply()
					
				case (true, false):
					print("\(relativePath): would mark \(color)")
					
				case (false, false):
					break
				}
				
			case .delete:
				switch (options.verbose, options.deleteOldItems) {
				case (true, true):
					print("\(relativePath): deleting")
					fallthrough
					
				case (false, true):
					try fm.removeItem(at: url)
					
				case (true, false):
					print("\(relativePath): would delete")
					
				case (false, false):
					break
				}
			}
		}
	}
}
