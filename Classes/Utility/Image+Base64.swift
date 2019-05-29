//
//  Image+Base64.swift
//  Freetime
//
//  Created by Sherlock, James on 18/10/2017.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

extension UIImage {

    /// Compressed and Encodes in Base64 the given image.
    ///
    /// Process is moved to a background thread in order to prevent UI blocking.
    ///
    /// Compression is a value between 0.0 and 1.0. Lower is smaller file size but worse quality.
    func compressAndEncode(compression: CGFloat = 0.65, completion: @escaping (Result<String>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let data = self.jpegData(compressionQuality: compression)

            guard let base64 = data?.base64EncodedString() else {
                completion(.error(nil))
                return
            }

            completion(.success(base64))
        }
    }

}
