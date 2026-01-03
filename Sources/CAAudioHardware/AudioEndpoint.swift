//
// SPDX-FileCopyrightText: 2020 Stephen F. Booth <contact@sbooth.dev>
// SPDX-License-Identifier: MIT
//
// Part of https://github.com/sbooth/CAAudioHardware
//

import Foundation

/// A HAL audio endpoint
/// - remark: This class correponds to objects with base class `kAudioEndPointClassID`
public class AudioEndpoint: AudioDevice, @unchecked Sendable {
}
