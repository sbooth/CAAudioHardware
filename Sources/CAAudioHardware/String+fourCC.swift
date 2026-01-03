//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
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
