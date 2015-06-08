//
//  PRPDrawScale.m
//  SplitView_AudioQueues_FFT_Graphs_Gate
//
//  Created by Phillip Parker on 04/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//lengths to draw scale and images correctly
#define kNoteOffset (60 - 21)
#define kDetectOffset 5
#define kDetectRange 5

#define kScaleLeft 0
#define kScaleRight 685
#define kScaleOffsetY 80
#define kScaleOffsetY_line (kScaleOffsetY - 20)
#define kScale2OffsetY 260
#define kScale2OffsetY_line (kScale2OffsetY + 40)
#define kScaleStepY 30
#define kHeight 480

#define kScaleCalulateY (kHeight - kScale2OffsetY_line - 145)

#define answerOffsetX 180
#define pitchOffsetX 380
#define kNoteOffsetX 280
#define kNoteOffsetY 0
#define kNote2OffsetY (kScale2OffsetY - 20)

#define kNoteStepY (kScaleStepY / 2)

#define kStepX 0
#define kSameX 30

#define kStepY 50
#define kOffsetY 10

#import "PRPDrawScale.h"

@implementation PRPDrawScale
{
    NSNumber* currentNote;
    UIImageView* currentImageView;
    NSUndoManager* undoManager;
    int display[88];
    NSArray* semi0;
    NSArray* semi0_1;
    NSArray* semi1;
    NSArray* semi1_1;
    NSArray* semiUp;
    NSArray* semiDown;
    
}
@synthesize data;
@synthesize answer;
@synthesize pitch;
@synthesize fileToDraw;
@synthesize noteIncrease;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {
    }
    return self;
}

-(void)addNote:(NSNumber*) note {
    [self addNote:note isUndo:false];
}

-(void)addNote:(NSNumber*) note isUndo:(bool) undo {
    if (undo) {
        [[undoManager prepareWithInvocationTarget:self]removeNoteAtIndex:(int)[data count] isUndo:true];
    }
    [data addObject:note];
    //Update the view
    [self setNeedsDisplay];
}

-(void)addPitch:(NSNumber *)note {
    [[undoManager prepareWithInvocationTarget:self]removePitch: note];
    [pitch addObject: note];
    //Update the view
    [self setNeedsDisplay];
}

-(void)removePitch:(NSNumber *)note{
    if (index < 0) return;
    [[undoManager prepareWithInvocationTarget:self]addPitch: note];
    [pitch removeObject: note];
    //Update the view
    [self setNeedsDisplay];
    
}

-(void)removeNoteAtIndex:(int) index {
    [self removeNoteAtIndex:index isUndo:false];
}

-(void)removeNoteAtIndex:(int) index isUndo:(bool) undo {
    if (index < 0) return;
    if (undo) {
        [[undoManager prepareWithInvocationTarget:self]addNote:[data objectAtIndex:index] isUndo:true];
    }
    [data removeObjectAtIndex:index];
    //Update the view
    [self setNeedsDisplay];
    
}

#pragma touchEvent
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // We only support single touches, so anyObject retrieves just that touch from touches.
    UITouch *touch = [touches anyObject];
    // Animate the first touch.
    CGPoint touchPoint = [touch locationInView:self];
    currentNote = [self encodeNote:[self getNote:(int)touchPoint.y]];
    
    [self addNote: currentNote];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    
    currentImageView.center = CGPointMake(kNoteOffsetX, touchPoint.y);
    
    NSNumber* note = [self encodeNote:[self getNote:(int)touchPoint.y]];
    
    int index = (int)[data count] - 1;
    if (index >= 0) {
        [data removeObjectAtIndex: index];
    }
    currentNote = note;
    [self addNote:currentNote];
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // We only support single touches, so anyObject retrieves just that touch from touches.
    UITouch *touch = [touches anyObject];
    // Animate the first touch.
    CGPoint touchPoint = [touch locationInView:self];
    
    NSNumber* note = [self encodeNote:[self getNote:(int)touchPoint.y]];
    
    int index = (int)[data count] - 1;
    if (index >= 0) {
        [data removeObjectAtIndex: index];
    }
    currentNote = note;
    [self addNote:currentNote isUndo: true];
}


#pragma notes
-(void)currentData:playDate{
    
    //Instantiate the array
    data = [NSMutableArray arrayWithCapacity:76];
    //Create the path of the data required
    NSString *noteIndex = [NSString stringWithFormat:@"note_%@",playDate];
    NSLog(@"string location: %@",noteIndex);
    //Find the documents directory
    NSArray *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentFolder = [documentPath objectAtIndex:0];
    
    //Concatinate the documents directory URL with the storage plist
    NSString *plistFile = [documentFolder stringByAppendingPathComponent:@"Storage.plist"];
    
    NSString *bundleFile = [[NSBundle mainBundle]pathForResource:@"Storage" ofType:@"plist"];
    
    
    //Copy the file from the bundle to the doc directory 
    [[NSFileManager defaultManager]copyItemAtPath:bundleFile toPath:plistFile error:nil];
    //Copy the current contents of the plist to an 	NSDictionary
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:plistFile];
    //Extract data from the NSDictionary at the index specifed
    NSMutableArray *noteDataFromPlist = [dict valueForKey:noteIndex];
    
    //Copy the extracted data from the Array into the data 	array
    for (int i = 0; i < 103; i++) {
        NSNumber *note = [NSNumber numberWithFloat:[[noteDataFromPlist objectAtIndex:i] floatValue]];
        
        [data insertObject:note atIndex:i];
                
    }
    
    //Update the view
    [self setNeedsDisplay];
    
}

-(void)increaseNotes:(NSNumber *) increase{
    //Set the public variable noteIncrease to the input parameter
    noteIncrease = increase;
    //Update the drawRect method
    [self setNeedsDisplay];
}

- (NSNumber*)encodeNote: (NSNumber*) input {
    int i = [input intValue];
    i += kNoteOffset;
    return [NSNumber numberWithInt:i];
}

- (NSNumber*)decodeNote: (NSNumber*) output {
    int i = [output intValue];
    i -= kNoteOffset;
    return [NSNumber numberWithInt:i];
}



- (NSNumber*)getNote:(int) y {
    for(int i = 1; i <= 43; ++i) {
        NSNumber* number = [NSNumber numberWithInt:i];
        int convertedY = kHeight - display[i];
        if ([semi0_1 containsObject:number] || [semi1_1 containsObject:number]) {
            if (y <= (convertedY - (kDetectOffset + kDetectRange))
                && y >= (convertedY - (kDetectOffset + kDetectRange * 2))) {
                return number;
            }
        } else if ([semiUp containsObject: number]){
            if (y > (convertedY - (kDetectOffset + kDetectRange * 2))
                && y < (convertedY + (kDetectOffset + kDetectRange)))
            {
                return number;
            }
        } else if ([semiDown containsObject: number]) {
            if (y > (convertedY - (kDetectOffset + kDetectRange))
                && y <= (convertedY + (kDetectOffset + kDetectRange * 2)))
            {
                return number;
            }
        } else {
            if (y > (convertedY - (kDetectOffset + kDetectRange))
                && y < (convertedY + (kDetectOffset + kDetectRange)))
            {
                return number;
            }
        }
    }
    
    if ( y <= (kHeight - display[43] + kDetectRange)) {
        return @43;
    } else if (y >= (kHeight - display[1]- kDetectRange)) {
        return @1;
    } else if (y <= (kHeight/2) && y >= (kHeight - display[21] - kDetectRange)) {
        return @21;
    } else if (y > (kHeight/2) && y <= (kHeight - display[20] + kDetectRange)) {
        return @20;
    }
    
    return @0;
}

- (void)longPressHandler:(UILongPressGestureRecognizer *)gestureRecognizer {
    NSLog(@"longPressHandler");
    UIImageView *tempImage=(UIImageView*)[gestureRecognizer view];
    [tempImage removeFromSuperview];
}

- (void)clear {
    [data removeAllObjects];
    [answer removeAllObjects];
    [pitch removeAllObjects];
    [undoManager removeAllActions];
    [self setNeedsDisplay];
}

- (void)undo {
    [undoManager undo];
    [self setNeedsDisplay];
}

- (void)redo {
    [undoManager redo];
    [self setNeedsDisplay];
}

-(void)setAnswer:(NSMutableSet *) ans{
    answer = ans;
    [self setNeedsDisplay];
}

- (UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) scaleFactor
{
    float oldWidth = sourceImage.size.width;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)setDisplay
{
    semi1 = [[NSArray alloc] initWithObjects:@1,@21,@42,nil];
    semi1_1 = [[NSArray alloc] initWithObjects:@22,@43,nil];
    semi0_1 = [[NSArray alloc] initWithObjects:@3,@5,@7,@10,@12,@15,@17,@19,@24,@27,@29,@31,@34,@36,@38,@41,nil];
    semiUp = [[NSArray alloc] initWithObjects:@1,@8,@13,@25,@32,@37,nil];
    semiDown = [[NSArray alloc] initWithObjects:@2,@9,@14,@26,@33,@38,nil];
    
    display[1] = kNoteOffsetY+(kNoteStepY * 1);
    display[2] = kNoteOffsetY+(kNoteStepY * 2);
    display[3] = kNoteOffsetY+(kNoteStepY * 2);
    display[4] = kNoteOffsetY+(kNoteStepY * 3);
    display[5] = kNoteOffsetY+(kNoteStepY * 3);
    display[6] = kNoteOffsetY+(kNoteStepY * 4);
    display[7] = kNoteOffsetY+(kNoteStepY * 4);
    display[8] = kNoteOffsetY+(kNoteStepY * 5);
    display[9] = kNoteOffsetY+(kNoteStepY * 6);
    display[10] = kNoteOffsetY+(kNoteStepY * 6);
    display[11] = kNoteOffsetY+(kNoteStepY * 7);
    display[12] = kNoteOffsetY+(kNoteStepY * 7);
    display[13] = kNoteOffsetY+(kNoteStepY * 8);
    display[14] = kNoteOffsetY+(kNoteStepY * 9);
    display[15] = kNoteOffsetY+(kNoteStepY * 9);
    display[16] = kNoteOffsetY+(kNoteStepY * 10);
    display[17] = kNoteOffsetY+(kNoteStepY * 10);
    display[18] = kNoteOffsetY+(kNoteStepY * 11);
    display[19] = kNoteOffsetY+(kNoteStepY * 11);
    display[20] = kNoteOffsetY+(kNoteStepY * 12);
    display[21] = kNote2OffsetY+(kNoteStepY * 1);
    display[22] = kNote2OffsetY+(kNoteStepY * 1);
    display[23] = kNote2OffsetY+(kNoteStepY * 2);
    display[24] = kNote2OffsetY+(kNoteStepY * 2);
    display[25] = kNote2OffsetY+(kNoteStepY * 3);
    display[26] = kNote2OffsetY+(kNoteStepY * 4);
    display[27] = kNote2OffsetY+(kNoteStepY * 4);
    display[28] = kNote2OffsetY+(kNoteStepY * 5);
    display[29] = kNote2OffsetY+(kNoteStepY * 5);
    display[30] = kNote2OffsetY+(kNoteStepY * 6);
    display[31] = kNote2OffsetY+(kNoteStepY * 6);
    display[32] = kNote2OffsetY+(kNoteStepY * 7);
    display[33] = kNote2OffsetY+(kNoteStepY * 8);
    display[34] = kNote2OffsetY+(kNoteStepY * 8);
    display[35] = kNote2OffsetY+(kNoteStepY * 9);
    display[36] = kNote2OffsetY+(kNoteStepY * 9);
    display[37] = kNote2OffsetY+(kNoteStepY * 10);
    display[38] = kNote2OffsetY+(kNoteStepY * 11);
    display[39] = kNote2OffsetY+(kNoteStepY * 11);
    display[40] = kNote2OffsetY+(kNoteStepY * 12);
    display[41] = kNote2OffsetY+(kNoteStepY * 12);
    display[42] = kNote2OffsetY+(kNoteStepY * 13);
    display[43] = kNote2OffsetY+(kNoteStepY * 13);
}

- (void)drawRect:(CGRect)rect
{
    if (undoManager == nil)
    {
        undoManager = [[NSUndoManager alloc] init];
        [undoManager setLevelsOfUndo:100];
    }
    
    if (data == nil)
    {
        data = [[NSMutableArray alloc] init];
    }
    
    if (pitch == nil) {
        pitch = [[NSMutableSet alloc] init];
    }
    
    //Get the graphics context
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //Reverses the co-ordination system so that values increasing will represent moving up on the
    //screen. This is why the image is made upside down.
    CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
    
    //Import Treble Clef image
    UIImage *trebleClef = [self imageWithImage:[UIImage imageNamed:@"trebleclef.png"] scaledToWidth:2.0];
    //Set the location to draw
    CGPoint imagePointTreble = CGPointMake(0,kScale2OffsetY);
    //Draw the image
    [trebleClef drawAtPoint:imagePointTreble];
    
    //Import Bass Clef Image
    UIImage *bassClef = [self imageWithImage:[UIImage imageNamed:@"bassclef.png"] scaledToWidth:2.0];
    //Set the location to draw
    CGPoint imagePointBass = CGPointMake(1,kScaleOffsetY);
    //Draw the imagine
    [bassClef drawAtPoint:imagePointBass];
    
    //Set a line width
    CGContextSetLineWidth(context, 3.0);
    //Set the colour of the line
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    
    //Create the lines at the positions specifed by the defines
    for (int i = 0; i < 5; i++)
    {
        //Specify to the start point
        CGContextMoveToPoint(context,kScaleLeft , kScaleOffsetY_line + i * kScaleStepY);
        //Specify the end point
        CGContextAddLineToPoint(context,kScaleRight , kScaleOffsetY_line + i * kScaleStepY);
    }
    
    //Draw the line
    CGContextStrokePath(context);
    
    CGContextSetLineWidth(context, 3.0);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    
    
    for (int i = 0; i < 5; i++)
    {
        //Specify to the start point
        CGContextMoveToPoint(context,kScaleLeft , kScale2OffsetY_line + i * (kScaleStepY));
        //Specify the end point
        CGContextAddLineToPoint(context,kScaleRight , kScale2OffsetY_line + i * (kScaleStepY));
    }
    
    CGContextStrokePath(context);
    
    
    UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
    longpressGesture.minimumPressDuration = 5;
    
    [self drawNotesOffsetX: kNoteOffsetX withData: data];
    [self drawNotesOffsetX: answerOffsetX withData: [answer allObjects]];
    [self drawNotesOffsetX: pitchOffsetX withData: [pitch allObjects]];
}

- (void) drawNotesOffsetX:(int) xOffset withData: (NSArray*) dataSet {
    for (int i = 0; i < [dataSet count]; i++) {
        //Import note images
        UIImage *semibreve0 = [self imageWithImage:[UIImage imageNamed:@"semibreve0.png"] scaledToWidth:1.2];
        UIImage *semibreve0_1 = [self imageWithImage:[UIImage imageNamed:@"semibreve0-1.png"] scaledToWidth:1.2];
        
        UIImage *semibreve1 = [self imageWithImage:[UIImage imageNamed:@"semibreve1.png"] scaledToWidth:1.2];
        UIImage *semibreve1_1 = [self imageWithImage:[UIImage imageNamed:@"semibreve1-1.png"] scaledToWidth:1.2];
        
        
        [self setDisplay];
        NSNumber* noteNumber = [self decodeNote:[dataSet objectAtIndex:i]];
        int note = [noteNumber intValue];
        CGPoint imagePoint = CGPointMake(xOffset+(kStepX*(i)),display[note]); //kNoteOffsetX
        
        if ([semi1 containsObject:noteNumber]) {
            [semibreve1 drawAtPoint:imagePoint];
        } else if ([semi1_1 containsObject:noteNumber]) {
            [semibreve1_1 drawAtPoint:imagePoint];
        } else if ([semi0_1 containsObject: noteNumber]) {
            [semibreve0_1 drawAtPoint:imagePoint];
        } else {
            [semibreve0 drawAtPoint:imagePoint];
        }
    }
}

@end
