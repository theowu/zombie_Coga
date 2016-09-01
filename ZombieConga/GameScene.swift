//
//  GameScene.swift
//  ZombieConga
//
//  Created by Theo WU on 20/06/2016.
//  Copyright (c) 2016 Theo WU. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    let zombie1 = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime:NSTimeInterval = 0
    var dt:NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    var velocity = CGPoint.zero
    let playableRect: CGRect
    var lastTouchLocation: CGPoint?
    let zombieRotationRadiansPerSec: CGFloat = 4.0 * π
    let zombieAnimation: SKAction
    var zombieIsInvincible = false
    let blinkAnimation: SKAction
    
    var lives = 5
    var gameOver = false
    
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    let catColorToGreen: SKAction = SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 1.0, duration: 0.2)
    
    let catMovePointsPerSec: CGFloat = 480.0
    
    let cameraNode = SKCameraNode()
    let cameraMovePointsPerSec: CGFloat = 200.0
    
    var cameraRect: CGRect {
        return CGRect(x: getCameraPosition().x-playableRect.width/2, y: getCameraPosition().y-playableRect.height/2, width: playableRect.width, height: playableRect.height)
    }

    let livesLabel = SKLabelNode(fontNamed: "WAREHOUSE")
    let catsLabel = SKLabelNode(fontNamed: "WAREHOUSE")
    
    var priorTouch: CGPoint = CGPoint.zero
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0 // 1
        let playableHeight = size.width / maxAspectRatio // 2
        let playableMargin = (size.height - playableHeight)/2.0 // 3
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight) // 4
        
        var textures:[SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.animateWithTextures(textures, timePerFrame: 0.1)
        
        let blinkTimes = 10.0
        let blinkDuration = 3.0
        blinkAnimation = SKAction.customActionWithDuration(blinkDuration) { node, elapsedTime in
            let slice = blinkDuration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            node.hidden = remainder > slice / 2
        }
        
        super.init(size: size) // 5
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") // 6
    }
    
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        playBackgroundMusic("backgroundMusic.mp3")
        
        backgroundColor = SKColor.blackColor()
        
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = "background"
//        background.zRotation = CGFloat(M_PI)/8
            background.zPosition = -1
            addChild(background)
        }
        
        zombie1.position = CGPoint(x: 400, y: 400)
        zombie1.zPosition = 100
//        zombie1.setScale(2) //SKNode method
        addChild(zombie1)
//        zombie1.runAction(SKAction.repeatActionForever(zombieAnimation))
        runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.runBlock(spawnEnemy), SKAction.waitForDuration(2.0)])))
        runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.runBlock(spawnCat), SKAction.waitForDuration(1.0)])))
        
        
//             Gesture recognizer example
//            let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleTap:"))
//            view.addGestureRecognizer(tapRecognizer)
        
//        debugDrawPlayableArea()
        
        addChild(cameraNode)
        camera = cameraNode
        setCameraPosition(CGPoint(x: size.width/2, y: size.height/2))
        
        livesLabel.text = "Lives: \(lives)"
        livesLabel.fontColor = SKColor.blackColor()
        livesLabel.fontSize = 100
        livesLabel.zPosition = 100
        livesLabel.horizontalAlignmentMode = .Left
        livesLabel.verticalAlignmentMode = .Bottom
        livesLabel.position = CGPoint(x: -playableRect.size.width/2+CGFloat(20), y: -playableRect.size.height/2+CGFloat(20)+overlapAmount()/2)
        cameraNode.addChild(livesLabel)
        
        catsLabel.text = "Cats: 0"
        catsLabel.fontColor = SKColor.blackColor()
        catsLabel.fontSize = 100
        catsLabel.zPosition = 100
        catsLabel.horizontalAlignmentMode = .Right
        catsLabel.verticalAlignmentMode = .Bottom
        catsLabel.position = CGPoint(x: playableRect.size.width/2-CGFloat(20), y: -playableRect.size.height/2+CGFloat(20)+overlapAmount()/2)
        cameraNode.addChild(catsLabel)
        
    }
    
    
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
//        print("\(dt*1000) millisecondes since last update")
        
//        if let destination = lastTouchLocation {
//            let delta = destination - zombie1.position
//            if delta.length() <= zombieMovePointsPerSec * CGFloat(dt) {
//                if delta.length() != 0 {
//                    rotateSprite(zombie1, direction: velocity, rotateRadiansPerSec: zombieRotationRadiansPerSec)
//                    zombie1.position = destination
//                }
//                velocity = CGPoint.zero
//                stopZombieAnimation()
//            } else {
//                moveSprite(zombie1, velocity: velocity)
//                rotateSprite(zombie1, direction: velocity, rotateRadiansPerSec: zombieRotationRadiansPerSec)
//            }
//        }
        
        moveSprite(zombie1, velocity: velocity)
        rotateSprite(zombie1, direction: velocity, rotateRadiansPerSec: zombieRotationRadiansPerSec)
        
        boundsCheckZombie()
        
        moveTrain()
        
        
        
        moveCamera()
        
        if lives <= 0 && !gameOver {
            gameOver = true
            backgroundMusicPlayer.stop()
            print("You lose!")
            
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
    }
    
    
    
    override func didEvaluateActions() {
        ckeckCollisions()
    }
    
    
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        // 1
        let amountToMove = velocity * CGFloat(dt)
//        print("Amount to move: \(amountToMove)")
        // 2
        sprite.position += amountToMove
    }
    
    
    
    func moveZombieToward(location: CGPoint) {
        startZombieAnimation()
        let offset = location - zombie1.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
    }
    
    
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(sprite.zRotation, angle2: direction.angle)
        let amtToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += amtToRotate * shortest.sign()
    }
    
    
    
    func sceneTouched(touchLocation:CGPoint) {
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
    }
    
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        #if os (tvOS)
            priorTouch = touchLocation
        #else
            sceneTouched(touchLocation)
        #endif
    }
    
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.locationInNode(self)
        #if os (tvOS)
            let offset = touchLocation - priorTouch
            let direction = offset.normalized()
            velocity = direction*zombieMovePointsPerSec
            
            priorTouch = (priorTouch*0.75)+(touchLocation*0.25)
            
        #else
            sceneTouched(touchLocation)
        #endif
    }
    
    //  func handleTap(recognizer:UIGestureRecognizer) {
    //    let viewLocation = recognizer.locationInView(self.view)
    //    let touchLocation = convertPointFromView(viewLocation)
    //    sceneTouched(touchLocation)
    //  }
    
    
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: CGRectGetMinX(cameraRect), y: CGRectGetMinY(cameraRect))
        let topRight = CGPoint(x: CGRectGetMaxX(cameraRect), y: CGRectGetMaxY(cameraRect))
        
        if zombie1.position.x <= bottomLeft.x {
            zombie1.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie1.position.x >= topRight.x {
            zombie1.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie1.position.y <= bottomLeft.y {
            zombie1.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie1.position.y >= topRight.y {
            zombie1.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, playableRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
    }

    
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        enemy.position = CGPoint(x: CGRectGetMaxX(cameraRect) + enemy.size.width/2, y: CGFloat.random(min: CGRectGetMinY(cameraRect) + enemy.size.height/2, max: CGRectGetMaxY(cameraRect) - enemy.size.height/2))
        enemy.zPosition = 50
        addChild(enemy)
        
        let actionMove = SKAction.moveToX(CGRectGetMinX(cameraRect)-enemy.size.width/2, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
        
////        let actionMidMove = SKAction.moveTo(CGPoint(x: size.width/2, y:CGRectGetMinY(playableRect) + enemy.size.height/2), duration: 4.0)
////        let actionMove = SKAction.moveTo(CGPoint(x: -enemy.size.width/2, y: enemy.position.y), duration: 4.0)
//        let actionMidMove = SKAction.moveByX(-size.width/2, y: enemy.size.height/2 - CGRectGetHeight(playableRect)/2, duration: 2.0)
//        let actionMove = SKAction.moveByX(-size.width/2 - enemy.size.width/2, y: CGRectGetHeight(playableRect)/2 - enemy.size.height/2, duration: 2.0)
////        let reverseMidMove = actionMidMove.reversedAction()
////        let reverseMove = actionMove.reversedAction()
//        let wait = SKAction.waitForDuration(1)
//        let logMessage = SKAction.runBlock() {
//            print("Reached bottom!")
//        }
//        let halfSequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
//        let sequence = SKAction.sequence([halfSequence, halfSequence.reversedAction()])
//        let repeatAction = SKAction.repeatActionForever(sequence)
//        enemy.runAction(repeatAction)
        
    }
    
    
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        cat.position = CGPoint(x: CGFloat.random(min: CGRectGetMinX(cameraRect), max: CGRectGetMaxX(cameraRect)), y: CGFloat.random(min: CGRectGetMinY(cameraRect), max: CGRectGetMaxY(cameraRect)))
        cat.zPosition = 50
        cat.setScale(0)
        addChild(cat)
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
        
//        let wait = SKAction.waitForDuration(10.0)
        cat.zRotation = -π/16.0
        let leftWiggle = SKAction.rotateByAngle(π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        
        let scaleUp = SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence([scaleUp, scaleDown])
        let group = SKAction.group([fullWiggle, fullScale])
        let groupWait = SKAction.repeatAction(group, count: 10)
        
//        let wiggleWait = SKAction.repeatAction(fullWiggle, count: 10)
        
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.runAction(SKAction.sequence(actions))
    }
    
    
    
    func startZombieAnimation() {
        if zombie1.actionForKey("animation") == nil {
            zombie1.runAction(SKAction.repeatActionForever(zombieAnimation), withKey: "animation")
        }
    }
    
    
    
    func stopZombieAnimation() {
        zombie1.removeActionForKey("animation")
    }
    
    
    
    func moveTrain() {
        var trainCount = 0
        
        var targetPosition = zombie1.position
        
        enumerateChildNodesWithName("train") { node, _ in
            trainCount += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)
                let moveAction = SKAction.moveByX(amountToMove.x, y: amountToMove.y, duration: actionDuration)
                node.runAction(moveAction)
            }
            targetPosition = node.position
        }
        
        if trainCount >= 15 && !gameOver {
            gameOver = true
            print("You win!")
            backgroundMusicPlayer.stop()
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        
        catsLabel.text = "Cats: \(trainCount)"
    }
    
    
    
    func zombieHitCat(cat: SKSpriteNode) {
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1)
        cat.zRotation = 0
        
        runAction(catCollisionSound)
        cat.runAction(catColorToGreen)
    }
    
    
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
//        enemy.removeFromParent()
        zombieIsInvincible = true
        runAction(enemyCollisionSound)
        let block = SKAction.runBlock() {
            self.zombie1.hidden = false
            self.zombieIsInvincible = false
        }
        zombie1.runAction(SKAction.sequence([blinkAnimation, block]))
        
        loseCats()
        lives -= 1
        livesLabel.text = "Lives: \(lives)"
    }
    
    
    
    func ckeckCollisions() {
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodesWithName("cat") { node, _ in
            let cat = node as! SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie1.frame) {
                hitCats.append(cat)
            }
        }
        for cat in hitCats {
            zombieHitCat(cat)
        }
        
        if !zombieIsInvincible {
            var hitEnemies: [SKSpriteNode] = []
            enumerateChildNodesWithName("enemy") { node, _ in
                let enemy = node as! SKSpriteNode
                if CGRectIntersectsRect(enemy.frame, self.zombie1.frame) {
                    hitEnemies.append(enemy)
                }
            }
            for enemy in hitEnemies {
                zombieHitEnemy(enemy)
            }
        } else {
            return
        }
    }
    
    
    
    func loseCats() {
        var loseCount = 0
        enumerateChildNodesWithName("train") { node, stop in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            node.name = ""
            node.runAction(
            SKAction.sequence([
                SKAction.group([
                    SKAction.rotateByAngle(4*π, duration: 1.0),
                    SKAction.moveTo(randomSpot, duration: 1.0),
                    SKAction.scaleTo(0, duration: 1.0)]),
                SKAction.removeFromParent()
                ]))
            loseCount += 1
            if loseCount >= 2 {
                stop.memory = true
            }
        }
    }
    
    
    
    func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        
        backgroundNode.size = CGSize(width: background1.size.width+background2.size.width, height: background1.size.height)
        return backgroundNode
    }
    
    func moveCamera() {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
        
        enumerateChildNodesWithName("background") { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width < self.cameraRect.origin.x {
                background.position.x += background.size.width*2
            }
        }
    }
    

    
    
    
    
    
    func overlapAmount() -> CGFloat {
        guard let view = self.view else {
            return 0
        }
        let scale = view.bounds.size.width/self.size.width
        let scaledHeight = self.size.height * scale
        let scaleOverlap = scaledHeight - view.bounds.size.height
        return scaleOverlap / scale
    }
    
    
    
    func getCameraPosition() -> CGPoint {
        return CGPoint(x: cameraNode.position.x, y: cameraNode.position.y + overlapAmount()/2)
    }
    
    
    
    func setCameraPosition(position: CGPoint) {
        cameraNode.position = CGPoint(x: position.x, y: position.y - overlapAmount()/2)
    }
    
    
    
}