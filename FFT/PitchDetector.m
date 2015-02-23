/*
 Copyright (c) Kevin P Murphy June 2012
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#import "PitchDetector.h"


@implementation PitchDetector
{
    AudioConverterRef converter;
    UInt32 maxSamples;
    
    UInt32 log2n;
    UInt32 n;
    
    UInt32 stride;
    UInt32 nOver2;
    
    FFTSetup fftSetup;
    
    COMPLEX_SPLIT   A;
    float window[MAX_FRAMES], in_real[MAX_FRAMES], outputBuffer[MAX_FRAMES];
    float *logmag, *displayData;
    
    SInt16 dataBuffer[MAX_FRAMES];
}

@synthesize lowBoundFrequency, hiBoundFrequency, sampleRate, delegate, running;


#pragma mark Initialize Methods


-(id) initWithSampleRate: (float) rate andDelegate: (id<PitchDetectorDelegate>) initDelegate {
    return [self initWithSampleRate:rate lowBoundFreq:40 hiBoundFreq:4500 andDelegate:initDelegate];
}

-(id) initWithSampleRate: (float) rate lowBoundFreq: (int) low hiBoundFreq: (int) hi andDelegate: (id<PitchDetectorDelegate>) initDelegate {
    self.lowBoundFrequency = low;
    self.hiBoundFrequency = hi;
    self.sampleRate = rate;
    self.delegate = initDelegate;
    
    bufferLength = self.sampleRate/self.lowBoundFrequency;
    maxSamples = MAX_FRAMES;
    
    log2n = log2f(maxSamples); //bins
    n = 1 << log2n;
    
    stride = 1;
    nOver2 = n/2;
    
    fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    A.realp = (float *) malloc(nOver2 * sizeof(float));
    A.imagp = (float *) malloc(nOver2 * sizeof(float));
    logmag = malloc(sizeof(float)*nOver2);
    displayData = malloc(sizeof(float)*n);
    
    [self setupConverter];

    return self;
}

#pragma  mark Insert Samples

- (void) addSamples:(SInt16 *)samples inNumberFrames:(int)frames {
    
    memcpy((SInt16 *) dataBuffer, samples, frames * sizeof(SInt16));
    
    //-- window
    
    UInt32 windowSize = maxSamples;
    memset(window, 0, windowSize * sizeof(float));
    //vDSP_hann_window(window, windowSize, 0);
    vDSP_blkman_window(window, windowSize, 1);
    
    [self convertInt16ToFloat:dataBuffer Output:outputBuffer Capacity:frames];
    
    vDSP_vmul(outputBuffer, 1, window, 1, in_real, 1, maxSamples);
    
    vDSP_ctoz((COMPLEX*)in_real, 2, &A, 1, maxSamples/2);
    
    vDSP_fft_zrip(fftSetup, &A, stride, log2n, FFT_FORWARD);
    
    vDSP_ztoc(&A, 1, (COMPLEX *)in_real, 2, nOver2);
    
    
    A.imagp[0] = 0.0f;
    vDSP_zvmags(&A, 1, A.realp, 1, nOver2);
    bzero(A.imagp, (nOver2) * sizeof(float));
    
    // scale
    float scale = 1.0f / (2.0f*(float)n);
    vDSP_vsmul(A.realp, 1, &scale, A.realp, 1, nOver2);
    
    // step 2 get log for cepstrum
    for (int i=0; i < nOver2; i++)
        logmag[i] = logf(sqrtf(A.realp[i]));
    
    
    // configure float array into acceptable input array format (interleaved)
    vDSP_ctoz((COMPLEX*)logmag, 2, &A, 1, nOver2);
    
    // create cepstrum
    vDSP_fft_zrip(fftSetup, &A, stride, log2n-1, FFT_INVERSE);
    
    //convert interleaved to real
    vDSP_ztoc(&A, 1, (COMPLEX*)displayData, 2, nOver2);
    
    
    int currentBin = 0;
    float dominantFrequencyAmp = 0;
    
    // find peak of cepstrum
    for (int i=0; i < nOver2; i++){
        //get current frequency magnitude
        float freq = displayData[i];
        if (freq > dominantFrequencyAmp) {
            // DLog("Bufferer filled %f", displayData[i]);
            dominantFrequencyAmp = freq;
            currentBin = i;
        }
    }

    float freq = currentBin * sampleRate/frames;
    //if(freq >= self.lowBoundFrequency && freq <= self.hiBoundFrequency) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate updatedPitch:freq];
        });
    //}
}

- (void)convertInt16ToFloat:(void*) buf Output: (float *) outputBuf Capacity: (size_t) capacity
{
    OSStatus err;
    UInt32 inSize = capacity*sizeof(SInt16);
    UInt32 outSize = capacity*sizeof(float);
    err = AudioConverterConvertBuffer(converter, inSize, buf, &outSize, outputBuf);
}

- (void) setupConverter
{
    OSStatus err;
    
    size_t bytesPerSample = sizeof(float);
    AudioStreamBasicDescription outFormat = {0};
    outFormat.mFormatID = kAudioFormatLinearPCM;
    outFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
    outFormat.mBitsPerChannel = 8 * bytesPerSample;
    outFormat.mFramesPerPacket = 1;
    outFormat.mChannelsPerFrame = 1;
    outFormat.mBytesPerPacket = bytesPerSample * outFormat.mFramesPerPacket;
    outFormat.mBytesPerFrame = bytesPerSample * outFormat.mChannelsPerFrame;
    outFormat.mSampleRate = sampleRate;
    
    AudioStreamBasicDescription audioFormat = {0};
    audioFormat.mSampleRate			= 44100.00;
    audioFormat.mFormatID			= kAudioFormatLinearPCM;
    audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioFormat.mFramesPerPacket	= 1;
    audioFormat.mChannelsPerFrame	= 1;
    audioFormat.mBitsPerChannel		= 16;
    audioFormat.mBytesPerPacket		= 2;
    audioFormat.mBytesPerFrame		= 2;
    
    
    const AudioStreamBasicDescription inFormat = audioFormat;
    err = AudioConverterNew(&inFormat, &outFormat, &converter);
}

@end
