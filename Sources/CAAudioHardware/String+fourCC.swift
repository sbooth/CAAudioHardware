//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation

extension String {
	/// Returns the first four characters of `self` as a four character code value.
	var fourCC: UInt32 {
		prefix(4).unicodeScalars.reduce(0) {
			($0 << 8) | ($1.value & 0xff)
		}
	}
}
