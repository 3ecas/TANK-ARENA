import AVFoundation

/// Plays the synthesised sound effects through a small pool of AVAudioPlayerNodes.
/// Fails silently (no sound) if the audio engine cannot start.
@MainActor
final class SoundEngine {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [SoundID: AVAudioPCMBuffer] = [:]
    private var lastPlayed: [SoundID: TimeInterval] = [:]
    private var nextPlayer = 0
    private var isRunning = false

    init() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }
        for _ in 0..<14 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        for id in SoundID.allCases {
            buffers[id] = SoundSynth.make(id, format: format)
        }
        engine.mainMixerNode.outputVolume = 0.55
        do {
            try engine.start()
            isRunning = true
            for player in players { player.play() }
        } catch {
            isRunning = false
        }
    }

    func play(_ id: SoundID, volume: Float = 1) {
        guard isRunning, volume > 0.02, let buffer = buffers[id], !players.isEmpty else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if let last = lastPlayed[id], now - last < id.minInterval { return }
        lastPlayed[id] = now
        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.volume = min(1, volume)
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    func stop() {
        engine.stop()
        isRunning = false
    }
}
