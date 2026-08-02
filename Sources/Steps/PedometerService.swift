import CoreMotion
import Foundation

enum MotionPermissionState: String {
    case notDetermined = "未確認"
    case authorized = "許可済み"
    case denied = "拒否"
    case restricted = "制限中"
    case unavailable = "利用不可"
}

struct PedometerSample {
    let steps: Int
    let startDate: Date
    let endDate: Date
}

final class PedometerService {
    private let pedometer = CMPedometer()

    var isAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }

    var permissionState: MotionPermissionState {
        guard isAvailable else { return .unavailable }
        switch CMPedometer.authorizationStatus() {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        @unknown default: return .unavailable
        }
    }

    func query(from start: Date, to end: Date) async throws -> PedometerSample {
        guard isAvailable else { throw PedometerError.unavailable }
        return try await withCheckedThrowingContinuation { continuation in
            pedometer.queryPedometerData(from: start, to: end) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(
                        returning: PedometerSample(
                            steps: data.numberOfSteps.intValue,
                            startDate: data.startDate,
                            endDate: data.endDate
                        )
                    )
                } else {
                    continuation.resume(throwing: PedometerError.missingData)
                }
            }
        }
    }

    func startUpdates(from start: Date, handler: @escaping (Result<PedometerSample, Error>) -> Void) {
        guard isAvailable else {
            handler(.failure(PedometerError.unavailable))
            return
        }
        pedometer.startUpdates(from: start) { data, error in
            if let error {
                handler(.failure(error))
            } else if let data {
                handler(
                    .success(
                        PedometerSample(
                            steps: data.numberOfSteps.intValue,
                            startDate: data.startDate,
                            endDate: data.endDate
                        )
                    )
                )
            }
        }
    }

    func stopUpdates() {
        pedometer.stopUpdates()
    }
}

enum PedometerError: LocalizedError {
    case unavailable
    case missingData

    var errorDescription: String? {
        switch self {
        case .unavailable: "この端末では歩数を取得できません。"
        case .missingData: "歩数データを読み込めませんでした。"
        }
    }
}
