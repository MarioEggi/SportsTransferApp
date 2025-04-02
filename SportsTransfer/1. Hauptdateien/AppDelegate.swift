//
//  AppDelegate.swift

import UIKit
import Firebase
import FirebaseMessaging
import FirebaseAuth
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        // Push-Benachrichtigungen konfigurieren
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Berechtigung für Push-Benachrichtigungen anfragen
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Fehler bei der Berechtigungsanfrage für Push-Benachrichtigungen: \(error.localizedDescription)")
            } else {
                print("Push-Benachrichtigungen erlaubt: \(granted)")
            }
        }
        application.registerForRemoteNotifications()

        return true
    }

    // FCM-Token empfangen und in Firestore speichern
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("FCM-Token: \(fcmToken)")

        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userID).setData(["fcmToken": fcmToken], merge: true) { error in
            if let error = error {
                print("Fehler beim Speichern des FCM-Tokens: \(error.localizedDescription)")
            } else {
                print("FCM-Token erfolgreich gespeichert für Benutzer \(userID)")
            }
        }
    }

    // Push-Benachrichtigung empfangen (im Vordergrund)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("Push-Benachrichtigung empfangen (im Vordergrund): \(userInfo)")
        completionHandler([.alert, .sound, .badge])
    }

    // Push-Benachrichtigung angeklickt
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Push-Benachrichtigung angeklickt: \(userInfo)")
        // Hier könnten wir z. B. zur Detailansicht eines Transferprozesses navigieren
        completionHandler()
    }

    // APNs-Token empfangen
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("APNs-Token empfangen: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }

    // Fehler bei der Registrierung für Push-Benachrichtigungen
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Fehler bei der Registrierung für Push-Benachrichtigungen: \(error.localizedDescription)")
    }
}
