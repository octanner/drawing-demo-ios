//
//  Gap.swift
//  sketchy-racer
//
//  Created by Derik Flanary on 4/28/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import SpriteKit

class Gap: SKSpriteNode {
    
    func configure(with parentPosition: CGPoint) {
        position = CGPoint(x: 4000, y: parentPosition.y)
        zPosition = -2
        name = Keys.Names.gap
    }
    
    func respawnIfNeeded(with playerPosition: CGPoint) {
        guard position.x < playerPosition.x - 1000 else { return }
        position.x = playerPosition.x + CGFloat.random(in: 2000...4000)
        size.width = CGFloat.random(in: 300...700)
    }
    
}
