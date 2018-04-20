//
//  CustomSlider.swift
//  AHCameraFocus
//
//  Created by ahenry on 2018/04/19.
//  Copyright © 2018 Monolithic. All rights reserved.
//

//TODO: WHAT TO DO ABOUT TIMER?

import UIKit

class CustomSlider: UIControl {
    let maskLayer = CALayer()
    let trackLayer = CALayer()
    let clearLayer = CALayer()
    let handleLayer = HandleLayer()
    let touchHandleLayer = HandleLayer()

    var barImage: UIImage?
    var handleImage: UIImage?
    var maskImage: UIImage?

    var maximumValue: CGFloat = 1
    var minimumValue: CGFloat = -1
    var value: CGFloat = 0
    var handleWidth: CGFloat = 0
    var useableTrackLength: CGFloat = 0
    var useableMaskTrackLength: CGFloat = 0
    var previousTouchPoint: CGPoint = .zero
    var isLocked = false

    var onFocusAnimationStart: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        barImage = UIImage(named: "brightness_bar.png")
        trackLayer.contents = barImage?.cgImage
        self.layer.addSublayer(trackLayer)

        touchHandleLayer.slider = self
        self.layer.addSublayer(touchHandleLayer)

        handleImage = UIImage(named: "brightness_knob.png")
        handleLayer.slider = self
        handleLayer.contents = handleImage?.cgImage
        self.layer.addSublayer(handleLayer)

        maskImage = UIImage(named: "brightness_knob_mask_clear.png")
        maskLayer.contents = maskImage?.cgImage
        trackLayer.mask = maskLayer

        self.alpha = 0.0

        self.setLayerFrames()
    }

    func setLayerFrames() {
        trackLayer.frame = CGRect(x: 0, y: 72, width: (barImage?.size.width ?? 0) / 2, height: (barImage?.size.height ?? 0) / 2)

        useableTrackLength = self.bounds.width - (handleImage?.size.height ?? 0) / 2
        useableMaskTrackLength = ((maskImage?.size.width ?? 0) / 4) - (handleImage?.size.height ?? 0) / 2
        let handleCenter = positionFor(value: value)
        let maskCenter = maskPositionFor(value: value)

        handleLayer.frame = CGRect(x: handleCenter,
                                   y: (-(handleImage?.size.width ?? 0) / 4) + 75,
                                   width: (handleImage?.size.width ?? 0)  / 2,
                                   height: (handleImage?.size.height ?? 0)  / 2)
        maskLayer.frame = CGRect(x: maskCenter - 130.5,
                                 y: 0,
                                 width: (maskImage?.size.width ?? 0) / 2,
                                 height: (maskImage?.size.height ?? 0) / 2);

        touchHandleLayer.setNeedsDisplay()

        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: .curveEaseIn,
                       animations: {
                        self.alpha = 1.0
        }, completion: nil)
    }

    func showLockedSlider() {
        self.alpha = 1.0
        trackLayer.removeFromSuperlayer()
    }

    func positionFor(value: CGFloat) -> CGFloat {
        return useableTrackLength * (value - minimumValue) / (maximumValue - minimumValue)
    }

    func maskPositionFor(value: CGFloat) -> CGFloat {
        return useableMaskTrackLength * (value - minimumValue) / (maximumValue - minimumValue)
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        self.previousTouchPoint = touch.location(in: self)

        if touchHandleLayer.frame.contains(self.previousTouchPoint) {
            handleLayer.highlighted = true
        }

        return handleLayer.highlighted
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let touchPoint = touch.location(in: self)

        let delta = (touchPoint.x - previousTouchPoint.x) / 20
        let valueDelta = (maximumValue - minimumValue) * delta / useableTrackLength

        previousTouchPoint = touchPoint

        if handleLayer.highlighted {
            self.value += valueDelta
            self.value = bound(value: self.value, lower: minimumValue, upper: maximumValue)
        }

        CATransaction.begin()
        CATransaction.disableActions()

        self.setLayerFrames()

        CATransaction.commit()

        self.sendActions(for: .valueChanged)

        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        handleLayer.highlighted = false
    }

    func fadeOut() {
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: {
                        self.alpha = 1.0
        }, completion: nil)

        onFocusAnimationStart?()
    }

    func bound(value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        return min(max(value, lower), upper)
    }
}
