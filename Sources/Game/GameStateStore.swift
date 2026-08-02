import Foundation
import OSLog

actor GameStateStore {
    private let logger = Logger(subsystem: "com.example.Takibi", category: "Persistence")
    private let fileManager: FileManager
    private let fileURL: URL

    init(fileManager: FileManager = .default, fileURL: URL? = nil) {
        self.fileManager = fileManager
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.fileURL = support
                .appendingPathComponent("Takibi", isDirectory: true)
                .appendingPathComponent("game-state.json", isDirectory: false)
        }
    }

    func load(now: Date = Date()) -> GameState {
        do {
            let data = try Data(contentsOf: fileURL)
            var state = try Self.decoder.decode(GameState.self, from: data)
            state.heat = HeatEngine.decayedHeat(
                from: state.heat,
                updatedAt: state.heatUpdatedAt,
                now: now
            )
            state.burningFuels = BurningFuelEngine.active(state.burningFuels, at: now)
            state.heatUpdatedAt = now
            return state
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return .initial(at: now)
        } catch {
            logger.error("Game state load failed: \(error.localizedDescription, privacy: .public)")
            return .initial(at: now)
        }
    }

    func save(_ state: GameState) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try Self.encoder.encode(state)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
    }

    func reset() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        try fileManager.removeItem(at: fileURL)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
