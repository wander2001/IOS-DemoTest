//
//  PRPDrawScale.h
//  SplitView_AudioQueues_FFT_Graphs_Gate
//
//  Created by Phillip Parker on 04/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PRPDrawScale : UIView{
	CGImageRef image;
    NSNumber *noteIncrease;
}

@property (strong, nonatomic) NSMutableArray *data;
@property (strong, nonatomic) NSMutableSet *answer;
@property (strong, nonatomic) NSMutableSet *pitch;
@property (retain, nonatomic) NSString *fileToDraw;
@property (strong, nonatomic) NSNumber *noteIncrease;

-(void)clear;
-(void)undo;
-(void)redo;
-(void)addNote:(NSNumber*) note;
-(void)addPitch:(NSNumber*) note;
-(void)increaseNotes:(NSNumber *) increase;
-(void)currentData:(NSString *) playDate;
-(void)setAnswer:(NSMutableSet *)answer;

@end
