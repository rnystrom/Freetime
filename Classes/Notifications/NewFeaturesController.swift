//
//  NewFeaturesController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 11/22/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation
import GitHubAPI
import IGListKit

final class NewFeaturesController {

    // change to true for hardcoded testing
    private let testing = false
    private(set) var latestMarkdown: String?

    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var version: String {
        if testing {
            return "test"
        }
        return NewFeaturesController.version
    }

    private var fetchURL: URL? {
        return URLBuilder(host: "raw.githubusercontent.com")
            .add(paths: ["GitHawkApp", "Release-Notes", "master", "versions", "\(version).md"])
            .url
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession.init(configuration: config)
    }()

    private let userDefaultsKey = "com.freetime.new-features-controller.has-fetched"

    private var hasFetchedLatest: Bool {
        get {
            guard let last = UserDefaults.standard.string(forKey: userDefaultsKey) else {
                return false
            }
            // value kept to latest version when seen
            // pinned to old versions (or empty) when out of date
            return last >= version
        }
        set {
            if newValue {
                UserDefaults.standard.set(version, forKey: userDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            }
        }
    }

    func fetch(success: @escaping () -> Void) {
        guard let url = fetchURL,
            (testing == true || hasFetchedLatest == false)
            else { return }

        let task = session.dataTask(with: url) { data, response, error in
            guard
                let httpResponse = response as? HTTPURLResponse,
                [200, 404].contains(httpResponse.statusCode),
                let data = data else {
                    let message = """
                    "Expected a successfull or failing status code, but errored
                    with \(error?.localizedDescription ?? "no error") for
                    \(response?.description ?? "no response")
                    """
                    return assertionFailure(message)
            }
            let string = String(decoding: data, as: UTF8.self)
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.hasFetchedLatest = true
                strongSelf.latestMarkdown = string
                success()
            }
        }
        task.resume()
    }

}
