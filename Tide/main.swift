//
//  main.swift
//  Tide
//
//  Created by Aaron Rennow on 2017-09-23.
//  Copyright © 2017 Lithiumcube. All rights reserved.
//

import Foundation

struct Options: CustomStringConvertible {
	enum Errors: String, Error, CustomStringConvertible {
		case missingRootPath = "Missing root path"
		
		var description: String { return self.rawValue }
	}
	
	var rootURL: URL! = nil
	var setColors: Bool = false
	var deleteOldItems: Bool = false
	var verbose: Bool = false
	
	func checkComplete() throws {
		if self.rootURL == nil {
			throw Errors.missingRootPath
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

while case let option = getopt(CommandLine.argc, CommandLine.unsafeArgv, "hcdvp:"), option != -1 {
	switch UnicodeScalar(CUnsignedChar(option)) {
	case "c":
		options.setColors = true
		
	case "d":
		options.deleteOldItems = true
		
	case "p":
		guard let pathString = (optarg as Optional).map({ String(cString: $0) }) else {
			stderrFatalError("Path string unreadable")
		}
		
		options.rootURL = URL(fileURLWithPath: pathString)
		
	case "v":
		options.verbose = true
		
	case "h":
		usage()
		exit(-1)
		
	default:
		usage()
		exit(-2)
	}
}

do {
	try options.checkComplete()
} catch {
	stderrFatalError(String(describing: error), includeUsage: true)
}

do {
	let oldMan = OldFileManager(rootURL: options.rootURL)
	try oldMan.scan(options: options)
} catch {
	stderrFatalError(String(describing: error))
}
