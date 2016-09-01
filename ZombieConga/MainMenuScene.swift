//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Theo WU on 24/06/2016.
//  Copyright © 2016 Theo WU. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    
    override func didMoveToView(view: SKView) {
        let background = SKSpriteNode(imageNamed: "MainMenu")
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        self.addChild(background)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        let reveal = SKTransition.doorwayWithDuration(1.5)
        view?.presentScene(gameScene, transition: reveal)
    }
}