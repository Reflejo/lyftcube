import Alamofire

/**
 API request routes, each case is a string with optional parameters built off the baseURL
 */
public enum APIRoute: URLStringConvertible {

    /// Base API URL to create requests from
    public static var baseURL = NSURL(string: "http://lyftberrypi:1337")!

    case Animations
    case Animation(id: String)
    case Upload(name: String)
    case Play(id: String)
    case Start
    case Stop

    /// The URL string of the combined URL
    public var URLString: String {

        let path: String = {
            switch self {
                case Animations:
                    return "/animation/"

                case Animation(let id):
                    return "/animation/\(id)"

                case Upload(let name):
                    return "/animation/upload/\(name)"

                case Play(let id):
                    return "/animation/play/\(id)"

                case Start:
                    return "/start"

                case Stop:
                    return "/stop"
            }
        }()

        let isAbsoluteURL = path.hasPrefix("https://") || path.hasPrefix("http://")
        let absoluteURLString = APIRoute.baseURL.URLByAppendingPathComponent(path).absoluteString ?? ""
        return isAbsoluteURL ? path : absoluteURLString
    }
}