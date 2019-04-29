//
//  Player.swift
//  sketchy-racer
//
//  Created by Derik Flanary on 4/28/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import Foundation
import SpriteKit

class Player: SKSpriteNode {
    
    static let maxBoostCount = 3
    
    var boostCount = Player.maxBoostCount
    
    func configurePhysicsBody() {
        physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        physicsBody?.affectedByGravity = true
        physicsBody?.categoryBitMask = CategoryMask.car.rawValue
        physicsBody?.collisionBitMask = CategoryMask.line.rawValue
        physicsBody?.contactTestBitMask = CategoryMask.badGuy.rawValue
        physicsBody?.mass = 10
        physicsBody?.linearDamping = 0.01
        physicsBody?.isDynamic = false
    }
    
    func applyImpulse() {
        guard let playerPhysicsBody = physicsBody else { return }
        playerPhysicsBody.applyImpulse(CGVector(dx: 500, dy: 0))
        if playerPhysicsBody.velocity.dx > CGFloat(1200) {
            playerPhysicsBody.velocity.dx = 1200
        }
    }
    
    func boost() {
        guard boostCount > 0 else { return }
        physicsBody?.applyImpulse(CGVector(dx: 7000, dy: 0))
        boostCount -= 1
    }
    
    func reset() {
        physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        physicsBody?.isDynamic = false
        boostCount = Player.maxBoostCount
    }
    
}
