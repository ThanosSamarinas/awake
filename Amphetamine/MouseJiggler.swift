import Foundation
import CoreGraphics
import Combine

final class MouseJiggler {
    private var timer: AnyCancellable?
    private let interval: TimeInterval = 240

    func start() {
        stop()
        jiggle()
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.jiggle()
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func jiggle() {
        guard let event = CGEvent(source: nil) else { return }
        let pos = event.location
        CGWarpMouseCursorPosition(CGPoint(x: pos.x + 1, y: pos.y))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            CGWarpMouseCursorPosition(pos)
        }
    }

    deinit {
        stop()
    }
}
