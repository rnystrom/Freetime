//
//  LocalNotificationsCache.swift
//  Freetime
//
//  Created by Ryan Nystrom on 8/26/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation
import FMDB
import GitHubAPI

final class LocalNotificationsCache {

    private static let sqlitePath: String = {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return "\(path)/read-notifications.sqlite"
    }()

    private let path: String
    private lazy var queue: FMDatabaseQueue = {
        return FMDatabaseQueue(path: self.path)!
    }()

    init(
        path: String = LocalNotificationsCache.sqlitePath
        ) {
        self.path = path
    }

    func update(
        notifications: [V3Notification],
        completion: @escaping ([V3Notification]) -> Void
        ) {
        guard notifications.count > 0 else {
            completion([])
            return
        }

        queue.inDatabase { db in
            let table = "seen"
            let apiCol = "apiID"
            let idCol = "id"

            var map = [String: V3Notification]()
            notifications.forEach {
                let key = "\($0.id)-\($0.updatedAt.timeIntervalSince1970)"
                map[key] = $0
            }
            let apiIDs = map.keys.map { $0 }

            do {
                // attempt to create the table
                try db.executeUpdate(
                    "create table if not exists \(table) (\(idCol) integer primary key autoincrement, \(apiCol) text)",
                    values: nil
                )

                // remove notifications that already exist
                let selectSanitized = map.keys.map { _ in "?" }.joined(separator: ", ")
                let rs = try db.executeQuery(
                    "select \(apiCol) from \(table) where \(apiCol) in (\(selectSanitized))",
                    values: apiIDs
                )
                while rs.next() {
                    if let key = rs.string(forColumn: apiCol) {
                        map.removeValue(forKey: key)
                    }
                }

                // only perform updates if there are new notifications
                if map.count > 0 {
                    // add latest notification ids in the db
                    let insertSanitized = map.keys.map { _ in "(?)" }.joined(separator: ", ")
                    try db.executeUpdate(
                        "insert into \(table) (\(apiCol)) values \(insertSanitized)",
                        values: map.keys.map { $0 }
                    )

                    // cap the local database to latest 1000 notifications
                    try db.executeUpdate(
                        "delete from \(table) where \(idCol) not in (select \(idCol) from \(table) order by \(idCol) desc limit 1000)",
                        values: nil
                    )
                }
            } catch {
                print("failed: \(error.localizedDescription)")
            }

            completion(map.values.map { $0 })
        }
    }

}
