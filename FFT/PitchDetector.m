//
//  Created by Min Liu on 2/12/15.
//  Copyright (c) 2015 Min Liu. All rights reserved.
//


#import "PitchDetector.h"

#define MAX_FRAMES 8192
#define FILTER 50

@implementation PitchDetector
{
    AudioConverterRef converter;
    UInt32 bufferCapacity;
    
    UInt32 log2n;
    UInt32 n;
    
    UInt32 stride;
    UInt32 nOver2;
    
    FFTSetup fftSetup;
    
    COMPLEX_SPLIT   A;
    float window[MAX_FRAMES], in_real[MAX_FRAMES], outputBuffer[MAX_FRAMES];
    float *logmag, *displayData;
    
    SInt16 dataBuffer[MAX_FRAMES];
    UInt32 index;
}

@synthesize lowBoundFrequency, hiBoundFrequency, sampleRate, delegate, running;


#pragma mark Initialize Methods


-(id) initWithSampleRate: (float) rate andDelegate: (id<PitchDetectorDelegate>) initDelegate {
    return [self initWithSampleRate:rate lowBoundFreq:20 hiBoundFreq:4500 andDelegate:initDelegate];
}

-(id) initWithSampleRate: (float) rate lowBoundFreq: (int) low hiBoundFreq: (int) hi andDelegate: (id<PitchDetectorDelegate>) initDelegate {
    self.lowBoundFrequency = low;
    self.hiBoundFrequency = hi;
    self.sampleRate = rate;
    self.delegate = initDelegate;
    
    bufferCapacity = MAX_FRAMES;
    
    log2n = log2f(bufferCapacity); //bins
    n = 1 << log2n;
    
    stride = 1;
    nOver2 = n/2;
    
    fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    A.realp = (float *) malloc(nOver2 * sizeof(float));
    A.imagp = (float *) malloc(nOver2 * sizeof(float));
    logmag = malloc(sizeof(float)*nOver2);
    displayData = malloc(sizeof(float)*n);
    result = malloc(sizeof(float)*nOver2);
    return self;
}

#pragma  mark Insert Samples

- (void) addSamples:(SInt16 *)samples inNumberFrames:(int)inNumberFrames {
    
    // fft.
    UInt32 read = bufferCapacity - index;
    if (read > inNumberFrames) {
        memcpy((SInt16 *)dataBuffer + index, samples, inNumberFrames*sizeof(SInt16));
        index += inNumberFrames;
        return;
    } else {
        // If we enter this conditional, our buffer will be filled and we should
        // perform the FFT.
        memcpy((SInt16 *)dataBuffer + index, samples, read*sizeof(SInt16));
        index = 0;
    }
    //-- window
    
    UInt32 windowSize = bufferCapacity;
    memset(window, 0, windowSize * sizeof(float));
    vDSP_hann_window(window, windowSize, vDSP_HANN_NORM);
    //vDSP_blkman_window(window, windowSize, vDSP_HANN_NORM);
    
    [self convertInt16ToFloat:dataBuffer Output:outputBuffer Capacity:bufferCapacity];
    
    vDSP_vmul(outputBuffer, 1, window, 1, in_real, 1, bufferCapacity);
    
    double sum = 0.0;
    for(int i=0; i < n; ++i) {
        sum += fabsf(outputBuffer[i]);
    }
    printf("AVG: %f\n", sum / n);
    float freq = 0;
    if (sum/n > FILTER)
    {
        float pEST = dsp_acf_II_fft_unscaled(fftSetup, in_real, &A, result, nOver2);
        freq = sampleRate / pEST;
    }
    
    if(freq >= 0 && freq <= self.hiBoundFrequency) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate updatedPitch:freq];
        });
    }
    
}

float dsp_acf_II_fft_unscaled(const FFTSetup setup, float const* signal, COMPLEX_SPLIT* temp, float* acf, vDSP_Length n)
{
    vDSP_Length length_with_pad = 2 * n;
    vDSP_Length log2_length_with_pad = (vDSP_Length) log2(length_with_pad);
    vDSP_Length complex_length_with_pad = length_with_pad / 2; // since there are 2 values per index for both packed and split
    vDSP_Length complex_length = n / 2; // ditto
    
    vDSP_vclr((float*)(signal + n), 1, n);
    
    // compute ifft(conj(fft(x)) * fft(x)) where x is signal + pad
    vDSP_ctoz((DSPComplex*)signal, 2, temp, 1, complex_length_with_pad);
    vDSP_fft_zrip(setup, temp, 1, log2_length_with_pad, FFT_FORWARD);
    dsp_zvcmul_packed(temp, 1, temp, 1, temp, 1, complex_length_with_pad);
    vDSP_fft_zrip(setup, temp, 1, log2_length_with_pad, FFT_INVERSE);
    // we only need the first complex_length results, not the extended padding ones
    vDSP_ztoc(temp, 1, (DSPComplex*)acf, 2, complex_length);
    
    int minP = 20;
    int maxP = complex_length;
    int bestP = minP;
    for ( int p = minP; p <= maxP; p++ )
        if ( acf[p] > acf[bestP] )
            bestP = p;
    
    //  Give up if it's highest value, but not actually a peak.
    //  This can happen if the period is outside the range [minP, maxP]
    if ( acf[bestP] < acf[bestP-1]
        && acf[bestP] < acf[bestP+1] )
    {
        return 0.0;
    }
    
    //  --------------------------------------
    //  Interpolate based on neighboring values
    //  E.g. if value to right is bigger than value to the left,
    //  real peak is a bit to the right of discretized peak.
    //  if left  == right, real peak = mid;
    //  if left  == mid,   real peak = mid-0.5
    //  if right == mid,   real peak = mid+0.5
    
    double mid   = acf[bestP];
    double left  = acf[bestP-1];
    double right = acf[bestP+1];
    
    //assert( 2*mid - left - right > 0.0 );
    
    double shift = 0.5*(right-left) / ( 2*mid - left - right );
    
    double pEst = bestP + shift;
    
    //  -----------------------------------------------
    //  If the range of pitches being searched is greater
    //  than one octave, the basic algo above may make "octave"
    //  errors, in which the period identified is actually some
    //  integer multiple of the real period.  (Makes sense, as
    //  a signal that's periodic with period p is technically
    //  also period with period 2p).
    //
    //  Algorithm is pretty simple: we hypothesize that the real
    //  period is some "submultiple" of the "bestP" above.  To
    //  check it, we see whether the NAC is strong at each of the
    //  hypothetical subpeak positions.  E.g. if we think the real
    //  period is at 1/3 our initial estimate, we check whether the
    //  NAC is strong at 1/3 and 2/3 of the original period estimate.
    
    const double k_subMulThreshold = 0.90;  //  If strength at all submultiple of peak pos are
    //  this strong relative to the peak, assume the
    //  submultiple is the real period.
    
    //  For each possible multiple error (starting with the biggest)
    int maxMul = bestP / minP;
    bool found = false;
    for ( int mul = maxMul; !found && mul >= 1; mul-- )
    {
        //  Check whether all "submultiples" of original
        //  peak are nearly as strong.
        bool subsAllStrong = true;
        
        //  For each submultiple
        for ( int k = 1; k < mul; k++ )
        {
            int subMulP = (int) (k*pEst/mul+0.5);
            //  If it's not strong relative to the peak NAC, then
            //  not all submultiples are strong, so we haven't found
            //  the correct submultiple.
            if ( acf[subMulP] < k_subMulThreshold * acf[bestP] )
                subsAllStrong = false;
            
            //  TODO: Use spline interpolation to get better estimates of nac
            //  magnitudes for non-integer periods in the above comparison
        }
        
        //  If yes, then we're done.   New estimate of
        //  period is "submultiple" of original period.
        if ( subsAllStrong == true )
        {
            found = true;
            pEst = pEst / mul;
        }
    }
    
    return pEst;
}

void dsp_zvcmul_packed(DSPSplitComplex const* a, vDSP_Stride stride_a,
                       DSPSplitComplex const* b, vDSP_Stride stride_b,
                       DSPSplitComplex const* c, vDSP_Stride stride_c, vDSP_Length n)
{
    if (n < 1) {
        return;
    }
    
    float dc_real = a->realp[0] * b->realp[0];
    float nyquist_real = a->imagp[0] * b->imagp[0];
    vDSP_zvcmul(a, stride_a, b, stride_b, c, stride_c, n);
    c->realp[0] = dc_real;
    c->imagp[0] = nyquist_real;
}

- (void)convertInt16ToFloat:(SInt16*) buf Output: (float *) outputBuf Capacity: (size_t) capacity
{
    for(int i = 0; i < capacity; i++) {
        outputBuf[i] = (float) (buf[i]) / 1.0f;
        //if (outputBuf[i] <= FILTER) outputBuf[i] = 0;
    }
}

@end
