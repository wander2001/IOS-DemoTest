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

#define OFFSET 20;

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
    NSMutableSet *_selectedNotes;
    NSMutableSet *_questionNotes;
    NSNumber *currentNode;
}

- (void) generateQuestion
{
    [_questionNotes addObject: @60];
    [_questionNotes addObject: @64];
    [_questionNotes addObject: @67];
}

-(void)load
{
    
    audioManager = [AudioController sharedAudioManager];
    audioManager.delegate = self;
    autoCorrelator = [[PitchDetector alloc] initWithSampleRate:audioManager.audioFormat.mSampleRate lowBoundFreq:30 hiBoundFreq:4500 andDelegate:self];
    
    medianPitchFollow = [[NSMutableArray alloc] initWithCapacity:22];

    _playingArpeggio = NO;
    
    // Create the player and tell it which sound bank to use.
    _selectedNotes = [[NSMutableSet alloc] init];
    _questionNotes = [[NSMutableSet alloc] init];
    
    [self generateQuestion];
    
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

- (void) updatedPitch:(float)frequency {
    
    double value = frequency;
    //value = [self median:value];
    int noteNum = [self closestCharForFrequency:value] + OFFSET;
    currentNode = [NSNumber numberWithInt:noteNum];
    self.freqLabel.text = [NSString stringWithFormat:@"%3.1f Hz & Note:%d", value, noteNum];
    
}

- (int)closestCharForFrequency:(float)frequency {
    int n = (12 * log2f(frequency / 440) + 0.5) + 49; //round
    return n;
}

- (double) median: (double) value {
    
    NSNumber *nsnum = [NSNumber numberWithDouble:value];
    [medianPitchFollow insertObject:nsnum atIndex:0];
    
    if(medianPitchFollow.count>22) {
        [medianPitchFollow removeObjectAtIndex:medianPitchFollow.count-1];
    }
    
    double median = 0;
    
    if(medianPitchFollow.count>=2) {
        NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
        NSMutableArray *tempSort = [NSMutableArray arrayWithArray:medianPitchFollow];
        [tempSort sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
        
        if(tempSort.count%2==0) {
            double first = 0, second = 0;
            first = [[tempSort objectAtIndex:tempSort.count/2-1] doubleValue];
            second = [[tempSort objectAtIndex:tempSort.count/2] doubleValue];
            median = (first+second)/2;
            value = median;
        } else {
            median = [[tempSort objectAtIndex:tempSort.count/2] doubleValue];
            value = median;
        }
        
        [tempSort removeAllObjects];
        tempSort = nil;
    }
    return value;
}

- (void) receivedAudioSamples:(SInt16 *)samples length:(int)len {
    [autoCorrelator addSamples:samples inNumberFrames:len];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)play:(id)sender {
    for (NSNumber *questionNote in _questionNotes) {
        [_soundBankPlayer queueNote:[questionNote intValue] gain:0.4f];
    }
    [_soundBankPlayer playQueuedNotes];
}

- (IBAction)add:(id)sender {
    [_selectedNotes addObject:currentNode];
}

- (IBAction)verify:(id)sender {
    if ([_questionNotes isEqual: _selectedNotes]) {
        self.result.image = [UIImage imageNamed:@"correct.jpeg"];
    } else {
        self.result.image = [UIImage imageNamed:@"wrong.jpeg"];
    }
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
    [_soundBankPlayer queueNote:72 gain:0.4f];
    [_soundBankPlayer playQueuedNotes];
}




@end
