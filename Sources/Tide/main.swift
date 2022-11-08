//
//  main.swift
//  Tide
//
//  Created by Aaron Rennow on 2017-09-23.
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

struct Options: CustomStringConvertible {
	enum Errors: String, CustomErrorPrintable {
		case missingRootPath = "Missing root path"
		case missingConfigPath = "Missing age config path"
	}
	
	var rootURL: URL! = nil
	var ageConfigURL: URL! = nil
	var noop: Bool = false
	var deleteOldItems: Bool = false
	var verbose: Bool = false
	
	func checkComplete() throws {
		if self.ageConfigURL == nil {
			throw Errors.missingConfigPath
		}
		
		if self.rootURL == nil {
			throw Errors.missingRootPath
		}
	}
	
	mutating func finalize() {
		if self.noop {
			self.verbose = true
			self.deleteOldItems = false
		}
	}
	
	var isComplete: Bool {
		do {
			try self.checkComplete()
			return true
		} catch {
			return false
		}
	}
	
	var description: String {
		return "<Options rootURL: '\(self.rootURL?.description ?? "No rootPath")' destroy: \(self.deleteOldItems)>"
	}
}

private var options = Options()

while case let option = getopt(CommandLine.argc, CommandLine.unsafeArgv, "hc:ndvp:x"), option != -1 {
	switch UnicodeScalar(CUnsignedChar(option)) {
	case "c":
		guard let pathString = (optarg as Optional).map({ String(cString: $0) }) else {
			stderrFatalError("Path string unreadable")
		}
		options.ageConfigURL = URL(fileURLWithConventionalCLIPath: pathString)
		
	case "d":
		options.deleteOldItems = true
		
	case "p":
		guard let pathString = (optarg as Optional).map({ String(cString: $0) }) else {
			stderrFatalError("Path string unreadable")
		}
		
		options.rootURL = URL(fileURLWithConventionalCLIPath: pathString)
		
	case "v":
		options.verbose = true
		
	case "h":
		usage()
		exit(-1)
		
	case "n":
		options.noop = true
		
	case "x":
		let example = """
{
	"yellow": "3d",
	"orange": "1w",
	"red"	: "10d",
	"delete": "2w"
}
"""
		print(example)
		exit(0)
		
	default:
		usage()
		exit(-2)
	}
}

options.finalize()

do {
	try options.checkComplete()
} catch {
	stderrFatalError(String(describing: error), includeUsage: true)
}

do {
	let ageConfig = try AgeConfig.fromURL(options.ageConfigURL)
	
	let oldMan = OldFileManager(rootURL: options.rootURL, ageConfig: ageConfig)
	try oldMan.scan(options: options)
} catch {
	stderrFatalError(String(describing: error))
}
