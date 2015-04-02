//
//  ViewController.h
//  ListeningPractice
//
//  Created by Min Liu on 2/12/15.
//  Copyright (c) 2015 Min Liu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AudioController.h"
#import "PitchDetector.h"

@interface ListenerViewController : UIViewController <
    PitchDetectorDelegate, AudioControllerDelegate,
    UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate>
{
    AudioController *audioManager;
    PitchDetector *autoCorrelator;
    NSMutableArray *medianPitchFollow;
}

@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UILabel *freqLabel;
@property (weak, nonatomic) IBOutlet UIImageView *result;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (nonatomic,retain) NSMutableArray *tableData;
- (IBAction)record:(id)sender;



- (IBAction)play:(id)sender;
- (IBAction)add:(id)sender;
- (IBAction)verify:(id)sender;
- (IBAction)change:(id)sender;

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

