import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class NowPlayingController {
    private(set) var track: MediaTrack?
    private(set) var isActive = false
    private(set) var lastError: String?

    private let sendCommand: @convention(c) (Int, AnyObject?) -> Void
    private var process: Process?
    private var pipeHandler: JSONLinesPipeHandler?
    private var streamTask: Task<Void, Never>?
    private var started = false

    init?() {
        guard
            let bundle = CFBundleCreate(
                kCFAllocatorDefault,
                NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
            ),
            let sendPtr = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteSendCommand" as CFString)
        else { return nil }
        sendCommand = unsafeBitCast(sendPtr, to: (@convention(c) (Int, AnyObject?) -> Void).self)
    }

    deinit {}

    func start() {
        guard !started else { return }
        started = true
        Task { await startStream() }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        if let process, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        process = nil
        started = false
        Task {
            await pipeHandler?.close()
            pipeHandler = nil
        }
    }

    func playPause() { sendCommand(2, nil) }
    func nextTrack() { sendCommand(4, nil) }
    func previousTrack() { sendCommand(5, nil) }

    private func startStream() async {
        let process = Process()
        guard
            let scriptURL = Bundle.main.url(forResource: "mediaremote-adapter", withExtension: "pl"),
            let frameworks = Bundle.main.privateFrameworksPath
        else {
            lastError = "Missing mediaremote-adapter resources"
            return
        }

        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = [scriptURL.path, frameworks + "/MediaRemoteAdapter.framework", "stream"]

        let handler = JSONLinesPipeHandler()
        process.standardOutput = await handler.getPipe()
        self.process = process
        self.pipeHandler = handler

        do {
            try process.run()
            isActive = true
            streamTask = Task { [weak self] in await self?.consumeStream() }
        } catch {
            lastError = error.localizedDescription
            isActive = false
        }
    }

    private func consumeStream() async {
        guard let pipeHandler else { return }
        await pipeHandler.readJSONLines(as: NowPlayingUpdate.self) { [weak self] update in
            await self?.apply(update)
        }
    }

    private func apply(_ update: NowPlayingUpdate) {
        let payload = update.payload
        let diff = update.diff ?? false
        let bundleID =
            payload.parentApplicationBundleIdentifier
            ?? payload.bundleIdentifier
            ?? (diff ? track?.appBundleID : nil)
            ?? ""

        let title = payload.title ?? (diff ? track?.title : nil) ?? ""
        let artist = payload.artist ?? (diff ? track?.artist : nil) ?? ""
        let duration = payload.duration ?? (diff ? track?.duration : nil) ?? 0
        let position = payload.elapsedTime ?? (diff ? track?.position : nil) ?? 0
        let playing = payload.playing ?? (diff ? track?.isPlaying : nil) ?? false

        var artworkData = track?.artworkData
        if let artworkDataString = payload.artworkData {
            artworkData = Data(
                base64Encoded: artworkDataString.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } else if !diff {
            artworkData = nil
        }

        if title.isEmpty && artist.isEmpty && !playing {
            track = nil
            return
        }

        track = MediaTrack(
            title: title,
            artist: artist,
            artworkURL: nil,
            artworkData: artworkData,
            isPlaying: playing,
            position: position,
            duration: duration,
            appBundleID: bundleID
        )
    }
}

struct NowPlayingUpdate: Codable {
    let payload: NowPlayingPayload
    let diff: Bool?
}

struct NowPlayingPayload: Codable {
    let title: String?
    let artist: String?
    let album: String?
    let duration: Double?
    let elapsedTime: Double?
    let artworkData: String?
    let playing: Bool?
    let parentApplicationBundleIdentifier: String?
    let bundleIdentifier: String?
}

actor JSONLinesPipeHandler {
    private let pipe = Pipe()
    private var buffer = ""

    func getPipe() -> Pipe { pipe }

    func readJSONLines<T: Decodable>(
        as type: T.Type,
        onLine: @escaping @Sendable (T) async -> Void
    ) async {
        let handle = pipe.fileHandleForReading
        do {
            while true {
                let data = try await readData(from: handle)
                if data.isEmpty { break }
                guard let chunk = String(data: data, encoding: .utf8) else { continue }
                buffer.append(chunk)
                while let range = buffer.range(of: "\n") {
                    let line = String(buffer[..<range.lowerBound])
                    buffer = String(buffer[range.upperBound...])
                    guard !line.isEmpty, let lineData = line.data(using: .utf8) else { continue }
                    if let decoded = try? JSONDecoder().decode(T.self, from: lineData) {
                        await onLine(decoded)
                    }
                }
            }
        } catch {}
    }

    private func readData(from handle: FileHandle) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            handle.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                fileHandle.readabilityHandler = nil
                continuation.resume(returning: data)
            }
        }
    }

    func close() {
        pipe.fileHandleForReading.readabilityHandler = nil
        try? pipe.fileHandleForReading.close()
        try? pipe.fileHandleForWriting.close()
    }
}
