//
//  GeneralError.swift
//  Tide
//
//  Created by Aaron Rennow on 2/9/19.
//  Copyright © 2019 Lithiumcube. All rights reserved.
//

struct GeneralError: CustomErrorPrintable {
	var rawValue: String { return message }
	
	let message: String
}
