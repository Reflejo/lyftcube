import UIKit

/**
 The animation type

 - Programatic: The animation is performed using an algorithm (this is used for random-based animations or
                dynamic animations such as text scrolling)
 - Fixed:       The animation was loaded from a BMP file
 */
enum AnimationType: String {
    case Programatic = "programatic", Fixed = "fixed"
}

struct LEDCubeFrame {
    var duration: NSTimeInterval = 0.02

    lazy var colors: [[[UIColor?]]] = {
        let x = [UIColor?](count: 8, repeatedValue: nil)
        let y = [[UIColor?]](count: 8, repeatedValue: x)
        return [[[UIColor?]]](count: 8, repeatedValue: y)
    }()
}

struct Animation {

    /// The animation's path (if local)
    var path: String?

    /// The animation's name (use a string that describes the animation).
    var name: String?

    /// The type of the animation (see `AnimationEntryType` for more information)
    var type: AnimationType

    /// When the animation comes from the server this is the unique id
    var id: String?

    /// The animation's frames including every LED color
    var frames = [LEDCubeFrame]()

    /// The estimated file size of the GIF file.
    var fileSize: UInt64?

    init(name: String? = nil, type: AnimationType = .Fixed, fileSize: UInt64? = nil, id: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.fileSize = fileSize
    }

    /**
     Create animation struct from a bitmap file containing all animation's frames.

     - parameter bitmap:  The Bitmap representation of file containing the animation frames and colors.
     - parameter onParse: When given, the GIF will be fully parsed (all pixels) and the closure will be 
                          called when the process is finished.

     - returns: the newly created `Animation` (only including the metadata, use the closure otherwise)
     */
    static func fromGIF(var gif: GIF, onParse: (Animation -> Void)? = nil) -> Animation {
        assert(gif.width == 8 && gif.height == 64, "GIF size is invalid")

        let lastPathComponent = gif.path?.componentsSeparatedByString("/").last ?? "Unknown"
        let name = (lastPathComponent as NSString).stringByDeletingPathExtension
        var animation = Animation(name: name, type: .Fixed)
        animation.fileSize = gif.size
        animation.path = gif.path
        if let onParse = onParse {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                gif.parse()
                animation.setColorsFromGIF(gif)
                dispatch_async(dispatch_get_main_queue()) { onParse(animation) }
            }
        }

        return animation
    }

    /**
     Writes bitmap data into the file system on the given path. This method is quite expensive and will run
     in a background thread. The completion is guaranteed to be called in the main thread.

     - parameter path:       The path where the destination bitmap will be located
     - parameter queue:      The queue to run the process (default: DISPATCH_QUEUE_PRIORITY_DEFAULT)
     - parameter completion: A closure that will be called when the saving is finished
     */
    func saveTo(path: String, queue: dispatch_queue_t? = nil, completion: NSURL -> Void) {
        let queue = queue ?? dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)!
        dispatch_async(queue) {
            let filePath = self.saveTo(path)
            dispatch_async(dispatch_get_main_queue()) {
                completion(filePath)
            }
        }
    }

    // MARK: - Private helpers

    private func saveTo(path: String) -> NSURL {
        var gif = GIF(width: 8, height: 64, frameCount: self.frames.count)
        for (frameNumber, var frame) in self.frames.enumerate() {
            gif.delayByFrame[frameNumber] = frame.duration
            for (x, layer) in frame.colors.enumerate() {
                for (cubeY, line) in layer.enumerate() {
                    for (cubeZ, pixel) in line.enumerate() {
                        let y = cubeZ + (cubeY * 8)
                        gif.setColor(pixel ?? .blackColor(), atFrame: frameNumber, x: x, y: y)
                    }
                }
            }
        }

        let animationName = self.name ?? "Unsaved"
        let filePath = "\(path)/\(animationName).gif"
        gif.save(filePath)
        return NSURL(fileURLWithPath: filePath)
    }

    mutating private func setColorsFromGIF(gif: GIF) {
        self.frames = []
        for frame in 0 ..< gif.frameCount {
            var cubeFrame = LEDCubeFrame()
            cubeFrame.duration = gif.delayByFrame[frame]
            for y in 0 ..< 64 {
                for x in 0 ..< 8 {
                    let cubeY = y / 8
                    let cubeZ = y % 8

                    let tuple = gif.colorAtFrame(frame, x: x, y: y)
                    cubeFrame.colors[x][cubeY][cubeZ] = tuple?.isDark == true ? nil : tuple?.color
                }
            }
            self.frames.append(cubeFrame)
        }
    }
}
