//
//  URL+Resources.swift
//  Tide
//
//  Created by Aaron Rennow on 2017-09-23.
//  Copyright © 2017 Lithiumcube. All rights reserved.
//

import Foundation

extension URL {
	func resource<T>(for key: URLResourceKey) throws -> T? {
		var val: AnyObject?
		try (self as NSURL).getResourceValue(&val, forKey: key)
		
		return val as? T
	}
}
