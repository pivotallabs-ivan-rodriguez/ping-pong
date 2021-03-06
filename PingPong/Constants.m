//
//  Constants.m
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "Constants.h"

@implementation Constants

//Keys
NSString * const kLeftPlayerKey = @"Left";
NSString * const kRightPlayerKey = @"Right";
NSString * const kServerKey = @"Server";
NSString * const kYourServeLeftKey = @"yourServeLeft";
NSString * const kYourServeRightKey = @"yourServeRight";
NSString * const kLastServeLeftKey = @"lastServeLeft";
NSString * const kLastServeRightKey = @"lastServeRight";

//Messages
NSString * const kPointMessage = @"point";
NSString * const kOpponentPointMessage = @"opponentPoint";
NSString * const kResetMessage = @"reset";
NSString * const kWinMessage = @"win";
NSString * const kLoseMessage = @"lose";
NSString * const kElevenMessage = @"11";
NSString * const kTwentyOneMessage = @"21";
NSString * const kMinusOneMessage = @"-1";
NSString * const kChangeStartingServerMessage = @"changeServer";

//Multipeer
NSString * const kServerServiceType = @"pingpong";

@end
