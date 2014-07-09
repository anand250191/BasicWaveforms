//
//  MainViewController.h
//  audio1
//
//  Created by Anand on 21/06/14.
//  Copyright (c) 2014 Anand. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum{
    SquareWave = 0,
    SawtoothWave = 1,
    SineWave = 2,
}WaveformType;

@interface WaveFormGeneratorView : NSView <NSTextFieldDelegate>

@property (nonatomic, strong) IBOutlet NSSegmentedControl *waveformTypeSegmentedControl;
@property (nonatomic, strong) IBOutlet NSTextField *toneFrequencyTextField;
@property (nonatomic, strong) IBOutlet NSTextField *fileNameTextField;

- (IBAction)createAudioFile:(id)sender;

@end
