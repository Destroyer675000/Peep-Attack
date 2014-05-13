//
//  MyScene.m
//  Peep Attack
//
//  Created by Student on 4/9/14.
//  Copyright (c) 2014 Corey Flickinger. All rights reserved.
//

#import "MyScene.h"
#import <CoreMotion/CoreMotion.h>
#import "GameOver.h"
@import AVFoundation;

NSString *const kEnemyPeep_Yellow = @"peep-yellow.png";
NSString *const kEnemyPeep_Green = @"peep-green.png";
NSString *const kEnemyPeep_Blue = @"peep-blue.png";
NSString *const kPlayer=@"test.png";
NSString *const kBackground = @"game.png";
NSString *const kbullet1=@"bullet-1.png";
NSString *const kbullet2=@"bullet-2.png";

static uint32_t const kCategoryBullet = 1;
static uint32_t const kCategoryEnemy = 2;
static uint32_t const kCategoryPlayer = 4;

typedef enum {
    kDrawingOrderPlayer,
    kDrawingOrderBullet
}kDrawingOrder;

static int const enemy1Counter = 1;
static int const enemy2Counter = 2;
static int const enemy3Counter = 3;

static float const kMinFPS = 12.0;
static float const kMaxFPS = 60.0;
static float const kMaxPlaneSpeed = 750.0; // per second
static float const kXYdeadZone = 0.05;
static float const kPitchFudgeFactor = 0.60; // tilted roughly 45 degrees

@implementation MyScene{
    CGFloat _screenHeight;
    CGFloat _screenWidth;
    
    CMMotionManager *_motionManager;
    double _accelX;
    double _accelY;
    double _lastTime;
    double _timeSinceLastSecondWentBy;
    SKSpriteNode *_player;
    SKSpriteNode *_bullet;
	
	int _lives;
    CGFloat _score;
    CGFloat enemyScore;
	BOOL _gameOver;
    int counter;
    
    AVAudioPlayer *_backgroundPlayer;
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        [self setup];
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.accelerometerUpdateInterval = .2;
        SKSpriteNode * bg = [SKSpriteNode spriteNodeWithImageNamed:kBackground];
        bg.position = CGPointMake(self.size.width/2, self.size.height/2);
        [self addChild:bg];
        [self startMonitoringAccel];
		[self setupUI];
        
        //making a holder for both lives to be used later
		_lives=5;
		_gameOver=NO;
        [self playbgMusic:@"DST-2ndBallad.mp3"];
    }
    return self;
}
//Setting up both score and live display for the player
-(void)setupUI
{
    SKLabelNode *scoreLabel;
    scoreLabel= [SKLabelNode labelNodeWithFontNamed:@"Loaded"];
    scoreLabel.fontSize= 25.0;
    scoreLabel.fontColor = [SKColor colorWithRed:0.5 green:1 blue:0 alpha:1.0];
    scoreLabel.text = @"Score:0";
    scoreLabel.name = @"scoreLabel";
    scoreLabel.verticalAlignmentMode =SKLabelVerticalAlignmentModeCenter;
    scoreLabel.position = CGPointMake(self.size.width/2, self.size.height-scoreLabel.frame.size.height +10);
    [self addChild:scoreLabel];
    
    SKLabelNode *livesLabel=[SKLabelNode labelNodeWithFontNamed:@"loaded"];
    //livesLabel.fontName = @"loaded.tff";
    livesLabel.fontSize = 25.0;
    livesLabel.fontColor= [SKColor colorWithRed:0.5 green:1 blue:0 alpha:1.0];
    livesLabel.text = @"Lives:5";
    livesLabel.name =@"livesLabel";
    livesLabel.verticalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    livesLabel.position = CGPointMake(self.size.width-livesLabel.frame.size.height-30,self.size.height-livesLabel.frame.size.height+10);
    [self addChild:livesLabel];
    
}
- (void)startMonitoringAccel{
    
    if (_motionManager.accelerometerAvailable) {
        // this is a named block - think of it like a JS function pointer
        void (^myblock)(CMAccelerometerData*, NSError*) =^(CMAccelerometerData *accelerometerData, NSError *error) {
            [self captureAccelData:accelerometerData.acceleration];
            if(error)
            {
               // NSLog(@"%@", error);
            }
        };
        [_motionManager startAccelerometerUpdatesToQueue:
         [NSOperationQueue currentQueue]
                                             withHandler: myblock];
        
        //NSLog(@"accelerometer updates on...");
    }
    
}

-(void)captureAccelData:(CMAcceleration)acceleration{
    
    //NSLog(@"x=%f, y=%f, z=%f",acceleration.x,acceleration.y,acceleration.z);
    _accelX = acceleration.x;
    _accelY = acceleration.y + kPitchFudgeFactor; // 45 degree angle away from face goes from -0.6 to 0.0
    if (fabs(_accelX) <= kXYdeadZone) _accelX = 0.0;
    if (fabs(_accelY) <= kXYdeadZone) _accelY = 0.0;
    /*
     Our max _accelY is 0.6
     Our min _accelY is -0.4
     Which means we move up the screen faster than we can move down it
     But that works OK here
     */
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    //creating bullets and adding a phsyicsBody before adding putting it on the stage. Also playing a sound when they are created.
    for (UITouch *touch in touches) {
        CGPoint location = _player.position;
        SKSpriteNode *bullet = [SKSpriteNode spriteNodeWithImageNamed: kbullet1];
        bullet.position = CGPointMake(location.x,location.y+_player.size.height/2);
        bullet.zPosition = kDrawingOrderBullet;
        bullet.scale = 0.8;
        bullet.name = @"bullet";
        
        SKTexture *bullet1 = [SKTexture textureWithImageNamed:kbullet1];
        SKTexture *bullet2 = [SKTexture textureWithImageNamed:kbullet2];
        SKAction *pulse = [SKAction animateWithTextures:@[bullet1,bullet2] timePerFrame:0.1];
        SKAction *repeat = [SKAction repeatActionForever:pulse];
        [bullet runAction:repeat];
        
        SKAction *action = [SKAction moveToY:self.frame.size.height+bullet.size.height duration:2];
        SKAction *remove = [SKAction removeFromParent];
        [bullet runAction:[SKAction sequence:@[action,remove]]];
        bullet.physicsBody = [SKPhysicsBody
                              bodyWithRectangleOfSize:bullet.size];
        bullet.physicsBody.dynamic = NO;
        bullet.physicsBody.categoryBitMask = kCategoryBullet;
        // look for collisions again enemy planes
        bullet.physicsBody.contactTestBitMask = kCategoryEnemy;
        bullet.physicsBody.collisionBitMask = 0;

        [self addChild:bullet];
        [self runAction:[SKAction sequence:@[
                                             [SKAction waitForDuration:0.1],
                                             [SKAction playSoundFileNamed:@"ray.mp3"
                                                        waitForCompletion:NO]]]
         ];


    }
}

-(void)update:(CFTimeInterval)currentTime {
    double time = (double)CFAbsoluteTimeGetCurrent();
    
    // NSLog(@"time=%f",time);
    float dt = time - _lastTime;
    _lastTime = time;
    // NSLog(@"delta=%f",dt);
    _timeSinceLastSecondWentBy += dt;
  
    if(_timeSinceLastSecondWentBy > 1)
    {
        _timeSinceLastSecondWentBy = 0;
        
        // do something once a second here
        [self spawnEnemy];
        
    }
    
    dt = MAX(dt, 1.0 / kMaxFPS); // don't go over 60 FPS
    dt = MIN(dt, 1.0 / kMinFPS); // don't go under 12 FPS
    
    // NSLog(@"adjusted delta=%f",dt);
    
    float maxY = _screenHeight - _player.size.height/2;
    float minY = _player.size.height/2;
    float maxX = _screenWidth - _player.size.width/2;
    float minX = _player.size.width/2;
    float newX = kMaxPlaneSpeed * _accelX * dt;
    float newY = kMaxPlaneSpeed * (_accelY ) * dt;
    
    newX = MIN(MAX(newX+_player.position.x,minX),maxX);
    newY = MIN(MAX(newY+_player.position.y,minY),maxY);
    
    _player.position = CGPointMake(newX, newY);
    
       //[self checkCollisions];
   //checking to see if the lives counter is zero and the gameover boolean. If the statement is true it goes to the game over screen and stops the music.
	   if(_lives<=0 && !_gameOver)
	   {
		 _gameOver = YES;
           [_backgroundPlayer stop];
           //NSLog(@"go to lose screen");
           SKScene *gameOver = [[GameOver alloc]initWithSize:self.size];
           SKTransition *reveal =[SKTransition flipHorizontalWithDuration:0.5];
           [self.view presentScene:gameOver transition:reveal];
	   }
    }

-(void)setup
{
    //creating the player and adding physicsbody to him
    CGRect screenRect = self.scene.frame;
    _screenHeight = screenRect.size.height;
    _screenWidth = screenRect.size.width;
    
    _player =[SKSpriteNode spriteNodeWithImageNamed:kPlayer];
    _player.position = CGPointMake(_screenWidth/2, _player.size.height/2);
    _player.scale = 2;
    _player.zPosition = 2;
    _player.physicsBody = [SKPhysicsBody
                          bodyWithRectangleOfSize:_player.size];
    _player.physicsBody.dynamic = NO;
    _player.physicsBody.categoryBitMask = kCategoryPlayer;
    // look for collisions again enemy planes
    _player.physicsBody.contactTestBitMask = kCategoryEnemy;
    _player.physicsBody.collisionBitMask = 0;

    [self addChild: _player];
    
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    self.physicsWorld.contactDelegate = self;
}


-(void)spawnEnemy
{
    //creating an three random types of enemies and making them spawn at different position when they are created
    //change their score, hitcounter, and size depending on which one they are.
    int enemyPos;
    int enemypick;
    enemypick =enemyPos = [self getRandomIntBetween:0 to:4];
    SKSpriteNode *enemy;
    switch(enemypick)
    {
        case 1:
        case 2:
        enemy=[SKSpriteNode spriteNodeWithImageNamed:kEnemyPeep_Yellow];
        counter = 1;
        enemy.name =@"peep";
            enemy.scale=.5;
        enemyScore = 10;
        break;
        
        
        case 3:
        enemy=[SKSpriteNode spriteNodeWithImageNamed:kEnemyPeep_Green];
        enemy.scale= .75;
        counter = 3;
        enemy.name =@"car";
        enemyScore = 20;
        break;
            
        default:
            enemy=[SKSpriteNode spriteNodeWithImageNamed:kEnemyPeep_Blue];
            counter = 5;
            enemyScore =50;
            break;
    }
    
   // NSLog(@"%d",counter);
    switch (enemyPos) {
        case 0:
            enemy.position = CGPointMake(_screenWidth/5,_screenHeight);
            break;
         case 1:
            enemy.position = CGPointMake(_screenWidth/4,_screenHeight);
            break;
        case 2:
            enemy.position = CGPointMake(_screenWidth/3,_screenHeight);
            break;
        case 3:
            enemy.position = CGPointMake(_screenWidth/2,_screenHeight);;
            break;
        default:
             enemy.position = CGPointMake(_screenWidth*.9,_screenHeight);
            break;
    }
    //Counter and score they hold being set here
    if([enemy.name isEqual: @"peep"])
    {
        counter = 1;
        enemyScore = 10;
    }
    else if([enemy.name isEqual: @"car"])
    {
        counter = 2;
        enemyScore =20;
    }
//making the enemy on screen and giving them a physicsbody
    enemy.zPosition=1;

    CGMutablePathRef cgpath =CGPathCreateMutable();
    
    enemy.physicsBody = [SKPhysicsBody
                         bodyWithRectangleOfSize:enemy.size];
    enemy.physicsBody.dynamic = YES;
    enemy.physicsBody.categoryBitMask = kCategoryEnemy;
    enemy.physicsBody.contactTestBitMask = kCategoryBullet;
    enemy.physicsBody.collisionBitMask = 0;
    NSString *firePath = [[NSBundle mainBundle]pathForResource:@"magic" ofType:@"sks"];
    SKEmitterNode *burn = [NSKeyedUnarchiver unarchiveObjectWithFile:firePath];
    burn.position = CGPointMake(0,enemy.size.height);

    [self addChild:enemy];
    [enemy addChild:burn];
    SKAction *actionMove = [SKAction moveToY: -enemy.size.height/2 duration:2.5];
    SKAction *actionRemove = [SKAction removeFromParent];
    [enemy runAction:[SKAction sequence:@[actionMove,actionRemove]]];
    CGPathRelease(cgpath);
}

//creating random numbers
-(int)getRandomIntBetween:(int)from to:(int)to {
    return (int)(from + arc4random_uniform(to - from + 1));
}
#pragma mark SKPhysicsContactDelegate methods
-(void)didBeginContact:(SKPhysicsContact *)contact{
   // NSLog(@"contact=%@",contact);
    // Handle contacts between two physics bodies.
    // Contacts are often a double dispatch problem; the effect you want
    // is based
    // on the type of both bodies in the contact. This sample solves
    // this in a brute force way, by checking the types of each. A more
    //complicated
    // example might use methods on objects to perform the type checking.
    
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    // The contacts can appear in either order, and so normally you'd need to
    // check
    // each against the other. In this example, the category types are well
    // ordered, so
    // the code swaps the two bodies if they are out of order. This allows
    // the code
    // to only test collisions once.
    
    if(contact.bodyA.categoryBitMask & kCategoryBullet){
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else{
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    //NSLog(@"firstBody.node.name=%@",firstBody.node.name);
   // NSLog(@"secondBody.node.name=%@",secondBody.node.name);
    // if firstBody is a bullet
    if ((firstBody.categoryBitMask & kCategoryBullet) != 0){
        // get projectile node from matching physicsBody
        SKNode *projectile = (contact.bodyA.categoryBitMask &
                              kCategoryBullet) ? contact.bodyA.node : contact.bodyB.node;
        
        // get enemy node from matching physicsBody
        SKNode *enemy = (contact.bodyA.categoryBitMask &
                         kCategoryEnemy) ? contact.bodyA.node : contact.bodyB.node;
        counter --;
            //remove projectile and enemy from screen
        [projectile runAction:[SKAction removeFromParent]];
        
    if(counter==0)
        {
            [enemy runAction:[SKAction removeFromParent]];
            [self increaseScoreBy:enemyScore];
        
//            if(enemy == @"peep")
//            {
//                counter = enemy1Counter;
//            }
//            else
//            {
//                counter = enemy2Counter;
//            }
        }
        //NSLog(@"%d",counter);
        
        
    }
    if(contact.bodyA.categoryBitMask & kCategoryBullet){
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else{
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    //NSLog(@"firstBody.node.name=%@",firstBody.node.name);
   // NSLog(@"secondBody.node.name=%@",secondBody.node.name);
    // if firstBody is a bullet
    if ((firstBody.categoryBitMask & kCategoryEnemy) != 0){
        // get projectile node from matching physicsBody
        SKNode *enemyAction = (contact.bodyA.categoryBitMask &
                              kCategoryEnemy) ? contact.bodyA.node : contact.bodyB.node;
        
        // get enemy node from matching physicsBody
        SKNode *player= (contact.bodyA.categoryBitMask &
                         kCategoryPlayer) ? contact.bodyA.node : contact.bodyB.node;
        counter --;
        //remove projectile and enemy from screen
        [enemyAction runAction:[SKAction removeFromParent]];
        [self subtractLives];
        
        
        //NSLog(@"%d",counter);
        
        if(_lives==0)
        {
                       // NSLog(@"%d",_lives);
            [player removeFromParent];
        }
        
    }

    
}
//Funciton to subtracts lives from my life counter and displaying that in the life label.
-(void)subtractLives
{
    _lives--;
    SKLabelNode *life=(SKLabelNode *)[self childNodeWithName:@"livesLabel"];
    life.text = [NSString stringWithFormat:@"Lives:%d",_lives];
}
//same thing as subtractLives but adding a score to the scoreLabel so the player can see their score
-(void)increaseScoreBy:(float)increment
{
    _score +=increment;
    SKLabelNode *scoreLabel =(SKLabelNode *)[self childNodeWithName:@"scoreLabel"];
    scoreLabel.text = [NSString stringWithFormat:@"Score: %1.0f",_score];

}
//creating the background music for the game
-(void)playbgMusic:(NSString *)filename
{
    NSError *error;
    NSURL *backgroundURL=[[NSBundle mainBundle]URLForResource:filename withExtension:nil];
    _backgroundPlayer= [[AVAudioPlayer alloc]initWithContentsOfURL:backgroundURL error:&error];
    _backgroundPlayer.numberOfLoops =-1;
    [_backgroundPlayer prepareToPlay];
    [_backgroundPlayer play];
}

//-(void)checkCollisions
//{
//    
//    [self enumerateChildNodesWithName:@"peep"
//                           usingBlock:^(SKNode *node,BOOL *stop)
//     {
//         SKSpriteNode *enemy = (SKSpriteNode *)node;
//         if(CGRectIntersectsRect(enemy.frame, _player.frame))
//         {
//             [enemy removeFromParent];
//             [_player removeFromParent];
//             _lives--;
//             NSLog(@"%d",_lives);
//         }
//     }];
//}
@end
