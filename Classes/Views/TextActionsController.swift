//
//  TextActionsController.swift
//  Freetime
//
//  Created by Ryan Nystrom on 10/8/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

final class TextActionsController: NSObject,
    IssueTextActionsViewDelegate,
    UINavigationControllerDelegate,
    UIImagePickerControllerDelegate,
    ImageUploadDelegate {

    private weak var textView: UITextView?
    weak var viewController: UIViewController?
    private var client: GithubClient?

    // MARK: Public API

    func configure(client: GithubClient, textView: UITextView, actions: IssueTextActionsView) {
        self.client = client
        self.textView = textView
        actions.delegate = self
    }

    // MARK: IssueTextActionsViewDelegate

    func didSelect(actionsView: IssueTextActionsView, operation: IssueTextActionOperation) {
        func handle(_ operation: IssueTextActionOperation.Operation) {
            switch operation {
            case .wrap(let left, let right):
                textView?.replace(left: left, right: right, atLineStart: false)
            case .line(let left):
                textView?.replace(left: left, right: nil, atLineStart: true)
            case .execute(let block):
                block()
            case .uploadImage:
                displayUploadImage()
            case .multi(let operations):
                operations.forEach { handle($0) }
            }
        }
        handle(operation.operation)
    }

    // MARK: Image Upload

    func displayUploadImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.modalPresentationStyle = .formSheet
        viewController?.route_present(to: imagePicker)
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }

        let username = client?.userSession?.username ?? Constants.Strings.unknown
        guard let uploadController = ImageUploadTableViewController.create(image, username: username, delegate: self) else { return }

        picker.pushViewController(uploadController, animated: trueUnlessReduceMotionEnabled)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: trueUnlessReduceMotionEnabled)
    }

    // MARK: ImageUploadDelegate

    func imageUploaded(link: String, altText: String) {
        textView?.replace(left: "![\(altText)](\(link))", right: nil, atLineStart: false)
    }

}
