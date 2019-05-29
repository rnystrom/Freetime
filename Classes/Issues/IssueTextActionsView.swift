//
//  IssueTextActionsView.swift
//  Freetime
//
//  Created by Ryan Nystrom on 7/31/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit

final class IssueTextActionsCell: SelectableCell {

    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.tintColor = Styles.Colors.Gray.dark.color
        imageView.contentMode = .center
        contentView.addSubview(imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds
    }

    func configure(operation: IssueTextActionOperation) {
        imageView.image = operation.icon
        imageView.accessibilityLabel = operation.name
    }

    override var accessibilityLabel: String? {
        get {
            return AccessibilityHelper.generatedLabel(forCell: self)
        }
        set { }
    }

}

protocol IssueTextActionsViewDelegate: class {
    func didSelect(actionsView: IssueTextActionsView, operation: IssueTextActionOperation)
}

protocol IssueTextActionsViewSendDelegate: class {
    func didSend(for actionsView: IssueTextActionsView)
}

struct IssueTextActionOperation {

    enum Operation {
        case line(String)
        case wrap(String, String)
        case execute(() -> Void)
        case multi([Operation])
        case uploadImage
    }

    let icon: UIImage?
    let operation: Operation
    let name: String

}

final class IssueTextActionsView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    weak var delegate: IssueTextActionsViewDelegate?
    weak var sendDelegate: IssueTextActionsViewSendDelegate?

    private let operations: [IssueTextActionOperation]
    private let identifier = "cell"
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = Styles.Sizes.rowSpacing
        let c = UICollectionView(frame: .zero, collectionViewLayout: layout)
        c.backgroundColor = .clear
        c.alwaysBounceVertical = false
        c.alwaysBounceHorizontal = true
        c.showsVerticalScrollIndicator = false
        c.showsHorizontalScrollIndicator = false
        return c
    }()
    private let gradientWidth = Styles.Sizes.gutter
    private let sendButtonGradientLayer = CAGradientLayer()
    private let sendButton = UIButton()
    private let activityIndicator = UIActivityIndicatorView(
        style: .gray
    )

    public var sendButtonEnabled: Bool {
        get { return sendButton.isEnabled }
        set {
            sendButton.isEnabled = newValue
            sendButton.alpha = newValue ? 1 : 0.25
        }
    }

    public var isProcessing: Bool = false {
        didSet {
            sendButton.isEnabled = !isProcessing
            if isProcessing {
                activityIndicator.startAnimating()
                sendButton.isHidden = true
            } else {
                activityIndicator.stopAnimating()
                sendButton.isHidden = false
            }
        }
    }

    init(operations: [IssueTextActionOperation], showSendButton: Bool) {
        self.operations = operations

        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        collectionView.clipsToBounds = true
        collectionView.register(IssueTextActionsCell.self, forCellWithReuseIdentifier: identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        addSubview(collectionView)

        if showSendButton {
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: gradientWidth)

            sendButtonGradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
            sendButtonGradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
            sendButtonGradientLayer.colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor.white.cgColor]
            layer.addSublayer(sendButtonGradientLayer)

            let blue = Styles.Colors.Blue.medium.color
            sendButton.tintColor = blue
            sendButton.imageView?.tintColor = blue
            sendButton.setImage(UIImage(named: "send").withRenderingMode(.alwaysTemplate), for: .normal)
            sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)
            addSubview(sendButton)

            activityIndicator.hidesWhenStopped = true
            addSubview(activityIndicator)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if sendButton.superview != nil {
            let height = bounds.height
            let imageWidth = sendButton.image(for: .normal)?.size.width ?? 0
            let buttonWidth = imageWidth + 2*Styles.Sizes.gutter
            sendButton.frame = CGRect(
                x: bounds.width - buttonWidth,
                y: 0,
                width: buttonWidth,
                height: height
            )
            sendButtonGradientLayer.frame = CGRect(
                x: sendButton.frame.minX - gradientWidth,
                y: 0,
                width: gradientWidth,
                height: height
            )
            activityIndicator.center = sendButton.center
            // put collection view beneath the gradient layer
            collectionView.frame = CGRect(x: 0, y: 0, width: sendButton.frame.minX, height: height)
        } else {
            collectionView.frame = bounds
        }
    }

    @objc private func onSend() {
        isProcessing = true
        sendDelegate?.didSend(for: self)
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return operations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? IssueTextActionsCell
            else { fatalError("Wrong cell type") }
        cell.configure(operation: operations[indexPath.item])
        return cell
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: trueUnlessReduceMotionEnabled)
        delegate?.didSelect(actionsView: self, operation: operations[indexPath.item])
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height
        return CGSize(
            width: (operations[indexPath.item].icon?.size.width ?? 0) + Styles.Sizes.rowSpacing*2,
            height: height
        )
    }

}
