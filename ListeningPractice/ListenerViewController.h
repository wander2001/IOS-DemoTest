//
//  ViewController.h
//  ListeningPractice
//
//  Created by Min Liu on 2/12/15.
//  Copyright (c) 2015 Min Liu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PRPDrawScale.h"
#import "AudioController.h"
#import "PitchDetector.h"

@interface ListenerViewController : UIViewController <
    PitchDetectorDelegate, AudioControllerDelegate>
{

    PRPDrawScale *drawScale;
    AudioController *audioManager;
    PitchDetector *autoCorrelator;
    NSMutableArray *medianPitchFollow;
}

@property (strong, nonatomic) IBOutlet PRPDrawScale *drawScale;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UILabel *freqLabel;
@property (weak, nonatomic) IBOutlet UIImageView *result;
- (IBAction)record:(id)sender;


- (IBAction)undo:(id)sender;
- (IBAction)redo:(id)sender;

- (IBAction)play:(id)sender;
- (IBAction)verify:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)prev:(id)sender;
- (IBAction)answer:(id)sender;
- (IBAction)addPitch:(id)sender;


#pragma mark keyboard
- (IBAction)C:(id)sender;
- (IBAction)Cplus:(id)sender;
- (IBAction)D:(id)sender;
- (IBAction)Dplus:(id)sender;
- (IBAction)E:(id)sender;
- (IBAction)F:(id)sender;
- (IBAction)Fplus:(id)sender;
- (IBAction)G:(id)sender;
- (IBAction)Gplus:(id)sender;
- (IBAction)A:(id)sender;
- (IBAction)Aplus:(id)sender;
- (IBAction)B:(id)sender;
- (IBAction)C5:(id)sender;


@end

