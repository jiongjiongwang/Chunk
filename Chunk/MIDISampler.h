//
//  MIDISampler
//  MidiOX
//
//  Created by zhl on 13-11-2.
//  Copyright (c) 2013年 Medeli. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#define SAMPLE_NODE_COUNT 16

typedef struct
{
    UInt8 msb;
    UInt8 lsb;
    UInt8 bank;
    AudioUnit samplerUnit;
}BankPatch;

@interface MIDISampler : NSObject
{
    AUGraph   m_processingGraph;
    BankPatch m_arrBankPatch[SAMPLE_NODE_COUNT];
    AudioUnit m_mixerUnit;
    AudioUnit m_ioUnit;
    Float64   m_graphSampleRate;
    NSURL     *m_presetURL;
}

- (void) MIDIPreloadBank:(const unsigned char *)data;
- (void) MIDIShortMsg:(Byte)status withData1:(Byte)data1 withData2:(Byte)data2;
- (void) MIDISysEx:(const UInt8 *)data withLength:length;
- (void) MIDIAllNotesOff;
@end
