//
//  Convenience.swift
//  Tide
//
//  Created by Aaron Rennow on 2017-09-24.
//  Copyright © 2017 Lithiumcube. All rights reserved.
//

#if os(Linux)
	import Glibc
#else
	import Darwin
#endif
import Foundation

struct STDERRStream: TextOutputStream {
	mutating func write(_ string: String) {
		string.withCString { ptr in
			withVaList([]) { valist in
				_ = vfprintf(stderr, ptr, valist)
			}
		}
	}
}

func stderrFatalError(_ message: String, exitCode: Int32 = -1, includeUsage: Bool = false) -> Never {
	var stderr = STDERRStream()
	print("Fatal error: \(message)", to: &stderr)
	if includeUsage {
		usage()
	}
	exit(exitCode)
}

func usage() {
	struct Flag {
		let label: String
		let description: String
		let required: Bool
		
		init(_ label: String, _ description: String, required: Bool = false) {
			self.label = label
			self.description = description
			self.required = required
		}
	}
	
	let options = [
		Flag("d", "Enable deletion"),
		Flag("v", "Enable verbosity"),
		Flag("n", "No-op. Implies -v and disables -d"),	
		Flag("c", "Specify the configuration file path (Required)", required: true),
		Flag("p", "Specify the path to scan (Required)", required: true)
	]
	
	let flagSummary = options.map({ $0.required ? "-\($0.label)" : "[-\($0.label)]" }).joined(separator: " ")
	
	print("Usage: \(CommandLine.arguments[0]) \(flagSummary)")
	for flag in options {
		print("   -\(flag.label)\t\(flag.description)")
	}
}

func withHeapMemory<Pointee, Result>(ofLength length: Int, _ block: (UnsafeMutablePointer<Pointee>, Int) throws -> Result) rethrows -> Result {
	let rawPtr = malloc(length)!
	defer {
		free(rawPtr)
	}
	let opaquePtr = OpaquePointer(rawPtr)
	let bufPtr = UnsafeMutablePointer<Pointee>(opaquePtr)
	
	return try block(bufPtr, length)
}

extension NSString {
	var fullRange: NSRange {
		return NSRange(location: 0, length: self.length)
	}
}

protocol CustomErrorPrintable: Error, CustomStringConvertible, RawRepresentable where Self.RawValue == String {}
extension CustomErrorPrintable {
	var description: String { return self.rawValue }
}

extension URL {
	init(fileURLWithConventionalCLIPath conventionalCLIPath: String) {
		let standardizedPath = (conventionalCLIPath as NSString).standardizingPath
		self.init(fileURLWithPath: standardizedPath)
	}
}
