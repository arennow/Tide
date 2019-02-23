//
//  Convenience.swift
//  Tide
//
//  Created by Aaron Rennow on 2017-09-24.
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
		Flag("n", "Take no actual actions. Implies -v and disables -d"),
		Flag("x", "Print an example configuration to stdout"),
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

protocol CustomErrorPrintable: Error, CustomStringConvertible {
	var rawValue: String { get }
}
extension CustomErrorPrintable {
	var description: String { return self.rawValue }
}

extension URL {
	init(fileURLWithConventionalCLIPath conventionalCLIPath: String) {
		let standardizedPath = (conventionalCLIPath as NSString).standardizingPath
		self.init(fileURLWithPath: standardizedPath)
	}
}
