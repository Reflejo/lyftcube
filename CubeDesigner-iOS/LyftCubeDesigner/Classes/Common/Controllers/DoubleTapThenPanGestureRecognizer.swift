import UIKit
import UIKit.UIGestureRecognizerSubclass

private let kMaximumInterval = 0.5

final class DoubleTapThenSwipeGestureRecognizer: UIPanGestureRecognizer {

    private var lastTapDate = NSDate()
    private var numberOfTaps = 0

    /// Default is 1. The (exact) number of fingers that must double tap + swipe.
    var numberOfTouchesRequired = 1

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)

        let minimumDurationMet = NSDate().timeIntervalSinceDate(self.lastTapDate) < kMaximumInterval
        let touchesMet = event.allTouches()?.count == self.numberOfTouchesRequired
        self.numberOfTaps = (minimumDurationMet && touchesMet) ? self.numberOfTaps + 1 : 1
        self.lastTapDate = NSDate()
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)

        if self.numberOfTaps != 2 {
            self.state = .Failed
            return super.touchesMoved(touches, withEvent: event)
        }

        if self.state == .Possible {
            self.state = .Began

        } else if self.state != .Ended {
            self.state = .Changed
        }
    }
}
