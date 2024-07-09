//
// Copyright © 2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation

extension UInt32 {
	/// Returns the value of `self` as a hexadecimal string
	public var hexString: String {
		String(self, radix: 16)
	}
}
