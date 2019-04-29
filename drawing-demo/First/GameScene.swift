//
//  GameScene.swift
//  sketchy-racer
//
//  Created by Derik Flanary on 4/25/19.
//  Copyright © 2019 Derik Flanary. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    // MARK: - Properties
    
    private var label : SKLabelNode?
    private var lineNode : Line?
    private let playerCamera = SKCameraNode()
    private var previousLocation: CGPoint?
    private var startingPosition: CGPoint = CGPoint.zero
    private var shouldApplyImpulse = false
    private var boostLabel: UILabel?
    private var distanceLabel: UILabel?
    private var emitter: Spark?
    private var gapNode: Gap?
    private var shouldTapToStart = true
    private var obstacles = [Obstacle]()
    
    
    // MARK: - Computed properties
    
    private var score: Int {
        guard let player = player else { return 0 }
        return Int(player.position.x - startingPosition.x) / 100
    }
    private var highScore: Int {
        return UserDefaults.standard.value(forKey: Keys.highScore) as? Int ?? 0
    }
    private var player: Player? {
        return childNode(withName: Keys.player) as? Player
    }
    private var highScoreLabel: SKLabelNode? {
        return childNode(withName: Keys.Names.highScoreLabel) as? SKLabelNode
    }
    private var tapToStartLabel: SKLabelNode? {
        return childNode(withName: Keys.Names.tapToStart) as? SKLabelNode
    }
    
    
    // MARK: - Setup
    
    override func didMove(to view: SKView) {
        boostLabel = UILabel(frame: CGRect(x: view.frame.width - 150, y: 40, width: 100, height: 40))
        guard let boostLabel = boostLabel else { return }
        boostLabel.font = UIFont.systemFont(ofSize: 21, weight: .semibold)
        boostLabel.textColor = .red
        view.addSubview(boostLabel)
        updateBoostLabel()
        
        distanceLabel = UILabel(frame: CGRect(x: 40, y: 40, width: 300, height: 40))
        guard let distanceLabel = distanceLabel else { return }
        distanceLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        view.addSubview(distanceLabel)
        
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        view.addInteraction(pencilInteraction)
        
        physicsWorld.contactDelegate = self
        camera = playerCamera
        playerCamera.position.y = self.frame.maxY / 2
        updateHighScore()
        let fadeInOutAction = SKAction.sequence([SKAction.fadeOut(withDuration: 1.0), SKAction.fadeIn(withDuration: 1.0)])
        tapToStartLabel?.run(SKAction.repeatForever(fadeInOutAction))
        
        if let player = player {
            player.position = CGPoint(x: frame.minX + frame.size.width / 4, y: 1000)
            startingPosition = player.position
            player.configurePhysicsBody()
            
            emitter = Spark(fileNamed: Spark.fileName)
            guard let emitter = emitter else { return }
            emitter.configure()
            addChild(emitter)
            
        }
        
        gapNode = Gap(color: .black, size: CGSize(width: 500, height: size.height * 2))
        if let gapNode = gapNode {
            gapNode.configure(with: position)
            addChild(gapNode)
        }
    }
    
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            switch touch.type {
            case .pencil:
                draw(at: touch)
            case .direct, .indirect:
                if shouldTapToStart {
                    shouldTapToStart = false
                    startGame()
                }
            @unknown default:
                print("unknown touch error")
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            switch touch.type {
            case .pencil:
                draw(at: touch)
            case .direct, .indirect:
                break
            @unknown default:
                print("unknown touch error")
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            switch touch.type {
            case .pencil:
                draw(at: touch)
            case .direct, .indirect:
                break
            @unknown default:
                print("unknown touch error")
            }
        }
        previousLocation = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            switch touch.type {
            case .pencil:
                draw(at: touch)
            case .direct, .indirect:
                break
            @unknown default:
                print("unknown touch error")
            }
        }
    }
    
    
    // MARK: - Frame update
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        updateDistanceLabel()
        if let player = player {
            applyImpulseToPlayer()
            
            playerCamera.position.x = player.position.x + frame.width / 4
            
            if let emitter = emitter {
                emitter.updatePosition(with: player.position)
            }
            if player.position.y < -300 {
                reset()
            }
            updateGap()
            updateObstacles()
        }
    }
    
}


// MARK: - Private functions

private extension GameScene {
    
    func startGame() {
        guard let player = player else { return }
        player.physicsBody?.isDynamic = true
        emitter?.isHidden = false
        highScoreLabel?.run(SKAction.scale(to: 0, duration: 0.25))
        tapToStartLabel?.run(SKAction.scale(to: 0, duration: 0.25))
    }
    
    func reset() {
        guard let player = player else { return }
        updateHighScore()
        player.position = startingPosition
        gapNode?.configure(with: position)
        for obstacle in obstacles {
            obstacle.removeFromParent()
        }
        obstacles.removeAll()
        
        updateBoostLabel()
        player.reset()
        shouldTapToStart = true
        emitter?.isHidden = true
        highScoreLabel?.run(SKAction.scale(to: 1.0, duration: 0.25))
        tapToStartLabel?.run(SKAction.scale(to: 1.0, duration: 0.25))

    }

    func boostActivated() {
        guard let player = player  else { return }
        player.boost()
        emitter?.runBoostAnimation()
        updateBoostLabel()
    }
    
    func updateBoostLabel() {
        guard let player = player else { return }
        boostLabel?.text = "Boosts: \(player.boostCount)"
    }
    
    func updateDistanceLabel() {
        distanceLabel?.text = "Score: \(score)"
    }
    
    func updateGap() {
        guard let gapNode = gapNode, let player = player else { return }
        gapNode.respawnIfNeeded(with: player.position)
    }
    
    func applyImpulseToPlayer() {
        guard !shouldTapToStart, shouldApplyImpulse else { return }
        player?.applyImpulse()
    }
    
    func updateObstacles() {
        guard let player = player, !shouldTapToStart else { return }
        let numberOfObstacles = (score / 100) + 1
        if obstacles.count < numberOfObstacles {
            let obstacle = Obstacle(texture: SKTexture(imageNamed: "bokeh"), color: .red, size: CGSize(width: 80, height: 80))
            addChild(obstacle)
            obstacle.respawn(basedOn: player.position)
            obstacles.append(obstacle)
        }
        for obstacle in obstacles {
            obstacle.respawnIfNeeded(with: player.position)
            
        }
    }
    
    func updateHighScore() {
        if score > highScore {
            UserDefaults.standard.set(score, forKey: Keys.highScore)
        }
        highScoreLabel?.text = "High Score: \(highScore)"
    }
    
    func draw(at touch: UITouch) {
        guard !shouldTapToStart else { return }

        let location = touch.location(in: self)
        guard shouldDraw(at: location) else {
            previousLocation = nil
            return
        }
            
        let path = CGMutablePath()
        path.move(to: previousLocation ?? touch.previousLocation(in: self))
        path.addLine(to: location)
        path.closeSubpath()
        let line = Line(path: path)
        line.configure(with: path, force: touch.force)
        addChild(line)
        previousLocation = location
    }

    func shouldDraw(at location: CGPoint) -> Bool {
        for node in nodes(at: location) {
            if node.name == gapNode?.name {
                return false
            }
        }
        return true
    }
    
}


// MARK: - Contact delegate

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let player = player else { return }
        if contact.bodyA.node == player || contact.bodyB.node == player {
            shouldApplyImpulse = true
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        guard let player = player else { return }
        if contact.bodyA.node == player || contact.bodyB.node == player {
            shouldApplyImpulse = false
        }

    }
}


// MARK: - Pencil delegate

extension GameScene: UIPencilInteractionDelegate {
    
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        boostActivated()
    }
    
}
