//
//  Line.swift
//  sketchy-racer
//
//  Created by Derik Flanary on 4/28/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import SpriteKit

class Line: SKShapeNode {
    
    private var lineColor = UIColor.darkGray
    
    func configure(with path: CGPath, force: CGFloat) {
        lineColor.setStroke()
        lineWidth = max(force * 2, 2.0)
        run(SKAction.sequence([SKAction.wait(forDuration: 0.75),
                               SKAction.fadeOut(withDuration: 0.5),
                               SKAction.removeFromParent()]))
        strokeColor = lineColor
        physicsBody = SKPhysicsBody(edgeLoopFrom: path)
        physicsBody?.categoryBitMask = CategoryMask.line.rawValue
        physicsBody?.affectedByGravity = false
    }
    
}
