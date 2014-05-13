//
//  Enemy.h
//  Peep Attack
//
//  Created by Student on 4/20/14.
//  Copyright (c) 2014 Corey Flickinger. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Enemy : SKSpriteNode

@property (assign, nonatomic)int hitCounter;
@property (assign, nonatomic)int score;

//-(id)initWithSize:(CGSize)size;
-(void)update:(CFTimeInterval)delta;

-(void)configureCollisionBody;
-(void)collidedWith:(SKPhysicsBody  *)body contact:(SKPhysicsContact *)contact;
@end
