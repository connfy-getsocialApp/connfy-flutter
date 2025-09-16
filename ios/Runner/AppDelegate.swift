// import UIKit
// import Flutter
// import Firebase
// import FirebaseMessaging
// import SystemConfiguration.CaptiveNetwork
// import CoreLocation
// import flutter_local_notifications
// import flutter_background_service_ios

// @main
// @objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
//   var locationManager: CLLocationManager?
//   var wifiInfoResult: FlutterResult?

//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {

//     FirebaseApp.configure()

//     // Initialize secondary Firebase app (review)
//         if let path = Bundle.main.path(forResource: "GoogleService-Info-Review", ofType: "plist"),
//            let options = FirebaseOptions(contentsOfFile: path) {
//             FirebaseApp.configure(name: "connfy_getsocialApp", options: options)
//         }
//  GeneratedPluginRegistrant.register(with: self)
//     // Initialize FlutterLocalNotificationsPlugin
//     FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
//       GeneratedPluginRegistrant.register(with: registry)
//     }
//     SwiftFlutterBackgroundServicePlugin.taskIdentifier = "com.slice.connfy.locationUpdates"

//     // Request notification permissions
//     UNUserNotificationCenter.current().delegate = self
//     UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//       if granted {
//         DispatchQueue.main.async {
//           application.registerForRemoteNotifications()
//         }
//       } else {
//         if let error = error {
//           print("Error requesting notification permissions: \(error.localizedDescription)")
//         }
//       }
//     }

//     // Setup Flutter method channel
//     let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
//     let wifiInfoChannel = FlutterMethodChannel(name: "wifi_info", binaryMessenger: controller.binaryMessenger)

//     wifiInfoChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
//       if call.method == "getWifiSSID" {
//         self.getWifiSSID(result: result)
//       } else {
//         result(FlutterMethodNotImplemented)
//       }
//     }

//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }

//   func getWifiSSID(result: @escaping FlutterResult) {
//     self.wifiInfoResult = result
//     locationManager = CLLocationManager()
//     locationManager?.delegate = self
//     locationManager?.requestWhenInUseAuthorization()
//   }

//   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//     if status == .authorizedWhenInUse || status == .authorizedAlways {
//       if let interfaces = CNCopySupportedInterfaces() as? [String] {
//         for interface in interfaces {
//           if let currentNetworkInfo = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: AnyObject] {
//             wifiInfoResult?(currentNetworkInfo[kCNNetworkInfoKeySSID as String] as? String)
//             return
//           }
//         }
//       }
//       wifiInfoResult?(nil)
//     } else {
//       wifiInfoResult?(nil)
//     }
//   }

//   override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//     Messaging.messaging().apnsToken = deviceToken

//     super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
//   }

//   // Handle notification registration failures
//   override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//     print("Failed to register for remote notifications: \(error.localizedDescription)")
//     super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
//   }
// }

import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import SystemConfiguration.CaptiveNetwork
import CoreLocation
import flutter_local_notifications
import flutter_background_service_ios

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate, MessagingDelegate {
    private var locationManager: CLLocationManager?
    private var wifiInfoResult: FlutterResult?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Primary Firebase app configuration
        FirebaseApp.configure()
        
//         // Initialize secondary Firebase app if needed
        if FirebaseApp.app(name: "connfy_getsocialApp") == nil,
           let path = Bundle.main.path(forResource: "GoogleService-Info-Review", ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: path) {
            FirebaseApp.configure(name: "connfy_getsocialApp", options: options)
        }
//
        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self
        
        GeneratedPluginRegistrant.register(with: self)
        
        // Initialize FlutterLocalNotificationsPlugin
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
            GeneratedPluginRegistrant.register(with: registry)
        }
        
        // Background service setup
        SwiftFlutterBackgroundServicePlugin.taskIdentifier = "com.slice.connfy.locationUpdates"
        
        // Notification permissions
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
                DispatchQueue.main.async {
                    if granted {
                        application.registerForRemoteNotifications()
                    }
                    if let error = error {
                        print("Notification permission error: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        // Setup Flutter method channel
        if let controller = window?.rootViewController as? FlutterViewController {
            let wifiInfoChannel = FlutterMethodChannel(
                name: "wifi_info",
                binaryMessenger: controller.binaryMessenger
            )
            
            wifiInfoChannel.setMethodCallHandler { [weak self] (call, result) in
                if call.method == "getWifiSSID" {
                    self?.getWifiSSID(result: result)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - WiFi SSID Handling
    private func getWifiSSID(result: @escaping FlutterResult) {
        self.wifiInfoResult = result
        
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
        }
        
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == .authorizedAlways {
            fetchCurrentWifiSSID()
        } else {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    private func fetchCurrentWifiSSID() {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            wifiInfoResult?(nil)
            return
        }
        
        for interface in interfaces {
            guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: AnyObject],
                  let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                continue
            }
            wifiInfoResult?(ssid)
            return
        }
        
        wifiInfoResult?(nil)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            fetchCurrentWifiSSID()
        } else {
            wifiInfoResult?(nil)
        }
    }
    
    // MARK: - Remote Notifications
    override func application(_ application: UIApplication, 
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
       
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    override func application(_ application: UIApplication, 
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    // MARK: - MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token nnn: \(String(describing: fcmToken))")
        // You can send this token to your server if needed
    }
    
    // Handle silent notifications
    override func application(_ application: UIApplication,
                            didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                            fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle your notification here
        completionHandler(.newData)
    }
}

