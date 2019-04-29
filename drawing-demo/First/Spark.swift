//
//  Spark.swift
//  sketchy-racer
//
//  Created by Derik Flanary on 4/28/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import SpriteKit

class Spark: SKEmitterNode {
    
    static let fileName = "Spark.sks"
    
    func configure() {
        zPosition = -2
        isHidden = true
    }
    
    func updatePosition(with parentPosition: CGPoint) {
        position = CGPoint(x: parentPosition.x + 10, y: parentPosition.y)
    }
    
    func runBoostAnimation() {
        run(SKAction.sequence([SKAction.scale(by: 1.6, duration: 0.5), SKAction.scale(to: 1.0, duration: 1.5)]))
    }
    
}
