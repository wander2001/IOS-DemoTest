/*
 Copyright (c) Kevin P Murphy June 2012
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>

/*
 * How many OpenAL sources we will use. Each source plays a single buffer, so
 * this effectively determines the maximum polyphony. There is an upper limit
 * to the number of simultaneously playing sources that OpenAL supports.
 * http://stackoverflow.com/questions/2871905/openal-determine-maximum-sources
 */
#define NUM_SOURCES 32

@protocol AudioControllerDelegate
@required
- (void) receivedAudioSamples:(SInt16*) samples length:(int) len;
@end

@interface AudioController : NSObject 
{
    @public
    AudioBufferList bufferList;
}

@property (nonatomic, assign) BOOL loopNotes;

@property (nonatomic, assign) AudioStreamBasicDescription audioFormat;
@property (nonatomic, assign) AudioComponentInstance audioUnit;
@property (nonatomic, assign) id<AudioControllerDelegate> delegate;

+ (AudioController*) sharedAudioManager;
- (void) startAudio;
- (void) stopAudio;
- (void)setSoundBank:(NSString *)soundBankName;
- (void)noteOn:(int)midiNoteNumber gain:(float)gain;
- (void)queueNote:(int)midiNoteNumber gain:(float)gain;
- (void)playQueuedNotes;
- (void)noteOff:(int)midiNoteNumber;
- (void)allNotesOff;

@end




