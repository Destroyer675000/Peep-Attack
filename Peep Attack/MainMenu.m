//
//  MainMenu.m
//  Peep Attack
//
//  Created by Student on 4/19/14.
//  Copyright (c) 2014 Corey Flickinger. All rights reserved.
//

#import "MainMenu.h"
#import "MyScene.h"

@implementation MainMenu
- (instancetype)initWithSize:(CGSize)size {
    if ((self = [super initWithSize:size])) {
        SKSpriteNode * bg = [SKSpriteNode spriteNodeWithImageNamed:@"MainMenu"];
        bg.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild:bg];
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    MyScene * myScene =
    [[MyScene alloc] initWithSize:self.size];
    
    SKTransition *reveal =
    [SKTransition doorwayWithDuration:0.5];
    
    [self.view presentScene:myScene transition: reveal];
}
@end
