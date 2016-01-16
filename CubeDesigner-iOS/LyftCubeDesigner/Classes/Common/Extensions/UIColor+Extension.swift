import UIKit

extension UIColor {

    /**
    Creates an instance of UIColor based on an RGB value.

    - parameter rgbValue: The Integer representation of the RGB value: Example: 0xFF0000
    - parameter alpha:    The desired alpha for the color

    - returns: UIColor instance colored based on given rgb
    */
    public convenience init(rgbValue: Int, alpha: CGFloat = 1.0) {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    /**
    Creates an instance of UIColor by offseting its HSB values.

    - parameter brightnessDelta: This delta it's going to be added to the current brightness. It can be
                                 negative to make the color darker or positive to make it brighter. From 0 to
                                 1.
    - parameter saturationDelta: This delta it's going to be added to the current saturation. From 0 to 1.

    - returns: the newly created color with the new brightness value.
    */
    public func colorByAddingBrightness(brightnessDelta: CGFloat,
        andSaturationFactor saturationFactor: CGFloat? = nil, brightnessCap: CGFloat = 1.0) -> UIColor
    {
        var hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0, alpha: CGFloat = 0.0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        let newSaturation = saturationFactor.map { $0 * saturation } ?? saturation
        let newBrightness = min(max(brightness + brightnessDelta, 0.0), brightnessCap)
        return UIColor(hue: hue, saturation: newSaturation, brightness: newBrightness, alpha: alpha)
    }
}
