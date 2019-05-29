//
//  IssueCommentImageCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 5/19/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit
import SDWebImage
import IGListKit

protocol IssueCommentImageCellDelegate: class {
    func didTapImage(cell: IssueCommentImageCell, image: UIImage, animatedImageData: Data?)
}

protocol IssueCommentImageHeightCellDelegate: class {
    func imageDidFinishLoad(cell: IssueCommentImageCell, url: URL, size: CGSize)
}

final class IssueCommentImageCell: IssueCommentBaseCell, ListBindable {

    static let bottomInset = Styles.Sizes.rowSpacing

    weak var delegate: IssueCommentImageCellDelegate?
    weak var heightDelegate: IssueCommentImageHeightCellDelegate?

    let imageView = FLAnimatedImageView()

    private let spinner = UIActivityIndicatorView(style: .gray)
    private var tapGesture: UITapGestureRecognizer!

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIgnoresInvertColors = true

        contentView.addSubview(imageView)

        spinner.hidesWhenStopped = true
        contentView.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalTo(imageView)
        }

        tapGesture = UITapGestureRecognizer(target: self, action: #selector(IssueCommentImageCell.onTap(recognizer:)))
        tapGesture.require(toFail: doubleTapGesture)
        tapGesture.delegate = self
        contentView.addGestureRecognizer(tapGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var frame = contentView.bounds
        frame.size.height -= IssueCommentImageCell.bottomInset
        if let size = imageView.image?.size {
            frame.size = BoundedImageSize(originalSize: size, containerWidth: frame.width)
        }
        imageView.frame = frame
    }

    // MARK: Private API

    @objc func onTap(recognizer: UITapGestureRecognizer) {
        // action will only trigger if shouldBegin returns true
        guard let image = imageView.image else { return }

        // If FLAnimatedImage is nil, access to implicit unwrapped optional will crash
        if let animatedImage = imageView.animatedImage {
            delegate?.didTapImage(cell: self, image: image, animatedImageData: animatedImage.data)
        } else {
            delegate?.didTapImage(cell: self, image: image, animatedImageData: nil)
        }
    }

    // MARK: ListBindable

    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? IssueCommentImageModel else { return }
        configure(with: viewModel)
    }

    func configure(with model: IssueCommentImageModel) {
        imageView.image = nil
        imageView.backgroundColor = Styles.Colors.Gray.lighter.color
        spinner.startAnimating()

        let imageURL = model.url
        imageView.sd_setImage(with: imageURL) { [weak self] (image, _, _, url) in
            guard let strongSelf = self else { return }
            strongSelf.imageView.backgroundColor = .clear
            strongSelf.spinner.stopAnimating()

            if let size = image?.size {
                strongSelf.heightDelegate?.imageDidFinishLoad(cell: strongSelf, url: imageURL, size: size)
            }

            // forces the image view to lay itself out using the original image size
            strongSelf.setNeedsLayout()
        }
    }

    // MARK: UIGestureRecognizerDelegate

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === tapGesture
            else { return super.gestureRecognizerShouldBegin(gestureRecognizer) }

        // only start the image tap gesture when an image exists
        // and the tap is within the actual image's bounds
        guard let image = imageView.image,
            collapsed == false
            else { return false }

        let imageSize = image.size
        let imageViewBounds = imageView.bounds

        // https://stackoverflow.com/a/2351101/940936
        let ratioX = imageViewBounds.width/imageSize.width
        let ratioY = imageViewBounds.height/imageSize.height
        let imageBounds: CGRect
        if ratioX < ratioY {
            let height = ratioX * imageSize.height
            imageBounds = CGRect(
                x: 0,
                y: (imageViewBounds.height - height) / 2,
                width: imageViewBounds.width,
                height: height
            )
        } else {
            let width = ratioY * imageSize.width
            imageBounds = CGRect(
                x: (imageViewBounds.width - width) / 2,
                y: 0,
                width: width,
                height: imageViewBounds.height
            )
        }

        let location = gestureRecognizer.location(in: imageView)
        return imageBounds.contains(location)
    }

}
