//
//  GameOver.m
//  Peep Attack
//
//  Created by Student on 4/18/14.
//  Copyright (c) 2014 Corey Flickinger. All rights reserved.
//

#import "GameOver.h"
#import "MyScene.h"

@implementation GameOver
-(id)initWithSize:(CGSize)size
{
        if((self = [super initWithSize:size] ))
    {
        SKSpriteNode *bg =[SKSpriteNode spriteNodeWithImageNamed:@"lose"];
        bg.position = CGPointMake(self.size.width/2,self.size.height/2);
        [self addChild:bg];
        [self runAction:[SKAction sequence:@[
                                             [SKAction waitForDuration:0.1],
                                             [SKAction playSoundFileNamed:@"bird.mp3"
                                                        waitForCompletion:NO]]]
         ];
    }
    return self;
}
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent*)event
{
    MyScene *myScene = [[MyScene alloc]initWithSize:self.size];
    SKTransition *reveal = [SKTransition doorwayWithDuration:0.5];
    [self.view presentScene:myScene transition:reveal];
}

@end
