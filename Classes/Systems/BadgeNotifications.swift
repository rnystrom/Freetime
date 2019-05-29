//
//  BadgeNotifications.swift
//  Freetime
//
//  Created by Ryan Nystrom on 8/12/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import UserNotifications
import GitHubAPI
import GitHubSession
import GitHawkRoutes

final class BadgeNotifications {

    private static let countWhenDisabledKey = "com.freetime.BadgeNotifications.count-when-disabled"
    private static let defaults = UserDefaults.standard

    private static let userKey = "com.freetime.BadgeNotifications.user-enabled"
    static var isBadgeEnabled: Bool {
        get {
            return defaults.bool(forKey: userKey)
        }
        set {
            let application = UIApplication.shared
            if newValue == false {
                defaults.set(application.applicationIconBadgeNumber, forKey: countWhenDisabledKey)
                application.applicationIconBadgeNumber = 0
            } else {
                application.applicationIconBadgeNumber = defaults.integer(forKey: countWhenDisabledKey)
            }
            defaults.set(newValue, forKey: userKey)
        }
    }

    private static let notificationKey = "com.freetime.BadgeNotifications.notifications-enabled"
    static var isLocalNotificationEnabled: Bool {
        get { return defaults.bool(forKey: notificationKey) }
        set { return defaults.set(newValue, forKey: notificationKey)}
    }

    static func check(callback: @escaping (Result<(Bool, Bool)>) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .denied:
                    callback(.error(nil))
                case .authorized, .provisional, .notDetermined:
                    callback(.success((isBadgeEnabled, isLocalNotificationEnabled)))
                }
            }
        }
    }

    static func configure(
        application: UIApplication = UIApplication.shared,
        permissionHandler: ((Bool) -> Void)? = nil
        ) {
        var options = UNAuthorizationOptions()
        if isBadgeEnabled {
            options.insert(.badge)
        }
        if isLocalNotificationEnabled {
            options.insert(.alert)
            options.insert(.sound)
        }

        if !options.isEmpty {
            UNUserNotificationCenter.current().requestAuthorization(options: options, completionHandler: { (granted, _) in
                permissionHandler?(granted)
            })
            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        } else {
            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
        }
    }

    private let client: Client

    init(client: Client) {
        self.client = client
    }

    func fetch(application: UIApplication, handler: @escaping (UIBackgroundFetchResult) -> Void) {
        let isBadgeEnabled = BadgeNotifications.isBadgeEnabled
        let isLocalNotificationEnabled = BadgeNotifications.isLocalNotificationEnabled
        guard isBadgeEnabled || isLocalNotificationEnabled else {
            handler(.noData)
            return
        }

        client.send(V3NotificationRequest(all: false)) { [weak self] result in
            switch result {
            case .success(let response):
                BadgeNotifications.updateBadge(
                    application: application,
                    count: response.data.count
                )
                self?.updateLocalNotificationCache(
                    notifications: response.data,
                    showAlert: isLocalNotificationEnabled,
                    completion: { changed in
                        handler(changed ? .newData : .noData)
                })
            case .failure:
                handler(.failed)
            }
        }
    }

    private lazy var localNotificationsCache = LocalNotificationsCache()

    func updateLocalNotificationCache(
        notifications: [V3Notification],
        showAlert: Bool,
        completion: ((Bool) -> Void)? = nil
        ) {
        localNotificationsCache.update(notifications: notifications) { [weak self] filtered in
            if showAlert {
                self?.sendLocalPush(for: filtered)
            }
            completion?(filtered.count > 0)
        }
    }

    private func sendLocalPush(for notifications: [V3Notification]) {
        let center = UNUserNotificationCenter.current()
        notifications.forEach {
            guard let type = NotificationType(rawValue: $0.subject.type.rawValue),
                let identifier = $0.subject.identifier
                else { return }

            let content = UNMutableNotificationContent()
            content.title = $0.repository.fullName
            content.body = $0.subject.title
            content.subtitle = "\(type.localizedString) \(identifier.string)"

            // currently only handling issues
            if let identifier = $0.subject.identifier,
                case .number(let n) = identifier {
                content.set(route: IssueRoute(
                    owner: $0.repository.owner.login,
                    repo: $0.repository.name,
                    number: n
                ))
            }

            let request = UNNotificationRequest(
                identifier: $0.id,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            center.add(request)
        }
    }

    static func updateBadge(application: UIApplication = UIApplication.shared, count: Int) {
        application.applicationIconBadgeNumber = isBadgeEnabled ? count : 0
    }

    static func clear(for notification: NotificationViewModel) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [notification.identifier]
        )
    }

}
