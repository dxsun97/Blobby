import AppKit

final class SpringRef {
    private(set) var position: CGPoint = .zero
    private(set) var velocity: CGPoint = .zero
    private(set) var isIdle: Bool = true
    private var lastStepTime: TimeInterval = 0

    func reset(to position: CGPoint) {
        self.position = position
        velocity = .zero
        isIdle = true
        lastStepTime = CACurrentMediaTime()
    }

    func step(constants: SpringMode.Constants, target: CGPoint) {
        let now = CACurrentMediaTime()
        guard now - lastStepTime > 0.001 else { return }
        lastStepTime = now

        let dx = target.x - position.x
        let dy = target.y - position.y

        velocity.x = (velocity.x + dx * CGFloat(constants.acceleration)) * CGFloat(constants.friction)
        velocity.y = (velocity.y + dy * CGFloat(constants.acceleration)) * CGFloat(constants.friction)

        position.x += velocity.x
        position.y += velocity.y

        let speed = velocity.x * velocity.x + velocity.y * velocity.y
        isIdle = speed < 0.01 && dx * dx + dy * dy < 0.01
    }
}
