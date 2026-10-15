import AVFoundation

/// Generates every sound effect procedurally (noise bursts, tones, sweeps). No audio files needed.
enum SoundSynth {
    static func make(_ id: SoundID, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let rate = Float(format.sampleRate)
        let samples: [Float]
        switch id {
        case .rifle: samples = noiseBurst(rate: rate, duration: 0.09, decay: 45, lowpass: 0.35, thump: 0.5)
        case .lmg: samples = noiseBurst(rate: rate, duration: 0.08, decay: 50, lowpass: 0.3, thump: 0.6)
        case .shotgun: samples = noiseBurst(rate: rate, duration: 0.22, decay: 18, lowpass: 0.25, thump: 0.9)
        case .sniper: samples = noiseBurst(rate: rate, duration: 0.3, decay: 14, lowpass: 0.5, thump: 0.7)
        case .rocket: samples = noiseBurst(rate: rate, duration: 0.35, decay: 8, lowpass: 0.12, thump: 0.2)
        case .cannon: samples = noiseBurst(rate: rate, duration: 0.45, decay: 9, lowpass: 0.08, thump: 1.0)
        case .explosionSmall: samples = noiseBurst(rate: rate, duration: 0.6, decay: 6, lowpass: 0.06, thump: 1.0)
        case .explosionBig: samples = noiseBurst(rate: rate, duration: 1.2, decay: 3.5, lowpass: 0.04, thump: 1.0)
        case .emp: samples = sweep(rate: rate, duration: 0.6, from: 900, to: 120, volume: 0.5)
        case .click: samples = tone(rate: rate, frequencies: [1200], noteLength: 0.03, volume: 0.3)
        case .levelUp: samples = tone(rate: rate, frequencies: [523, 659, 784, 1047], noteLength: 0.09, volume: 0.35)
        case .purchase: samples = tone(rate: rate, frequencies: [880, 1320], noteLength: 0.06, volume: 0.3)
        case .error: samples = tone(rate: rate, frequencies: [180, 140], noteLength: 0.08, volume: 0.35, square: true)
        case .alert: samples = tone(rate: rate, frequencies: [880, 660, 880, 660], noteLength: 0.1, volume: 0.25, square: true)
        case .capture: samples = sweep(rate: rate, duration: 0.5, from: 300, to: 900, volume: 0.35)
        case .heal: samples = sweep(rate: rate, duration: 0.35, from: 500, to: 1100, volume: 0.2)
        }
        return buffer(from: samples, format: format)
    }

    private static func buffer(from samples: [Float], format: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData?[0] else { return nil }
        for (i, value) in samples.enumerated() { channel[i] = value }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        return buffer
    }

    /// Filtered white noise with an exponential envelope plus a low "thump" sine.
    private static func noiseBurst(rate: Float, duration: Float, decay: Float, lowpass: Float,
                                   thump: Float) -> [Float] {
        let count = Int(rate * duration)
        var result = [Float](repeating: 0, count: count)
        var filtered: Float = 0
        for i in 0..<count {
            let t = Float(i) / rate
            let envelope = expf(-t * decay)
            let noise = Float.random(in: -1...1)
            filtered += (noise - filtered) * lowpass
            let low = sinf(2 * .pi * 70 * t) * expf(-t * decay * 1.5) * thump
            result[i] = (filtered * 0.8 + low * 0.6) * envelope * 0.7
        }
        return result
    }

    /// A sequence of short notes.
    private static func tone(rate: Float, frequencies: [Float], noteLength: Float, volume: Float,
                             square: Bool = false) -> [Float] {
        let perNote = Int(rate * noteLength)
        var result: [Float] = []
        result.reserveCapacity(perNote * frequencies.count)
        for frequency in frequencies {
            for i in 0..<perNote {
                let t = Float(i) / rate
                var wave = sinf(2 * .pi * frequency * t)
                if square { wave = wave >= 0 ? 0.6 : -0.6 }
                let envelope = min(1, Float(i) / 200) * min(1, Float(perNote - i) / 400)
                result.append(wave * envelope * volume)
            }
        }
        return result
    }

    /// Frequency sweep with a fade out.
    private static func sweep(rate: Float, duration: Float, from: Float, to: Float, volume: Float) -> [Float] {
        let count = Int(rate * duration)
        var result = [Float](repeating: 0, count: count)
        var phase: Float = 0
        for i in 0..<count {
            let progress = Float(i) / Float(count)
            let frequency = from + (to - from) * progress
            phase += 2 * .pi * frequency / rate
            result[i] = sinf(phase) * (1 - progress) * volume * min(1, Float(i) / 300)
        }
        return result
    }
}
