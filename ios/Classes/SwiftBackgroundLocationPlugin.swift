import Flutter
import UIKit
import CoreLocation

public class SwiftBackgroundLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    static var locationManager: CLLocationManager?
    static var channel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftBackgroundLocationPlugin()
        
        SwiftBackgroundLocationPlugin.channel = FlutterMethodChannel(name: "com.almoullim.background_location/methods", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: SwiftBackgroundLocationPlugin.channel!)
        SwiftBackgroundLocationPlugin.channel?.setMethodCallHandler(instance.handle)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftBackgroundLocationPlugin.locationManager = CLLocationManager()
        SwiftBackgroundLocationPlugin.locationManager?.delegate = self
        SwiftBackgroundLocationPlugin.locationManager?.requestAlwaysAuthorization()

        SwiftBackgroundLocationPlugin.locationManager?.allowsBackgroundLocationUpdates = true
        if #available(iOS 11.0, *) {
            SwiftBackgroundLocationPlugin.locationManager?.showsBackgroundLocationIndicator = true;
        }
        SwiftBackgroundLocationPlugin.locationManager?.pausesLocationUpdatesAutomatically = false

        SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: "method")

        if (call.method == "start_location_service") {
            SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: "start_location_service")
            
            let args = call.arguments as? Dictionary<String, Any>
            let distanceFilter = args?["distance_filter"] as? Double
            let activityType = args?["activity_type"] as? String
            SwiftBackgroundLocationPlugin.locationManager?.distanceFilter = distanceFilter ?? 0
            var mappedActivityType = CLActivityType.other
            if(activityType == "fitness"){
                mappedActivityType = CLActivityType.fitness
            }
            else if(activityType == "automotiveNavigation"){
                mappedActivityType = CLActivityType.automotiveNavigation
            }
            else if(activityType == "airborne"){
                if #available(iOS 12.0, *){
                    mappedActivityType = CLActivityType.airborne
                }
            }
            SwiftBackgroundLocationPlugin.locationManager?.activityType = mappedActivityType
            SwiftBackgroundLocationPlugin.locationManager?.startUpdatingLocation()
        } else if (call.method == "stop_location_service") {
            SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: "stop_location_service")
            SwiftBackgroundLocationPlugin.locationManager?.stopUpdatingLocation()
        }
        result(true)
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
           
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = [
            "speed": locations.last!.speed,
            "altitude": locations.last!.altitude,
            "latitude": locations.last!.coordinate.latitude,
            "longitude": locations.last!.coordinate.longitude,
            "accuracy": locations.last!.horizontalAccuracy,
            "bearing": locations.last!.course,
            "time": locations.last!.timestamp.timeIntervalSince1970 * 1000,
            "is_mock": false
        ] as [String : Any]

        SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: location)
    }
}
