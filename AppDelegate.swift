//
//  AppDelegate.swift
//  NearbyAPIDemo
//
//  Created by Patrick on 24/12/19.
//  Copyright © 2019 Patrick. All rights reserved.
//

import UIKit


let kMyAPIKey = "AIzaSyDj5sRGvao_y-tyaJG9pP0DOiWUvxAT9dw"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    //let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    /**
     * @property
     * This class lets you check the permission state of Nearby for the app on the current device.  If
     * the user has not opted into Nearby, publications and subscriptions will not function.
     */
    var nearbyPermission: GNSPermission!
    
    /**
     * @property
     * The message manager lets you create publications and subscriptions.  They are valid only as long
     * as the manager exists.
     */
    var messageMgr: GNSMessageManager?
    var publication: GNSPublication?
    var subscription: GNSSubscription?
    var navController: UINavigationController!
    var messageViewController: MessageViewController!
    
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        messageViewController = MessageViewController()
        navController = UINavigationController(rootViewController: messageViewController)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        // Set up the message view navigation buttons.
        nearbyPermission = GNSPermission(changedHandler: {[unowned self] granted in
            self.messageViewController.leftBarButton =
                UIBarButtonItem(title: String(format: "%@ Nearby", granted ? "Deny" : "Allow"),
                                style: .plain, target: self, action: #selector(AppDelegate.toggleNearbyPermission))
        })
        setupStartStopButton()
        
        // Enable debug logging to help track down problems.
        GNSMessageManager.setDebugLoggingEnabled(true)
        
        // Create the message manager, which lets you publish messages and subscribe to messages
        // published by nearby devices.
        messageMgr = GNSMessageManager(apiKey: kMyAPIKey,
                                       paramsBlock: {(params: GNSMessageManagerParams?) -> Void in
                                        guard let params = params else { return }
                                        
                                        // This is called when microphone permission is enabled or disabled by the user.
                                        params.microphonePermissionErrorHandler = { hasError in
                                            if (hasError) {
                                                print("Nearby works better if microphone use is allowed")
                                            }
                                        }
                                        // This is called when Bluetooth permission is enabled or disabled by the user.
                                        params.bluetoothPermissionErrorHandler = { hasError in
                                            if (hasError) {
                                                print("Nearby works better if Bluetooth use is allowed")
                                            }
                                        }
                                        // This is called when Bluetooth is powered on or off by the user.
                                        params.bluetoothPowerErrorHandler = { hasError in
                                            if (hasError) {
                                                print("Nearby works better if Bluetooth is turned on")
                                            }
                                        }
        })
        
        return true
    }
    
    /// Sets up the right bar button to start or stop sharing, depending on current sharing mode.
    func setupStartStopButton() {
        let isSharing = (publication != nil)
        messageViewController.rightBarButton = UIBarButtonItem(title: isSharing ? "Stop" : "Start",
                                                               style: .plain,
                                                               target: self, action: isSharing ? #selector(AppDelegate.stopSharing) :  #selector(AppDelegate.startSharingWithRandomName))
    }
    
    /// Starts sharing with a randomized name.
    @objc func startSharingWithRandomName() {
        startSharing(withName: String(format:"Anonymous %d", arc4random() % 100))
        setupStartStopButton()
    }
    
    /// Stops publishing/subscribing.
    @objc func stopSharing() {
        publication = nil
        subscription = nil
        messageViewController.title = ""
        setupStartStopButton()
    }
    
    /// Toggles the permission state of Nearby.
    @objc func toggleNearbyPermission() {
        GNSPermission.setGranted(!GNSPermission.isGranted())
    }
    
    /// Starts publishing the specified name and scanning for nearby devices that are publishing
    /// their names.
    func startSharing(withName name: String) {
        if let messageMgr = self.messageMgr {
            // Show the name in the message view title and set up the Stop button.
            messageViewController.title = name
            
            // Publish the name to nearby devices.
            let pubMessage: GNSMessage = GNSMessage(content: name.data(using: .utf8, allowLossyConversion: true))
            
            publication = messageMgr.publication(with: pubMessage,
            paramsBlock: { (params: GNSPublicationParams?) in
              guard let params = params else { return }
              params.strategy = GNSStrategy(paramsBlock: { (params: GNSStrategyParams?) in
                guard let params = params else { return }
                params.discoveryMediums = .audio
                params.discoveryMode = .scan
              })
            })
            //
            
            
            //publication = messageMgr.publication(with: pubMessage)
            
            // Subscribe to messages from nearby devices and display them in the message view.
            subscription = messageMgr.subscription(messageFoundHandler: {[unowned self] (message: GNSMessage?) -> Void in
                guard let message = message else { return }
                self.messageViewController.addMessage(String(data: message.content, encoding:.utf8))
                self.stopSharing()
                print(String(data: message.content, encoding:.utf8)! + " Successfull ----------------->")
                }, messageLostHandler: {[unowned self](message: GNSMessage?) -> Void in
                    guard let message = message else { return }
                    self.messageViewController.removeMessage(String(data: message.content, encoding: .utf8))
                    print(String(data: message.content, encoding:.utf8)! + " Failed ----------------->")
            })
        }
    }
}
