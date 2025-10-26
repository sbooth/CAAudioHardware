//
// Copyright © 2020-2025 Stephen F. Booth <me@sbooth.org>
// Part of https://github.com/sbooth/CAAudioHardware
// MIT license
//

import Foundation

extension UInt32 {
	/// Returns the value of `self` as a four character code string.
	var fourCC: String {
		String(decoding: [
			UInt8(self >> 24),
			UInt8((self >> 16) & 0xff),
			UInt8((self >> 8) & 0xff),
			UInt8(self & 0xff),
		], as: UTF8.self)
	}
}
