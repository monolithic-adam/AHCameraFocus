//
//  ViewController.swift
//  AHCameraFocus
//
//  Created by ahenry on 2018/04/18.
//  Copyright © 2018 Monolithic. All rights reserved.
//

import UIKit
import SnapKit
import AVFoundation

class AHCameraFocusViewController: UIViewController, UIGestureRecognizerDelegate {
    var device: AVCaptureDevice?
    private let exposureDurationPower = 5
    private let exposureMinimumDuration = 1.0 / 1000.0
    private var isEnablePint = true
    private var hasBeenTapped = false
    private var isFirst = true

    private var customSlider = CustomSlider()
    private let lockedNotifyImageView = UIImageView()
    private var focusImageView: FocusImageView?
    private var focusOptions: FocusOptions = FocusOptions()

    private var originalISO: Float = 0
    private var originalExposureDuration: CMTime = CMTime()
    private var absoluteMax: Float = 0
    private var absoluteMin: Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.focusImageView = FocusImageView(frame: CGRect(x: 0,
                                                           y: 0,
                                                           width: focusOptions.focusSize,
                                                           height: focusOptions.focusSize))
        self.customSlider.frame = CGRect(x: 0,
                                         y: 0,
                                         width: focusOptions.sliderWidth,
                                         height: focusOptions.sliderHeight)
        customSlider.isLocked = false
        customSlider.addTarget(self, action: #selector(updateBrightness(sender:)), for: .valueChanged)
        customSlider.onFocusAnimationStart = { [weak self] in
            self?.focusImageView?.hideFocus()
        }

        lockedNotifyImageView.frame = CGRect(x: 0,
                                             y: 0,
                                             width: 0,
                                             height: 0)
        lockedNotifyImageView.alpha = 0.0
        self.view.addSubview(lockedNotifyImageView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        self.view.addGestureRecognizer(tapGesture)
        tapGesture.delegate = self
    }

    @objc func updateBrightness(sender: UISlider) {
        self.changeExposureDuration(value: Float(-customSlider.value))
    }

    func enablePint() {
        isEnablePint = true
    }

    func disablePint() {
        isEnablePint = false
    }

    @objc func tapHandler(gestureRecognizer: UITapGestureRecognizer) {
        isFirst = true
        if !hasBeenTapped {
            self.allowBrightnessSwipe()
        }
        customSlider.removeFromSuperview()
        focusImageView?.removeFromSuperview()
        self.focusImageView = FocusImageView(frame: CGRect(x: 0,
                                                           y: 0,
                                                           width: focusOptions.focusSize,
                                                           height: focusOptions.focusSize))
        self.customSlider.frame = CGRect(x: 0,
                                         y: 0,
                                         width: focusOptions.sliderWidth,
                                         height: focusOptions.sliderHeight)
        guard isEnablePint else { return }

        let touchPoint = gestureRecognizer.location(in: self.view)
        let viewSize = self.view.bounds.size
        let pointOfInterest = CGPoint(x: touchPoint.y / viewSize.height, y: 1.0 - touchPoint.x / viewSize.width)

        do {
            try self.device?.lockForConfiguration()
            self.device?.focusPointOfInterest = pointOfInterest
            self.device?.focusMode = .autoFocus
            self.device?.exposureMode = .autoExpose
            self.device?.unlockForConfiguration()
        } catch {
            print("Failed To Lock Device")
        }

        if let focusImageView = self.focusImageView {
            self.view.addSubview(focusImageView)
            focusImageView.frame = CGRect(x: touchPoint.x - focusImageView.frame.size.width / 2,
                                          y: touchPoint.y - focusImageView.frame.size.height / 2,
                                          width: focusImageView.frame.width,
                                          height: focusImageView.frame.height)
            focusImageView.startTapAnimation()
        }

        let sliderFrame = CGRect(x: touchPoint.x - 72, y: touchPoint.y - 125, width: 143, height: 143)
        customSlider = CustomSlider(frame: sliderFrame)
        customSlider.addTarget(self, action: #selector(updateBrightness(sender:)), for: .valueChanged)
        customSlider.onFocusAnimationStart = { [weak self] in
            self?.focusImageView?.hideFocus()
        }
        self.view.addSubview(customSlider)
    }

    @objc func panHandler(panGestureRecognizer: UIPanGestureRecognizer) {
        focusImageView?.showFocus()
        if panGestureRecognizer.velocity(in: self.view).y < 0 {
            if customSlider.value < -1 {
                return
            }

            customSlider.value += (panGestureRecognizer.velocity(in: self.view).y / UIScreen.main.bounds.height) / 115
        } else {
            if customSlider.value > 1 {
                return
            }

            customSlider.value += (panGestureRecognizer.velocity(in: self.view).y / UIScreen.main.bounds.height) / 115
        }

        print(customSlider.value)
        self.changeExposureDuration(value: Float(-customSlider.value))
        customSlider.setLayerFrames()
    }

    func allowBrightnessSwipe() {
        hasBeenTapped = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panHandler))
        self.view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.delegate = self
    }

    func changeExposureDuration(value: Float) {
        guard let device = self.device else { return }
        if isFirst {
            self.originalISO = device.iso
            self.originalExposureDuration = device.exposureDuration
            self.absoluteMax = device.activeFormat.maxISO
            self.absoluteMin = device.activeFormat.minISO
            isFirst = false
        }

        var newIso = originalISO + (value * 50)
        if newIso < absoluteMin {
            newIso = absoluteMin
        }
        if newIso > absoluteMax {
            newIso = absoluteMax
        }

        let maxExposure = 30000000;
        let minExposure = 3000000;
        let maxDifference = maxExposure - Int(originalExposureDuration.value);
        let minDifference = Int(originalExposureDuration.value) - minExposure;

        var newDuration = 0
        if value < 0 {
            newDuration = Int(originalExposureDuration.value) + (Int(value) * minDifference)
        } else {
            newDuration = Int(originalExposureDuration.value) + (Int(value) * maxDifference)
        }
        do {
            try device.lockForConfiguration()
            device.setExposureModeCustom(duration: CMTime(value: CMTimeValue(newDuration),
                                                          timescale: 1000*1000*1000),
                                         iso: newIso,
                                         completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            print("Device Lock Failed")
        }
    }
}
