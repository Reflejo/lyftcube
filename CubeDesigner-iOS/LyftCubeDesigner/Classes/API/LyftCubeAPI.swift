import Alamofire
import Foundation

struct LyftCubeAPI {

    private static let manager = Manager()

    /**
     Starts LEDCube, note that this is a nop if cube is already started.
     */
    static func start() {
        self.manager.request(.POST, APIRoute.Start)
    }

    /**
     Shut downs LEDCube, note that this is a nop if cube is already stopped.
     */
    static func stop() {
        self.manager.request(.POST, APIRoute.Stop)
    }

    /**
     Removes animation identified by the given animation ID

     - parameter animationID: The unique identifier of the animation to remove
     */
    static func removeAnimation(animationID: String) {
        self.manager.request(.DELETE, APIRoute.Animation(id: animationID))
    }

    /**
     Upload animation GIF file to the cube. Note that this will also play the animation once uploaded.

     - parameter animation:  The animation to upload & play
     - parameter completion: A completion closure that will be called either on success or failure.
     */
    static func uploadAnimation(animation: Animation, completion: (id: String?) -> Void) {
        guard let animationName = animation.name where !animationName.isEmpty else {
            return completion(id: nil)
        }

        let directory = NSURL(fileURLWithPath: NSTemporaryDirectory())
        animation.saveTo(directory.path!) { filePath in
            self.manager.upload(.POST, APIRoute.Upload(name: animationName), file: filePath)
                .response { request, _, data, error in
                    guard error == nil, let data = data,
                        id = String(data: data, encoding: NSUTF8StringEncoding) else
                    {
                        return completion(id: nil)
                    }

                    completion(id: id)
                }
        }
    }

    /**
     Plays given animation on the cube, if it exists it'd just play it, if it's a new animation we'll first
     upload the file and then play it.

     - parameter animation: The animation to play (or upload)
     */
    static func playAnimation(animation: Animation, completion: (id: String?) -> Void) {
        guard let animationID = animation.id else {
            return self.uploadAnimation(animation, completion: completion)
        }

        self.manager.request(.POST, APIRoute.Play(id: animationID))
            .response { _, _, _, error in
                completion(id: error == nil ? animationID : nil)
            }
    }

    /**
     Downloads the animation data for the given animation's ID.

     - parameter id:         The ID of the animation to download
     - parameter completion: A completion closure that will be called either on success or failure.
     */
    static func animationByID(id: String, completion: Animation? -> Void) {
        let directory = NSURL(fileURLWithPath: NSTemporaryDirectory())
        let URL = directory.URLByAppendingPathComponent("\(id).gif")

        self.manager.download(.GET, APIRoute.Animation(id: id), destination: { _ in URL })
            .response { _, response, _, _ in
                guard response?.statusCode == 200, let path = URL.path, let gif = GIF(path: path) else {
                    return completion(nil)
                }

                Animation.fromGIF(gif) { (var animation) in
                    animation.id = id
                    completion(animation)
                }
        }
    }

    /**
     Gets the list of all available animations from the cube.

     - parameter completion: A completion closure that will be called either on success or failure.
     */
    static func listAnimations(completion: [Animation] -> Void) {
        self.manager.request(.GET, APIRoute.Animations)
            .response { _, response, data, _ in
                guard response?.statusCode == 200, let data = data else {
                    return completion([])
                }

                let response = String(data: data, encoding: NSUTF8StringEncoding)
                let entries = response?.componentsSeparatedByString("\n") ?? []
                let animations = entries.flatMap { entry -> Animation? in
                    let parts = entry.componentsSeparatedByString(",")
                    if parts.count != 3 {
                        return nil
                    }

                    let size = UInt64(parts[2])
                    let type: AnimationType = size > 0 ? .Fixed : .Programatic
                    return Animation(name: parts[0], type: type, fileSize: size, id: parts[1])
                }
                completion(animations)
            }
    }
}