//
//  main.swift
//  Tide
//
//  Created by Aaron Rennow on 2017-09-23.
//  Copyright © 2017 Lithiumcube. All rights reserved.
//

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

while case let option = getopt(CommandLine.argc, CommandLine.unsafeArgv, "hc:ndvp:"), option != -1 {
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
	let ageConfig = try AgeConfig.from(options.ageConfigURL)
	
	let oldMan = OldFileManager(rootURL: options.rootURL, ageConfig: ageConfig)
	try oldMan.scan(options: options)
} catch {
	stderrFatalError(String(describing: error))
}
