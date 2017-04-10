//
//  LoadingView.swift
//  LoadingView
//
//  Created by Gleb Radchenko on 4/9/17.
//  Copyright © 2017 Gleb Radchenko. All rights reserved.
//

import UIKit

open class LoadStatusView: UIView {
    
    enum State {
        case inProgress
        case end
        case start
    }
    
    /// progress value from 0 to 1
    public private(set) var progress: Float = 0.0
    
    public var aspectRatio: Float {
        return Float(bounds.width / bounds.height)
    }
    
    @IBInspectable public var frontColor: UIColor = UIColor(red: 186 / 255, green: 2 / 255, blue: 0, alpha: 1.0)
    
    @IBInspectable public var backColor: UIColor = UIColor(red: 254 / 255, green: 92 / 255, blue: 92 / 255, alpha: 1.0)
    
    @IBInspectable public var completionColor = UIColor(red: 85 / 255, green: 212 / 255, blue: 86 / 255, alpha: 1.0)
    
    @IBInspectable public var fullAnimationDuration = 1.0
    
    lazy var contentLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        
        let width = self.bounds.width / CGFloat(self.aspectRatio)
        let height = self.bounds.width / CGFloat(self.aspectRatio)
        
        layer.path = UIBezierPath(roundedRect: CGRect(x: self.bounds.midX - width / 2,
                                                      y: self.bounds.midY - height / 2,
                                                      width: width,
                                                      height: width),
                                  cornerRadius: height).cgPath
        layer.fillColor = self.backColor.cgColor
        self.layer.addSublayer(layer)
        return layer
    }()
    
    lazy var loadingLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        
        let width = self.bounds.width / CGFloat(self.aspectRatio)
        let height = self.bounds.width / CGFloat(self.aspectRatio)
        
        
        layer.path = UIBezierPath(roundedRect: CGRect(x: self.contentLayer.bounds.midX - width / 2,
                                                      y: self.contentLayer.bounds.midY - height / 2,
                                                      width: width,
                                                      height: height),
                                  cornerRadius: height).cgPath
        
        layer.fillColor = self.frontColor.cgColor
        self.contentLayer.addSublayer(layer)
        return layer
    }()
    
    var state: State = .start
    var animationQueue: [() -> Void] = []
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        set(progress: 0)
    }
    
    func set(progress: Float) {
        let progress = truncf(progress * 100) / 100
        let oldProgress = self.progress
        let oldState = self.state
        
        self.progress = progress > 1 ? 1 : progress
        self.state = state(for: self.progress)
        
        loadingLayer.add(animForLoading(from: oldProgress),
                         forKey: "loading")
        
        if oldState == state { return }
        
        contentLayer.add(animForContentLayer(for: oldState),
                         forKey: "content")
    }
    
    func state(for progress: Float) -> State {
        if progress == 0 {
            return .start
        }
        if progress == 1 {
            return .end
        }
        return .inProgress
    }
    
    func contentShape(for state: State) -> UIBezierPath {
        var width: CGFloat = 0
        let height: CGFloat = bounds.height
        
        switch state {
        case .start, .end:
            width = bounds.width / CGFloat(aspectRatio)
        case .inProgress:
            width = bounds.width
        }
        
        return UIBezierPath(roundedRect: CGRect(x: bounds.midX - width / 2,
                                                y: bounds.midY - height / 2,
                                                width: width,
                                                height: height),
                            cornerRadius: height / 2)
    }
    
    func loadingShape(for progress: Float) -> UIBezierPath {
        var width = bounds.width / CGFloat(aspectRatio) + (bounds.width * CGFloat((aspectRatio - 1) / aspectRatio)) * CGFloat(progress)
        
        if progress == 1 {
            width = bounds.width / CGFloat(aspectRatio)
        }
        
        let height = bounds.height
        
        return UIBezierPath(roundedRect: CGRect(x: bounds.midX - width / 2,
                                                y: bounds.midY - height / 2,
                                                width: width,
                                                height: height),
                            cornerRadius: height / 2)
    }
    
    func animForLoading(from oldProgress: Float) -> CAAnimationGroup {
        let group = CAAnimationGroup()
        
        let shapeAnim = CABasicAnimation(keyPath: "path")
        shapeAnim.fromValue = loadingShape(for: oldProgress).cgPath
        shapeAnim.toValue = loadingShape(for: progress).cgPath
        
        let colorAnim = CABasicAnimation(keyPath: "fillColor")
        colorAnim.fromValue = oldProgress == 1 ? completionColor.cgColor : frontColor.cgColor
        colorAnim.toValue = progress == 1 ? completionColor.cgColor : frontColor.cgColor
        
        group.animations = [shapeAnim, colorAnim]
        group.isRemovedOnCompletion = false
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        group.fillMode = kCAFillModeForwards
        group.duration = fullAnimationDuration * Double(abs(progress - oldProgress))
        group.delegate = self
        
        return group
    }
    
    func contentLayerColor(for state: State) -> UIColor {
        switch state {
        case .start, .inProgress:
            return backColor
        case .end:
            return completionColor
        }
    }
    
    func animForContentLayer(for oldState: State) -> CAAnimationGroup {
        let group = CAAnimationGroup()
        let shapeAnim = CABasicAnimation(keyPath: "path")
        shapeAnim.fromValue = contentShape(for: oldState).cgPath
        shapeAnim.toValue = contentShape(for: state).cgPath
        
        let colorAnim = CABasicAnimation(keyPath: "fillColor")
        colorAnim.fromValue = contentLayerColor(for: oldState).cgColor
        colorAnim.toValue = contentLayerColor(for: state).cgColor
        group.animations = [shapeAnim, colorAnim]
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        group.isRemovedOnCompletion = false
        group.fillMode = kCAFillModeForwards
        group.duration = fullAnimationDuration / 2
        group.delegate = self
        
        return group
    }
}

extension LoadStatusView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            if !animationQueue.isEmpty {
                animationQueue.removeFirst()()
            }
        }
    }
}
