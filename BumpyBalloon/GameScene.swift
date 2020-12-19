//
//  GameScene.swift
//  BumpyBalloon
//
//  Created by Terry Thrasher on 2020-12-17.
//  Project 3 from Dive Into SpriteKit
//  Music: Balloon Game by Kevin MacLeod (https://incompetech.com/)

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    let player = SKSpriteNode(imageNamed: "balloon")
    let smoke = SKEmitterNode(fileNamed: "BalloonSmoke")
    
    var birds = 0
    let levelLabel = SKLabelNode(fontNamed: "Baskerville-Bold")
    var level = 0 {
        didSet {
            levelLabel.text = "LEVEL: \(level)"
        }
    }
    
    var touchingScreen = false
    var timer: Timer?
    
    let scoreLabel = SKLabelNode(fontNamed: "Baskerville-Bold")
    var score = 0 {
        didSet {
            scoreLabel.text = "SCORE: \(score)"
        }
    }
    
    let music = SKAudioNode(fileNamed: "balloon-game")
    
    override func didMove(to view: SKView) {
        player.position = CGPoint(x: -400, y: 250)
        player.physicsBody?.categoryBitMask = 1
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        addChild(player)
        
        // Challenge 2 asked me to create a new particle system attached to the player's balloon that created a wind effect.
        // I chose to make it like smoke from a hot air balloon's fire.
        smoke!.position.x = player.position.x
        smoke!.position.y = player.position.y - 40
        // By default the emitted particles follow the emitter node. However, that looked ridiculous. I discovered that I could specify a target node for the particles, and that target node could be the scene, and that would make the particles move indepent of the emitter node and its future positions.
        smoke!.targetNode = self
        addChild(smoke!)
        
        scoreLabel.fontColor = UIColor.black.withAlphaComponent(0.5)
        scoreLabel.position.x = -400
        scoreLabel.position.y = 320
        addChild(scoreLabel)
        score = 0
        
        // Challenge 3 asked me to track how many birds have been created, and every 10 birds, recreate the timer with a shorter time interval to make birds more often.
        // I decided I'd show the player a level to represent the increased number of birds.
        levelLabel.fontColor = UIColor.black.withAlphaComponent(0.5)
        levelLabel.position.x = 400
        levelLabel.position.y = 320
        addChild(levelLabel)
        level = 0
        
        addChild(music)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        
        parallaxScroll(image: "sky", y: 0, z: -3, duration: 10, needsPhysics: false)
        parallaxScroll(image: "ground", y: -340, z: -1, duration: 6, needsPhysics: true)
        
        timer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(createObstacle), userInfo: nil, repeats: true)
        
        physicsWorld.contactDelegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchingScreen = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchingScreen = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        if player.parent != nil {
            score += 1
        }
        if touchingScreen {
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 300)
        }
        if player.position.y > 300 {
            player.position.y = 300
        }
        smoke!.position.y = player.position.y - 40
    }
    
    func parallaxScroll(image: String, y: CGFloat, z: CGFloat, duration: Double, needsPhysics: Bool) {
        for i in 0 ... 1 {
            let node = SKSpriteNode(imageNamed: image)
            
            node.position = CGPoint(x: 1023 * CGFloat(i), y: y)
            node.zPosition = z
            addChild(node)
            
            if needsPhysics {
                node.physicsBody = SKPhysicsBody(texture: node.texture!, size: node.texture!.size())
                node.physicsBody?.isDynamic = false
                node.physicsBody?.contactTestBitMask = 1
                node.name = "obstacle"
            }
            
            let move = SKAction.moveBy(x: -1024, y: 0, duration: duration)
            let wrap = SKAction.moveBy(x: 1024, y: 0, duration: 0)
            let sequence = SKAction.sequence([move, wrap])
            let forever = SKAction.repeatForever(sequence)
            
            node.run(forever)
        }
    }
    
    @objc func createObstacle() {
        // Challenge 3 asked me to track how many birds have been created, and every 10 birds, recreate the timer with a shorter time interval to make birds more often.
        // The timer gets faster until it reaches 0.4 seconds, then it stops getting faster.
        birds += 1
        if birds % 10 == 0 {
            level += 1
            timer?.invalidate()
            var birdSpawn = 1.5 - (0.1 * Double(level))
            birdSpawn = max(birdSpawn, 0.4)
            timer = Timer.scheduledTimer(timeInterval: birdSpawn, target: self, selector: #selector(createObstacle), userInfo: nil, repeats: true)
        }
        
        let obstacle = SKSpriteNode(imageNamed: "enemy-bird")
        obstacle.zPosition = -2
        obstacle.position.x = 768
        addChild(obstacle)
        
        obstacle.physicsBody = SKPhysicsBody(texture: obstacle.texture!, size: obstacle.texture!.size())
        obstacle.physicsBody?.isDynamic = false
        obstacle.physicsBody?.contactTestBitMask = 1
        obstacle.name = "obstacle"
        
        obstacle.position.y = CGFloat.random(in: -300 ..< 350)
        
        let move = SKAction.moveTo(x: -768, duration: 6)
        let remove = SKAction.removeFromParent()
        let action = SKAction.sequence([move, remove])
        obstacle.run(action)
    }
    
    func playerHit(_ node: SKNode) {
        if node.name == "obstacle" {
            if let explosion = SKEmitterNode(fileNamed: "PlayerExplosion") {
                explosion.position = player.position
                addChild(explosion)
            }
            run(SKAction.playSoundFileNamed("explosion", waitForCompletion: false))
            player.removeFromParent()
            music.removeFromParent()
            smoke!.removeFromParent()
            
            // Challenge 1 asked me to show a provided game over sprite when the player dies.
            // Bonus points for animating it.
            let gameOver = SKSpriteNode(imageNamed: "game-over")
            gameOver.position = CGPoint(x: 0, y: 0)
            gameOver.zPosition = 10
            gameOver.alpha = 0
            addChild(gameOver)
            
            let fadeIn = SKAction.fadeIn(withDuration: 0.8)
            gameOver.run(fadeIn)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if let scene = GameScene(fileNamed: "GameScene") {
                    scene.scaleMode = .aspectFill
                    self.view?.presentScene(scene)
                }
            }
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player {
            playerHit(nodeB)
        } else if nodeB == player {
            playerHit(nodeA)
        }
    }
}
