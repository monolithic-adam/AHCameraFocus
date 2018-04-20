//
//  FocusImageView.swift
//  AHCameraFocus
//
//  Created by ahenry on 2018/04/20.
//  Copyright © 2018 Monolithic. All rights reserved.
//

import UIKit

class FocusImageView: UIImageView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        self.image = UIImage(named: "focus")
    }

    func startLongPressAnimation() {
        self.alpha = 1.0
        self.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)

        UIView.animate(withDuration: 0.2,
                       delay: 0.8,
                       options: [.curveEaseIn, .allowUserInteraction],
                       animations: {
                        self.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        }, completion: { _ in
            UIView.animate(withDuration: 0.3,
                           delay: 0.0,
                           options: [.curveEaseOut, .allowUserInteraction],
                           animations: {
                            self.alpha = 0.5
                            self.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }, completion: { _ in
                UIView.animate(withDuration: 0.2,
                               delay: 0.0,
                               options: [.curveEaseIn, .allowUserInteraction],
                               animations: {
                                self.alpha = 1.0
                                self.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
                }, completion: { [weak self] _ in
                    UIView.animate(withDuration: 0.3,
                                   delay: 0.0,
                                   options: [.curveEaseIn, .allowUserInteraction],
                                   animations: {
                                    self?.alpha = 0.0
                                    self?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    }, completion: { _ in
                        self?.removeFromSuperview()
                    })
                })
            })
        })
    }

    func startTapAnimation() {
        self.layer.removeAllAnimations()
        self.alpha = 0
        self.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)

        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: [.curveEaseIn, .allowUserInteraction],
                       animations: {
                        self.alpha = 1.0
                        self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }, completion: nil)
    }

    func showFocus() {
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: [.curveEaseOut, .allowUserInteraction],
                       animations: {
                        self.alpha = 1.0
        }, completion: nil)
    }

    func hideFocus() {
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: [.curveEaseOut, .allowUserInteraction],
                       animations: {
                        self.alpha = 0.5
        }, completion: nil)
    }
}
