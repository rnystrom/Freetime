//
//  SplashView.swift
//  Freetime
//
//  Created by Yury Bogdanov on 25/07/2018.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import UIKit
import SnapKit

final class SplashView: UIView {

    // MARK: Private properties

    private var birdImageView: UIImageView!
    private var branchesImageView: UIImageView!

    // MARK: Public API

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setupView()
    }

    func configureView() {
        addBirdAnimation()
        addBranchesAnimation()
    }

    // MARK: Private API

    private func setupView() {
        branchesImageView = UIImageView(image: UIImage(named: "splash_branches"))
        addSubview(branchesImageView)
        branchesImageView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview()
        }

        birdImageView = UIImageView(image: UIImage(named: "splash"))
        addSubview(birdImageView)
        birdImageView.snp.makeConstraints { make in
            make.top.left.right.bottom.equalToSuperview().inset(30)
        }
    }

    private func addBirdAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")

        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 0.9
        pulseAnimation.duration = 2
        pulseAnimation.fillMode = .forwards
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        birdImageView.layer.add(pulseAnimation, forKey: "scaling")
    }

    private func addBranchesAnimation() {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")

        rotateAnimation.repeatCount = .infinity
        rotateAnimation.byValue = 2 * Double.pi
        rotateAnimation.duration = 120
        rotateAnimation.fillMode = .forwards
        rotateAnimation.timingFunction = CAMediaTimingFunction(name: .linear)

        branchesImageView.layer.add(rotateAnimation, forKey: "rotation")
    }

}
