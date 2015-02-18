//
//  ViewController.m
//  ListeningPractice
//
//  Created by Min Liu on 2/12/15.
//  Copyright (c) 2015 Min Liu. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SoundBankPlayer.h"
#import "ListenerViewController.h"

@interface ListenerViewController ()

@end


@implementation ListenerViewController

{
    SoundBankPlayer *_soundBankPlayer;
    NSTimer *_timer;
    BOOL _playingArpeggio;
    NSArray *_arpeggioNotes;
    NSUInteger _arpeggioIndex;
    CFTimeInterval _arpeggioStartTime;
    CFTimeInterval _arpeggioDelay;
    NSMutableIndexSet *_selectedNote;
}

-(void)load
{
    _playingArpeggio = NO;
    
    // Create the player and tell it which sound bank to use.
    _selectedNote = [[NSMutableIndexSet alloc] init];
    _soundBankPlayer = [[SoundBankPlayer alloc] init];
    [_soundBankPlayer setSoundBank:@"Piano"];
    
    // We use a timer to play arpeggios.
    [self startTimer];
}

- (void)dealloc
{
    [self stopTimer];
}


- (void)playArpeggioWithNotes:(NSArray *)notes delay:(CFTimeInterval)delay
{
    if (!_playingArpeggio)
    {
        _playingArpeggio = YES;
        _arpeggioNotes = [notes copy];
        _arpeggioIndex = 0;
        _arpeggioDelay = delay;
        _arpeggioStartTime = CACurrentMediaTime();
    }
}

- (void)startTimer
{
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.05f  // 50 ms
                                              target:self
                                            selector:@selector(handleTimer:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)stopTimer
{
    if (_timer != nil && [_timer isValid])
    {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)handleTimer:(NSTimer *)timer
{
    if (_playingArpeggio)
    {
        // Play each note of the arpeggio after "arpeggioDelay" seconds.
        CFTimeInterval now = CACurrentMediaTime();
        if (now - _arpeggioStartTime >= _arpeggioDelay)
        {
            NSNumber *number = _arpeggioNotes[_arpeggioIndex];
            [_soundBankPlayer noteOn:[number intValue] gain:0.4f];
            
            _arpeggioIndex += 1;
            if (_arpeggioIndex == [_arpeggioNotes count])
            {
                _playingArpeggio = NO;
                _arpeggioNotes = nil;
            }
            else  // schedule next note
            {
                _arpeggioStartTime = now;
            }
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self load];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)Play:(id)sender {
    [_soundBankPlayer queueNote:60 gain:0.4f];
    [_soundBankPlayer queueNote:64 gain:0.4f];
    [_soundBankPlayer queueNote:67 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)C:(id)sender {
    [_soundBankPlayer queueNote:60 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)Cplus:(id)sender {
    [_soundBankPlayer queueNote:61 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)D:(id)sender {
    [_soundBankPlayer queueNote:62 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)Dplus:(id)sender {
    [_soundBankPlayer queueNote:63 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)E:(id)sender {
    [_soundBankPlayer queueNote:64 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)F:(id)sender {
    [_soundBankPlayer queueNote:65 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)Fplus:(id)sender {
    [_soundBankPlayer queueNote:66 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)G:(id)sender {
    [_soundBankPlayer queueNote:67 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)Gplus:(id)sender {
    [_soundBankPlayer queueNote:68 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)A:(id)sender {
    [_soundBankPlayer queueNote:69 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)Aplus:(id)sender {
    [_soundBankPlayer queueNote:70 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)B:(id)sender {
    [_soundBankPlayer queueNote:71 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)C5:(id)sender {
    [_soundBankPlayer queueNote:73 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}




@end
