//
//  NodeLayer.swift
//  BEForceDirectedDemo-Swift
//
//  Created by yichi.wang on 22/05/2018.
//  Copyright © 2018 blueeee. All rights reserved.
//

import UIKit

class NodeLayer: CALayer {
    static let NodeLayerSpringAnimationKey = "NodeLayerSpringAnimationKey"
    let colors:[UIColor] = [UIColor(red: 241.0/255.0, green: 141.0/255.0, blue: 0, alpha: 1), UIColor(red: 244.0/255.0, green: 150.0/255.0, blue: 201.0/255.0, alpha: 1), UIColor(red: 255.0/255.0, green: 248.0/255.0, blue: 165.0/255.0, alpha: 1), UIColor(red: 128.0/255.0, green: 205.0/255.0, blue: 227.0/255.0, alpha: 1), UIColor(red: 236.0/255.0, green: 122.0/255.0, blue: 172.0/255.0, alpha: 1)]
    
    public func springAnimation() {
        let animation: CASpringAnimation = CASpringAnimation(keyPath: "transform.scale")
        animation.fromValue = 0.5
        animation.toValue = 3
        animation.duration = 3
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.mass = 2
        animation.damping = 5
        animation.stiffness = 200
        
        self.add(animation, forKey: NodeLayer.NodeLayerSpringAnimationKey)
    }
    
    public func randomBackgroundColor() {
        self.backgroundColor = colors[Int(arc4random()%5)].cgColor
    }
}
