import SVProgressHUD
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func applicationDidBecomeActive(application: UIApplication) {
        SVProgressHUD.setDefaultStyle(.Dark)
    }
}
