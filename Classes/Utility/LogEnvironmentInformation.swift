//
//  LogEnvironmentInformation.swift
//  Freetime
//
//  Created by Ryan Nystrom on 12/17/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation
import Crashlytics

func LogEnvironmentInformation(application: UIApplication) {
    // information to help understand the device+locale demographics of users
    // be able to better prioritize & serve AX, RTL, and non-en languages
    Answers.logCustomEvent(withName: "environment", customAttributes: [
        "voice-enabled": UIAccessibility.isVoiceOverRunning ? "1": "0",
        "lang": NSLocale.autoupdatingCurrent.languageCode ?? "n/a",
        "country": NSLocale.autoupdatingCurrent.regionCode ?? "n/a",
        "rtl": application.userInterfaceLayoutDirection == .rightToLeft ? "1" : "0"
        ])
}
