//
// SPDX-FileCopyrightText: 2024 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation

extension UInt32 {
	/// Returns the value of `self` as a hexadecimal string
	var hexString: String {
		String(self, radix: 16)
	}
}
