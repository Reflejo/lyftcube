import UIKit

/**
Executes the given clousure after a delay of "delay" seconds.

- parameter delay:   The delay in seconds.
- parameter closure: A closure that is going to be executed after the delay.
*/
public func executeAfter(delay: Double, queue: dispatch_queue_t? = nil, closure: () -> Void) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, queue ?? dispatch_get_main_queue(), closure)
}
