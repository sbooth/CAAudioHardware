//
// Copyright © 2020-2024 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation

extension String {
	/// Returns `self.prefix(4)` interpreted as a four character code
	var fourCC: UInt32 {
		var fourcc: UInt32 = 0
		for uc in prefix(4).unicodeScalars {
			fourcc = (fourcc << 8) + (uc.value & 0xff)
		}
		return fourcc
	}
}
