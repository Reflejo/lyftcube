import ImageIO
import MobileCoreServices
import UIKit

struct GIF {
    private var pixelsByFrame: [[UInt8]]?

    /// An array of delays by frame.
    var delayByFrame: [NSTimeInterval]

    /// The path where the binary was loaded from (if any)
    var path: String?

    /// GIF file size in bytes
    let size: UInt64?

    /// Animation's frame count
    let frameCount: Int

    /// The width of the image
    let width: Int

    /// The height of the image
    let height: Int

    init(width: Int, height: Int, frameCount: Int, size: UInt64 = 0) {
        self.width = width
        self.height = height
        self.frameCount = frameCount
        self.size = size

        let pixels = [UInt8](count: height * width * 3, repeatedValue: 0)
        self.pixelsByFrame = [[UInt8]](count: frameCount, repeatedValue: pixels)
        self.delayByFrame = [NSTimeInterval](count: frameCount, repeatedValue: 0.02)
    }

    init?(path: String) {
        self.path = path
        guard let (width, height, count) = GIF.parseMetadaa(path) else {
            return nil
        }

        let attributes: NSDictionary? = try? NSFileManager.defaultManager().attributesOfItemAtPath(path)
        self.size = attributes?.fileSize()
        self.width = width
        self.height = height
        self.frameCount = count
        self.delayByFrame = [NSTimeInterval](count: frameCount, repeatedValue: 0.02)
    }

    /**
     Parse the entire file (all pixel information). Note that this is an expensive operation.
     */
    mutating func parse() {
        guard let path = self.path, data = CGDataProviderCreateWithFilename(path),
            imageSource = CGImageSourceCreateWithDataProvider(data, nil) else
        {
            return
        }

        self.pixelsByFrame = []
        for index in 0 ..< CGImageSourceGetCount(imageSource) {
            guard let frameImage = CGImageSourceCreateImageAtIndex(imageSource, index, nil),
                pixels = CGDataProviderCopyData(CGImageGetDataProvider(frameImage)),
                properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) else
            {
                continue
            }

            let bytes = CFDataGetBytePtr(pixels)
            var frameBytes = [UInt8]()
            for index in 0.stride(to: CFDataGetLength(pixels), by: 4) {
                frameBytes.append(bytes[index])
                frameBytes.append(bytes[index + 1])
                frameBytes.append(bytes[index + 2])
            }
            self.pixelsByFrame?.append(frameBytes)

            let GIFProperties = (properties as NSDictionary)[kCGImagePropertyGIFDictionary as NSString]
            let delay = (GIFProperties as? NSDictionary)?[kCGImagePropertyGIFUnclampedDelayTime as NSString]
                as? NSTimeInterval
            self.delayByFrame[index] = delay ?? 0.02
        }
    }

    /**
     Sets a color on the given animation's frame and located at a given position.

     - parameter color:   The UIColor to set
     - parameter atFrame: The animation's frame index
     - parameter x:       The pixel's x position
     - parameter y:       The pixel's y position
     */
    mutating func setColor(color: UIColor, atFrame frame: Int, x: Int, y: Int) {
        var red: CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0, alpha: CGFloat = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let start = 3 * (x + y * self.width)
        self.pixelsByFrame?[frame][start] = UInt8(round(red * 255.0))
        self.pixelsByFrame?[frame][start + 1] = UInt8(round(green * 255.0))
        self.pixelsByFrame?[frame][start + 2] = UInt8(round(blue * 255.0))
    }

    /**
     Color located on the given animation's frame and at a given position.

     - parameter frame: The animation's frame index
     - parameter x:     The pixel's x position
     - parameter y:     The pixel's y position

     - returns: A UIColor created from the RGB value at the given position
     */
    func colorAtFrame(frame: Int, x: Int, y: Int) -> (color: UIColor, isDark: Bool)? {
        let start = 3 * (x + y * self.width)
        guard let red = self.pixelsByFrame?[frame][start], green = self.pixelsByFrame?[frame][start + 1],
            blue = self.pixelsByFrame?[frame][start + 2] else
        {
            return nil
        }

        let isDark = red < 30 && green < 30 && blue < 30
        let color = UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255, alpha: 1.0)
        return (color, isDark)
    }

    /**
     Saves the pixels information into a BMP 16-bits file.

     - parameter path: The destination (full) path where the file will be saved.
     */
    func save(path: String) {
        let URL = NSURL(fileURLWithPath: path)
        let properties: NSDictionary = [
            kCGImagePropertyGIFDictionary as NSString: [
                kCGImagePropertyGIFHasGlobalColorMap as NSString: false,
            ]
        ]

        guard let byFrame = self.pixelsByFrame,
            destination = CGImageDestinationCreateWithURL(URL, kUTTypeGIF, self.frameCount, properties) else
        {
            return
        }

        CGImageDestinationSetProperties(destination, properties)

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.None.rawValue).union(.ByteOrderDefault)
        for frame in 0 ..< self.frameCount {
            let delay = self.delayByFrame[frame]
            let durationInfo: NSDictionary = [
                kCGImagePropertyGIFDictionary as NSString: [kCGImagePropertyGIFDelayTime as NSString: delay]
            ]

            let data = CGDataProviderCreateWithData(nil, byFrame[frame], byFrame[frame].count, nil)
            let imageReference = CGImageCreate(self.width, self.height, 8, 8 * 3, self.width * 3,
                CGColorSpaceCreateDeviceRGB(), bitmapInfo, data, nil, false, .RenderingIntentDefault)

            if let imageReference = imageReference {
                CGImageDestinationAddImage(destination, imageReference, durationInfo)
            }
        }
        CGImageDestinationFinalize(destination)
    }

    // MARK: - Private helpers

    static func parseMetadaa(path: String) -> (width: Int, height: Int, frames: Int)? {
        let imageURL = NSURL(fileURLWithPath: path)
        guard let imageSource = CGImageSourceCreateWithURL(imageURL, nil) else {
            return nil
        }

        let result = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil).map { $0 as NSDictionary }
        if let width = result?[kCGImagePropertyPixelWidth as NSString] as? Int,
            height = result?[kCGImagePropertyPixelHeight as NSString] as? Int
        {
            let count = CGImageSourceGetCount(imageSource)
            return (width, height, count)
        }
        
        return nil
    }
}
