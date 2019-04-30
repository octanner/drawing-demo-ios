//
//  Obstacle.swift
//  sketchy-racer
//
//  Created by Derik Flanary on 4/29/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import SpriteKit

class Obstacle: SKSpriteNode {
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = CategoryMask.badGuy.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func respawnIfNeeded(with playerPosition: CGPoint) {
        guard position.x < playerPosition.x - 1000 else { return }
        respawn(basedOn: playerPosition)
    }
    
    func respawn(basedOn playerPosition: CGPoint) {
        position.x = playerPosition.x + CGFloat.random(in: 1000...2000)
        position.y = playerPosition.y + CGFloat.random(in: -400...400)
    }
    
}
