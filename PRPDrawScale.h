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
@property (retain, nonatomic) NSString *fileToDraw;
@property (strong, nonatomic) NSNumber *noteIncrease;

-(void)undo;
-(void)redo;
-(void)addNote:(NSNumber*) note;
-(void)increaseNotes:(NSNumber *) increase;
-(void)currentData:(NSString *) playDate;

@end