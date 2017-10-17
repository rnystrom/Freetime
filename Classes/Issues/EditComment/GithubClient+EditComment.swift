//
//  GithubClient+EditComment.swift
//  Freetime
//
//  Created by Ryan Nystrom on 10/16/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import Foundation

extension GithubClient {

    func editComment(
        owner: String,
        repo: String,
        commentID: Int,
        body: String,
        completion: @escaping (Result<Bool>) -> ()
        ) {
        // https://developer.github.com/v3/issues/comments/#edit-a-comment
        request(Request(
            path: "repos/\(owner)/\(repo)/issues/comments/\(commentID)",
            method: .patch,
            parameters: ["body": body],
            completion: { (response, _) in
            if response.response?.statusCode == 200 {
                completion(.success(true))
            } else {
                completion(.error(response.error))
            }
        }))
    }

}
