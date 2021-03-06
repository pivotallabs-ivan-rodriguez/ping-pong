//
//  ViewController.m
//  PingPong
//
//  Created by DX169-XL on 2014-09-03.
//  Copyright (c) 2014 Pivotal. All rights reserved.
//

#import "ServerViewController.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "MultipeerManager.h"
#import "ConfettiScreen.h"

@import AVFoundation;

@interface ServerViewController () <MCBrowserViewControllerDelegate, MultipeerServerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *leftPlayerImageView;
@property (weak, nonatomic) IBOutlet UIImageView *rightPlayerImageView;
@property (weak, nonatomic) IBOutlet UILabel *leftServingLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightServingLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightScoreLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *photoProgressView;
@property (weak, nonatomic) IBOutlet UILabel *leftPlayerConnectionStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightPlayerConnectionStatusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *leftServingImageView;
@property (weak, nonatomic) IBOutlet UIImageView *rightServingImageView;
@property (weak, nonatomic) IBOutlet UILabel *pointsToWinLabel;
@property (weak, nonatomic) IBOutlet UIView *confettiView;


@property (nonatomic) NSInteger leftScore;
@property (nonatomic) NSInteger rightScore;

@property (nonatomic) NSInteger pointsToWin;
@property (nonatomic, weak) ConfettiScreen *winConfettiScreen;
@property (nonatomic, weak) ConfettiScreen *loseConfettiScreen;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation ServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupServer];
    self.leftScore = 0;
    self.rightScore = 0;

    self.photoProgressView.hidden = YES;
}

#pragma mark - Helpers methods

- (void)showMultipeerBrowser {
    MCBrowserViewController *browserVC = [[MultipeerManager sharedInstance] createMCBrowser];
    browserVC.delegate = self;

    [self presentViewController:browserVC animated:YES completion:nil];
}

- (BOOL)leftPlayerWon {
    return (self.leftScore >= self.pointsToWin && [self scoreDelta] > 1);
}

- (BOOL)rightPlayerWon {
    return (self.rightScore >= self.pointsToWin && [self scoreDelta] > 1);
}

- (NSInteger)scoreDelta {
    NSInteger delta = self.leftScore - self.rightScore;
    if (self.leftScore > self.rightScore) {
        return delta;
    } else if (self.leftScore < self.rightScore) {
        return -delta;
    } else {
        return 0;
    }
}

- (void)toggleServer {
    self.leftServingLabel.hidden = !self.leftServingLabel.hidden;
    self.rightServingLabel.hidden = !self.rightServingLabel.hidden;
    self.leftServingImageView.hidden = !self.leftServingImageView.hidden;
    self.rightServingImageView.hidden = !self.rightServingImageView.hidden;
}

- (void)startConfettiAnimationInRect:(CGRect)rect win:(BOOL)win {
    ConfettiScreen *confettiScreen = [[ConfettiScreen alloc] initWithFrame:rect win:win];
    if (win) {
        self.winConfettiScreen = confettiScreen;
    } else {
        self.loseConfettiScreen = confettiScreen;
    }
    [self.confettiView addSubview:confettiScreen];
}

- (void)stopConfettiAnimation {
    [self.winConfettiScreen stopEmitting];
    [self.loseConfettiScreen stopEmitting];
    for (UIView * view in self.confettiView.subviews) {
        [view removeFromSuperview];
    }
}

- (void)setupServer {
    [MultipeerManager sharedInstance].serverDelegate = self;
    [[MultipeerManager sharedInstance] setupPeerAndSessionWithDisplayName:kServerKey];
    [[MultipeerManager sharedInstance] advertiseSelf:YES];
    [self showMultipeerBrowser];
}

- (void)playAudioForAudioName:(NSString *)audioName {
    if (!audioName) return;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:audioName ofType:@"mp3"];
    NSError *error;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:&error];
    self.player = player;
    BOOL success = [player prepareToPlay];
    if (success) {
        [player play];
    }
}

#pragma mark - UI updating helpers

- (void)scoreUpdated {
    [self updateScoreLabels];
    [self updateServingString];
    [self sayScoreIfNeeded];
    if ([self isGameOver]) {
        [self informClientGameOver];
    } else {
        [self informClientOfServer];
    }
}

- (void)sayScoreIfNeeded {
    if (self.leftScore < self.pointsToWin - 1 && self.rightScore < self.pointsToWin - 1) {
        return;
    }
    NSString *audioString;
    BOOL deuce = ([self isInTieBreakerMode] && self.leftScore == self.rightScore);
    BOOL advantageLeft = ([self isInTieBreakerMode] && self.leftScore > self.rightScore && [self scoreDelta]==1);
    BOOL advantageRight = ([self isInTieBreakerMode] && self.rightScore > self.leftScore && [self scoreDelta]==1);
    if (deuce) {
        audioString = @"deuce";
    } else if (advantageLeft) {
        audioString = @"advantageLeft";
    } else if (advantageRight) {
        audioString = @"advantageRight";
    } else if (![self isGameOver]) {
        audioString = @"matchPoint";
    }

    [self playAudioForAudioName:audioString];
}

- (void)informClientGameOver {
    NSAssert([self isGameOver], @"Game must be over for this method to be called");
    NSString *winnerName = [self leftPlayerWon] ? kLeftPlayerKey : kRightPlayerKey;
    NSString *loserName = [self leftPlayerWon] ? kRightPlayerKey : kLeftPlayerKey;
    [[MultipeerManager sharedInstance] sendMessage:kWinMessage toPeer:winnerName];
    [[MultipeerManager sharedInstance] sendMessage:kLoseMessage toPeer:loserName];
}

- (BOOL)isGameOver {
    CGRect leftFrame = CGRectMake(0.0f, 0.0f, 384.0f, 50.0f);
    CGRect rightFrame = CGRectMake(CGRectGetWidth(self.view.bounds)-384.0f, 0.0f, 384.0f, 50.0f);

    //TODO: refactor
    if ([self leftPlayerWon]) {
        [self startConfettiAnimationInRect:leftFrame win:YES];
        [self startConfettiAnimationInRect:rightFrame win:NO];
    } else if ([self rightPlayerWon]) {
        [self startConfettiAnimationInRect:rightFrame win:YES];
        [self startConfettiAnimationInRect:leftFrame win:NO];
    }
    return [self leftPlayerWon] || [self rightPlayerWon];
}

- (void)informClientOfServer {
    BOOL isLeftPlayerServing = self.leftServingLabel.hidden == NO;
    NSString *serveMessage = isLeftPlayerServing ? kYourServeLeftKey : kYourServeRightKey;
    NSString *playerName = isLeftPlayerServing ? kLeftPlayerKey : kRightPlayerKey;

    if ([self isInTieBreakerMode]) {
        [[MultipeerManager sharedInstance] sendMessage:serveMessage toPeer:playerName];
        return;
    }

    BOOL isLastServe = [self servesRemainingForServingPlayer]==([self servesPerPlayer] - 1);
    if (isLeftPlayerServing) {
        serveMessage = isLastServe ? kLastServeLeftKey : kYourServeLeftKey;
    } else {
        serveMessage = isLastServe ? kLastServeRightKey : kYourServeRightKey;
    }

    [[MultipeerManager sharedInstance] sendMessage:serveMessage toPeer:playerName];
}

- (BOOL)isInTieBreakerMode {
    return (self.leftScore >= [self tieBreakerThreshold] && self.rightScore >= [self tieBreakerThreshold]);
}

- (NSInteger)tieBreakerThreshold {
    return self.pointsToWin - 1;
}

- (void)updateScoreLabels {
    self.leftScoreLabel.text = [NSString stringWithFormat:@"%ld",(long)self.leftScore];
    self.rightScoreLabel.text = [NSString stringWithFormat:@"%ld",(long)self.rightScore];
}

- (void)updateServingString {
    NSInteger threshold = [self pointsToWin] - 1;
    BOOL bothPlayersAboveThreshold = (self.leftScore >= threshold && self.rightScore >= threshold);
    if (bothPlayersAboveThreshold) {
        if (self.pointsToWin == 11) {
            [self toggleServer];
        } else if ((self.leftScore + self.rightScore)%2 == 0) {
            [self toggleServer];
        }
    } else if ([self servesRemainingForServingPlayer] == 0) {
        [self toggleServer];
    }
}

- (NSInteger)servesRemainingForServingPlayer {
    return (self.rightScore + self.leftScore)%[self servesPerPlayer];
}

- (NSInteger)servesPerPlayer {
    return (self.pointsToWin == 11) ? 2 : 5;
}

- (void)resetGame {
    self.leftScore = 0;
    self.leftScoreLabel.text = @"0";
    self.rightScore = 0;
    self.rightScoreLabel.text = @"0";
    [self stopConfettiAnimation];

    [[MultipeerManager sharedInstance] broadcastString:kResetMessage];
}

#pragma mark - MultipeerServerDelegate methods

- (void)leftPlayerScored {
    self.leftScore ++;
    [self scoreUpdated];
}

- (void)rightPlayerScored {
    self.rightScore ++;
    [self scoreUpdated];
}

- (void)setupLeftImage:(UIImage *)image {
    UIImage *portraitImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationRight];
    self.leftPlayerImageView.image = portraitImage;
}

- (void)setupRightImage:(UIImage *)image {
    UIImage *portraitImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:1.0 orientation:UIImageOrientationRight];
    self.rightPlayerImageView.image = portraitImage;
}

- (void)triggeredReset {
    [self resetGame];
}

- (void)setupGameWithPointsToWin:(NSInteger)pointsToWin {
    self.pointsToWin = pointsToWin;
    NSString *pointsToWinString = [NSString stringWithFormat:@"%ld",(long)pointsToWin];
    self.pointsToWinLabel.text = pointsToWinString;
    [[MultipeerManager sharedInstance] broadcastString:pointsToWinString];
}

- (void)minusOneToLeftScore {
    if (self.leftScore > 0) {
        self.leftScore--;
        [self scoreUpdated];
    }
}

- (void)minusOneToRightScore {
    if (self.rightScore > 0) {
        self.rightScore--;
        [self scoreUpdated];
    }
}

- (void)didStartDownloadingPhoto {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.photoProgressView.hidden = NO;
    });
}

- (void)photoDownloadPercent:(CGFloat)percent {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (percent == 1.0f) {
            self.photoProgressView.hidden = YES;
        }
        self.photoProgressView.progress = percent;
    });
}

- (void)leftPlayerConnected {
    self.leftPlayerConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Player Connected",kLeftPlayerKey];
    self.leftPlayerConnectionStatusLabel.textColor = [UIColor greenColor];
}

- (void)rightPlayerConnected {
    self.rightPlayerConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Player Connected",kRightPlayerKey];
    self.rightPlayerConnectionStatusLabel.textColor = [UIColor greenColor];
}

- (void)leftPlayerDisconnected {
    self.leftPlayerConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Player Disonnected",kLeftPlayerKey];
    self.leftPlayerConnectionStatusLabel.textColor = [UIColor redColor];
}

- (void)rightPlayerDisconnected {
    self.rightPlayerConnectionStatusLabel.text = [NSString stringWithFormat:@"%@ Player Disonnected",kRightPlayerKey];
    self.rightPlayerConnectionStatusLabel.textColor = [UIColor redColor];
}

- (void)changeStartingServer {
    if (self.leftScore == 0 && self.rightScore == 0) {
        [self toggleServer];
    }
}


#pragma mark - MCBrowserViewControllerDelegate Methods

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)resetGameTapped:(id)sender {
    [self resetGame];
}

- (IBAction)restartServerTapped:(id)sender {
    [[MultipeerManager sharedInstance] disconnectServer];
    [self setupServer];
}

- (IBAction)reconnectTapped:(id)sender {
    [self showMultipeerBrowser];
}

@end
