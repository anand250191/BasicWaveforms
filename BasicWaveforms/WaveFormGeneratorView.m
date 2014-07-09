//
//  MainViewController.m
//  audio1
//
//  Created by Anand on 21/06/14.
//  Copyright (c) 2014 Anand. All rights reserved.
//

#import "WaveFormGeneratorView.h"
#import <AudioToolbox/AudioToolbox.h>

#define SAMPLING_RATE 44100
#define BIT_DEPTH 16
#define TONE_DURATION 10.0

@interface WaveFormGeneratorView (){
    NSURL *_fileURL;
    float _toneFreq;
    WaveformType _currentWaveformType;
    
    AudioStreamBasicDescription _basicDesc;
}

@end

@implementation WaveFormGeneratorView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    memset(&_basicDesc, 0, sizeof(_basicDesc)); // 7
    _basicDesc.mSampleRate = SAMPLING_RATE; // 8
    _basicDesc.mFormatID = kAudioFormatLinearPCM;
    _basicDesc.mFormatFlags = kAudioFormatFlagIsBigEndian |
    kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    _basicDesc.mBitsPerChannel = BIT_DEPTH;
    _basicDesc.mChannelsPerFrame = 1;
    _basicDesc.mFramesPerPacket = 1;
    _basicDesc.mBytesPerFrame = 2;
    _basicDesc.mBytesPerPacket = 2;
    
    [_waveformTypeSegmentedControl setTarget:self];
    [_waveformTypeSegmentedControl setAction:@selector(segControlClicked:)];
    _toneFrequencyTextField.delegate = self;
    _fileNameTextField.delegate = self;
    
    [_waveformTypeSegmentedControl setSelectedSegment:0];
    [_toneFrequencyTextField setFloatValue:261.1];
    [_fileNameTextField setStringValue:@"squarewave.aif"];
    
    _currentWaveformType = SquareWave;
    _toneFreq = [_toneFrequencyTextField floatValue];
    [self updateDestinationFileURL];
}

- (void)controlTextDidChange:(NSNotification *)notif
{
    NSTextField *textField = [notif object];
    
    if([textField isEqual:_toneFrequencyTextField]){
        _toneFreq = [_toneFrequencyTextField floatValue];
    }else if([textField isEqual:_fileNameTextField]){
        [self updateDestinationFileURL];
    }
}

- (IBAction)segControlClicked:(id)sender
{
    NSInteger clickedSegment = [_waveformTypeSegmentedControl selectedSegment];
    switch (clickedSegment) {
        case 0:
            _currentWaveformType = SquareWave;
            break;
        case 1:
            _currentWaveformType = SawtoothWave;
            break;
        case 2:
            _currentWaveformType = SineWave;
            break;
            
        default:
            break;
    }
}

- (void)updateDestinationFileURL
{
    NSString *fileName = [_fileNameTextField stringValue];
    NSString* filePath = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:fileName];

    _fileURL = [NSURL fileURLWithPath:filePath];
}

- (IBAction)createAudioFile:(id)sender
{
    AudioFileID audioFile;
    OSStatus fileCreateErr = noErr;
    
    fileCreateErr = AudioFileCreateWithURL((__bridge CFURLRef)_fileURL, kAudioFileAIFFType, &_basicDesc, kAudioFileFlags_EraseFile, &audioFile);

    if(fileCreateErr != noErr){
        return;
    }
    
    switch (_currentWaveformType) {
        case SquareWave:
            [self writeSquareWaveSamplesIntoAudioFile:audioFile];
            break;
        case SawtoothWave:
            [self writeSawtoothWaveSamplesIntoAudioFile:audioFile];
            break;
        case SineWave:
            [self writeSineWaveSamplesIntoAudioFile:audioFile];
            break;
            
        default:
            break;
    }
}

- (void)writeSquareWaveSamplesIntoAudioFile:(AudioFileID)file
{
    long totalSampleCount = SAMPLING_RATE * TONE_DURATION;
    long currSampleCount = 0;
    UInt32 bytesToWrite = 2;
    double wavelengthInSamples = SAMPLING_RATE / _toneFreq;
    OSStatus fileWriteErr = noErr;
    while (currSampleCount < totalSampleCount) {
        for (int i=0; i<wavelengthInSamples; i++) {
            SInt16 sample;
            if (i < wavelengthInSamples/2) {
                sample = CFSwapInt16HostToBig (SHRT_MAX);
            } else {
                sample = CFSwapInt16HostToBig (SHRT_MIN);
            }
            
            fileWriteErr = AudioFileWriteBytes(file, false, currSampleCount*2, &bytesToWrite, &sample);
            assert (fileWriteErr == noErr);
            
            currSampleCount++;
        }
    }
    
    AudioFileClose(file);
}

- (void)writeSawtoothWaveSamplesIntoAudioFile:(AudioFileID)file
{
    long totalSampleCount = SAMPLING_RATE * TONE_DURATION;
    long currSampleCount = 0;
    UInt32 bytesToWrite = 2;
    double wavelengthInSamples = SAMPLING_RATE / _toneFreq;
    OSStatus fileWriteErr = noErr;
    while (currSampleCount < totalSampleCount) {
        for (int i=0; i<wavelengthInSamples; i++) {
            SInt16 sample = CFSwapInt16HostToBig (((i / wavelengthInSamples) * SHRT_MAX *2) - SHRT_MAX);
            
            fileWriteErr = AudioFileWriteBytes(file, false, currSampleCount*2, &bytesToWrite, &sample);
            assert (fileWriteErr == noErr);
            
            currSampleCount++;
        }
    }
    
    AudioFileClose(file);
}

- (void)writeSineWaveSamplesIntoAudioFile:(AudioFileID)file
{
    long totalSampleCount = SAMPLING_RATE * TONE_DURATION;
    long currSampleCount = 0;
    UInt32 bytesToWrite = 2;
    double wavelengthInSamples = SAMPLING_RATE / _toneFreq;
    OSStatus fileWriteErr = noErr;
    while (currSampleCount < totalSampleCount) {
        for (int i=0; i<wavelengthInSamples; i++) {
            SInt16 sample = CFSwapInt16HostToBig ((SInt16) SHRT_MAX * sin (2 * M_PI * (i / wavelengthInSamples)));
            
            fileWriteErr = AudioFileWriteBytes(file, false, currSampleCount*2, &bytesToWrite, &sample);
            assert (fileWriteErr == noErr);
            
            currSampleCount++;
        }
    }
    
    AudioFileClose(file);
}

@end
