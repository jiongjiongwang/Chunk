//
//  MIDISampler.m
//  MidiOX
//
//  Created by zhl on 13-11-2.
//  Copyright (c) 2013年 Medeli. All rights reserved.
//

#import "MIDISampler.h"
#import <AssertMacros.h>

#if __has_feature(objc_arc) && __clang_major__ >=3
#define PP_ARC_ENABLED 1
#endif

char Drum_Banks[] = {0,8,16,24,25,30,32,40,48};

@implementation MIDISampler

- (void)dealloc
{
    [self stopAudioProcessingGraph];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
#ifndef PP_ARC_ENABLED
    [super dealloc];
#endif
}
- (id)init
{
    BOOL audioSessionActivated = [self setupAudioSession];
    NSAssert (audioSessionActivated == YES, @"Unable to set up audio session.");
    
    // Create the audio processing graph; place references to the graph and to the Sampler unit
    // into the processingGraph and samplerUnit instance variables.
    [self createAUGraph];
    [self configureAndStartAudioProcessingGraph: m_processingGraph];
    [self registerForUIApplicationNotifications];
    
    
    for (int i = 0; i < SAMPLE_NODE_COUNT; ++i)
    {
        m_arrBankPatch[i].msb = kAUSampler_DefaultMelodicBankMSB;
        m_arrBankPatch[i].lsb = kAUSampler_DefaultBankLSB;
        m_arrBankPatch[i].bank = 0xff;
    }
    
    
    NSString *presetURLPath = [[NSBundle mainBundle] pathForResource:@"GS" ofType:@"sf2"];
    m_presetURL = [NSURL fileURLWithPath:presetURLPath];
    //Load Default
    [self loadFromDLSOrSoundFont:m_presetURL withBankMSB:kAUSampler_DefaultMelodicBankMSB withBankLSB:kAUSampler_DefaultBankLSB withPatch:0 withChannel:0];
    
    [self loadFromDLSOrSoundFont:m_presetURL withBankMSB:kAUSampler_DefaultPercussionBankMSB withBankLSB:kAUSampler_DefaultBankLSB withPatch:0 withChannel:9];
    
    return self;
    
}

// Create an audio processing graph.
- (BOOL) createAUGraph
{
	OSStatus result = noErr;
	AUNode samplerNode[SAMPLE_NODE_COUNT], ioNode, mixerNode;
    
    // Instantiate an audio processing graph
	result = NewAUGraph (&m_processingGraph);
    NSCAssert (result == noErr, @"Unable to create an AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Sampler Node
	AudioComponentDescription samplerACD;
    samplerACD.componentType             = kAudioUnitType_MusicDevice;
	samplerACD.componentSubType          = kAudioUnitSubType_Sampler;
	samplerACD.componentManufacturer     = kAudioUnitManufacturer_Apple;
	samplerACD.componentFlags            = 0;
	samplerACD.componentFlagsMask        = 0;
    for (int i = 0; i < SAMPLE_NODE_COUNT; ++i)
    {
        result = AUGraphAddNode (m_processingGraph, &samplerACD, &samplerNode[i]);
        NSCAssert (result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    }
    
    //Mixer Node
    AudioComponentDescription mixerACD;
    mixerACD.componentType = kAudioUnitType_Mixer;
    mixerACD.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerACD.componentManufacturer = kAudioUnitManufacturer_Apple;
    mixerACD.componentFlags = 0;
    mixerACD.componentFlagsMask = 0;
    result = AUGraphAddNode (m_processingGraph, &mixerACD, &mixerNode);
    NSCAssert (result == noErr, @"Unable to add the Mixer unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Output Node
	AudioComponentDescription outputACD;
    outputACD.componentType             = kAudioUnitType_Output;
	outputACD.componentSubType          = kAudioUnitSubType_RemoteIO;
	outputACD.componentManufacturer     = kAudioUnitManufacturer_Apple;
	outputACD.componentFlags            = 0;
	outputACD.componentFlagsMask        = 0;
	result = AUGraphAddNode (m_processingGraph, &outputACD, &ioNode);
    NSCAssert (result == noErr, @"Unable to add the Output unit to the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    
    // Open the graph
	result = AUGraphOpen (m_processingGraph);
    NSCAssert (result == noErr, @"Unable to open the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Obtain a reference to the Sampler unit from its node
    for (int i = 0; i < SAMPLE_NODE_COUNT; ++i)
    {
        result = AUGraphNodeInfo (m_processingGraph, samplerNode[i], 0, &m_arrBankPatch[i].samplerUnit);
        NSCAssert (result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    }
    
	// Obtain a reference to the Mixer unit from its node
	result = AUGraphNodeInfo (m_processingGraph, mixerNode, 0, &m_mixerUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the Mixer unit. Error code: %d '%.4s'", (int) result, (const char *)&result);

	// Obtain a reference to the I/O unit from its node
	result = AUGraphNodeInfo (m_processingGraph, ioNode, 0, &m_ioUnit);
    NSCAssert (result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Initialize I/O unit
    result = AudioUnitInitialize (m_ioUnit);
    NSCAssert (result == noErr, @"Unable to initialize the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    UInt32 framesPerSlice = 0;
    UInt32 framesPerSlicePropertySize = sizeof (framesPerSlice);

    // Set the I/O unit's output sample rate.
    result = AudioUnitSetProperty(m_ioUnit,
                                  kAudioUnitProperty_SampleRate,
                                  kAudioUnitScope_Output,
                                  0,
                                  &m_graphSampleRate,
                                  sizeof(m_graphSampleRate));
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    // Obtain the value of the maximum-frames-per-slice from the I/O unit.
    result = AudioUnitGetProperty(m_ioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0,
                                  &framesPerSlice,
                                  &framesPerSlicePropertySize);
    NSCAssert (result == noErr, @"Unable to retrieve the maximum frames per slice property from the I/O unit. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    framesPerSlice = 4096*16;
    // Set the Mixer unit's output sample rate.
    result = AudioUnitSetProperty(m_ioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0,
                                  &framesPerSlice,
                                  framesPerSlicePropertySize);
    if (result != noErr) { NSLog(@"AudioUnitSetProperty maximumFramesPerSlice Error"); }
    
    // Set the Mixer unit's output sample rate.
    result = AudioUnitSetProperty(m_mixerUnit,
                                  kAudioUnitProperty_SampleRate,
                                  kAudioUnitScope_Output,
                                  0,
                                  &m_graphSampleRate,
                                  sizeof(m_graphSampleRate));
    NSAssert (result == noErr, @"AudioUnitSetProperty (set Mixer unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    //Set Max Frames per Slice for MixerUnit
    result = AudioUnitSetProperty(m_mixerUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0,
                                  &framesPerSlice,
                                  framesPerSlicePropertySize);
    if (result != noErr) { NSLog(@"AudioUnitSetProperty maximumFramesPerSlice Error"); }
    
    //Set Bus Count of MixerUnit
	UInt32 countbuses = SAMPLE_NODE_COUNT;
    result = AudioUnitSetProperty(m_mixerUnit,
                                  kAudioUnitProperty_ElementCount,
                                  kAudioUnitScope_Input,
                                  0,
                                  &countbuses,
                                  sizeof(countbuses));
    if (result != noErr) { NSLog(@"AudioUnitSetProperty kAudioUnitProperty_ElementCount Error"); }
    
    for (int i = 0; i < SAMPLE_NODE_COUNT; ++i)
    {
        // Set the Sampler unit's output sample rate.
        result = AudioUnitSetProperty(m_arrBankPatch[i].samplerUnit,
                                      kAudioUnitProperty_SampleRate,
                                      kAudioUnitScope_Output,
                                      0,
                                      &m_graphSampleRate,
                                      sizeof(m_graphSampleRate));
        NSAssert (result == noErr, @"AudioUnitSetProperty (set Sampler unit output stream sample rate). Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Set the Sampler unit's maximum frames-per-slice.
        result = AudioUnitSetProperty (m_arrBankPatch[i].samplerUnit,
                                       kAudioUnitProperty_MaximumFramesPerSlice,
                                       kAudioUnitScope_Global,
                                       0,
                                       &framesPerSlice,
                                       framesPerSlicePropertySize);
        NSAssert( result == noErr, @"AudioUnitSetProperty (set Sampler unit maximum frames per slice). Error code: %d '%.4s'", (int) result, (const char *)&result);
    }
    
    // Connect the Sampler unit to the mixer unit
    for (int i = 0; i < SAMPLE_NODE_COUNT; ++i)
    {
        result = AUGraphConnectNodeInput (m_processingGraph, samplerNode[i], 0, mixerNode, i);
        NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    }
    // Connect the mixer unit to the io unit
    result = AUGraphConnectNodeInput (m_processingGraph, mixerNode, 0, ioNode, 0);
    NSCAssert (result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
    
    return YES;
}

// audio units, initialize it, and start it.
- (void) configureAndStartAudioProcessingGraph: (AUGraph) graph
{
    OSStatus result = noErr;
    
    if (graph)
    {
        // Initialize the audio processing graph.
        result = AUGraphInitialize (graph);
        NSAssert (result == noErr, @"Unable to initialze AUGraph object. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Start the graph
        result = AUGraphStart (graph);
        NSAssert (result == noErr, @"Unable to start audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
        
        // Print out the graph to the console
        //CAShow (graph);
    }
}




// Set up the audio session for this app.
- (BOOL) setupAudioSession
{
    AVAudioSession *mySession = [AVAudioSession sharedInstance];
    
    // Specify that this object is the delegate of the audio session, so that
    //    this object's endInterruption method will be invoked when needed.
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleInterruption:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: [AVAudioSession sharedInstance]];
    
    // Assign the Playback category to the audio session. This category supports
    //    audio output with the Ring/Silent switch in the Silent position.
    NSError *audioSessionError = nil;
    [mySession setCategory: AVAudioSessionCategoryPlayback error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting audio session category."); return NO;}
    
    // Request a desired hardware sample rate.
    m_graphSampleRate = 44100.0;
    
    [mySession setPreferredSampleRate: m_graphSampleRate error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error setting preferred hardware sample rate."); return NO;}
    
    // Activate the audio session
    [mySession setActive: YES error: &audioSessionError];
    if (audioSessionError != nil) {NSLog (@"Error activating the audio session."); return NO;}
    
    // Obtain the actual hardware sample rate and store it for later use in the audio processing graph.
    m_graphSampleRate = [mySession sampleRate];
    
    return YES;
}



// Stop the audio processing graph
- (void) stopAudioProcessingGraph
{
    OSStatus result = noErr;
	if (m_processingGraph)
        result = AUGraphStop(m_processingGraph);
    NSAssert (result == noErr, @"Unable to stop the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

// Restart the audio processing graph
- (void) restartAudioProcessingGraph
{
    OSStatus result = noErr;
	if (m_processingGraph)
        result = AUGraphStart (m_processingGraph);
    NSAssert (result == noErr, @"Unable to restart the audio processing graph. Error code: %d '%.4s'", (int) result, (const char *)&result);
}

#pragma mark -
#pragma mark Audio session AVAudioSessionInterruptionNotification
- (void) handleInterruption:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSUInteger interuptionType = (NSUInteger)[interuptionDict valueForKey:AVAudioSessionInterruptionTypeKey];
    
    if (interuptionType == AVAudioSessionInterruptionTypeBegan)
    {
        [self beginInterruption];
    }
    else if (interuptionType == AVAudioSessionInterruptionTypeEnded)
    {
        [interuptionDict valueForKey:AVAudioSessionInterruptionOptionKey];
        [self endInterruption:NO];
    }
}


// Respond to an audio interruption, such as a phone call or a Clock alarm.
- (void) beginInterruption
{
    NSLog(@"beginInterruption");

    [self MIDIAllNotesOff];
    
    [self stopAudioProcessingGraph];
}
// Respond to the ending of an audio interruption.
- (void) endInterruption:(BOOL)requireResume
{
    NSLog(@"endInterruption");
    NSError *endInterruptionError = nil;
    [[AVAudioSession sharedInstance] setActive: YES
                                         error: &endInterruptionError];
    
    if (endInterruptionError != nil)
    {
        NSLog (@"Unable to reactivate the audio session.");
        return;
    }
    
    if (requireResume)
    {
        /*
         In a shipping application, check here to see if the hardware sample rate changed from
         its previous value by comparing it to graphSampleRate. If it did change, reconfigure
         the ioInputStreamFormat struct to use the new sample rate, and set the new stream
         format on the two audio units. (On the mixer, you just need to change the sample rate).
         
         Then call AUGraphUpdate on the graph before starting it.
         */
        
        [self restartAudioProcessingGraph];
    }
}

#pragma mark - Application state management
// The audio processing graph should not run when the screen is locked or when the app has
//  transitioned to the background, because there can be no user interaction in those states.
//  (Leaving the graph running with the screen locked wastes a significant amount of energy.)
//
// Responding to these UIApplication notifications allows this class to stop and restart the
//    graph as appropriate.
- (void) registerForUIApplicationNotifications
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver: self
                           selector: @selector (handleResigningActive:)
                               name: UIApplicationWillResignActiveNotification
                             object: [UIApplication sharedApplication]];
    
    [notificationCenter addObserver: self
                           selector: @selector (handleBecomingActive:)
                               name: UIApplicationDidBecomeActiveNotification
                             object: [UIApplication sharedApplication]];
}


- (void) handleResigningActive: (id) notification
{
    NSLog(@"handleResigningActive");

    [self MIDIAllNotesOff];
    
    [self stopAudioProcessingGraph];
}


- (void) handleBecomingActive: (id) notification
{
    NSLog(@"handleBecomingActive");
    [self restartAudioProcessingGraph];
}

- (void) MIDIShortMsg:(Byte)status withData1:(Byte)data1 withData2:(Byte)data2
{
    Byte chn = status & 0x0f;
    OSStatus result;
    switch (status & 0xF0)
    {
        case 0x80:
        case 0x90:
            //NSLog(@"%.2X %.2X %.2X", status, data1, data2);
            result = MusicDeviceMIDIEvent(m_arrBankPatch[chn].samplerUnit, status, data1, data2, 0);
            NSCAssert (result == noErr, @"Unable to play . Error code:%d '%.4s'", (int) result, (const char *)&result);
            break;
        case 0xA0:
        case 0xB0:
        case 0xD0:
        case 0xE0:
            //NSLog(@"%.2X %.2X %.2X", status, data1, data2);
            result = MusicDeviceMIDIEvent(m_arrBankPatch[chn].samplerUnit, status, data1, data2, 0);
            NSCAssert (result == noErr, @"Unable to play . Error code:%d '%.4s'", (int) result, (const char *)&result);
            break;
        case 0xC0:
            if (chn == 9)
            {
                [self loadFromDLSOrSoundFont:m_presetURL withBankMSB:kAUSampler_DefaultPercussionBankMSB withBankLSB:kAUSampler_DefaultBankLSB withPatch:data1 withChannel:chn];
            }
            else
            {
                [self loadFromDLSOrSoundFont:m_presetURL withBankMSB:kAUSampler_DefaultMelodicBankMSB withBankLSB:kAUSampler_DefaultBankLSB withPatch:data1 withChannel:chn];
            }
            break;
            
        default:
            break;
    }
}

- (void) MIDISysEx:(const UInt8 *)data withLength:length
{
    /*
    extern OSStatus
    MusicDeviceSysEx(		MusicDeviceComponent	inUnit,
                     const UInt8 *			inData,
                     UInt32					inLength)							__OSX_AVAILABLE_STARTING(__MAC_10_0,__IPHONE_5_0);
     */
}

- (void) MIDIAllNotesOff
{
    OSStatus result;
    for (int i = 0; i < 16; ++i)
    {
        result = MusicDeviceMIDIEvent(m_arrBankPatch[i].samplerUnit, 0xB0 | i, 0x7B, 0, 0);
        NSCAssert (result == noErr, @"Unable to play . Error code:%d '%.4s'", (int) result, (const char *)&result);
    }
}
- (OSStatus) loadFromDLSOrSoundFont: (NSURL *)bankURL withBankMSB:(UInt8) msb withBankLSB:(UInt8) lsb withPatch: (int)presetNumber withChannel: (int)channelNumber
{
    if ((m_arrBankPatch[channelNumber].msb == msb) && \
        (m_arrBankPatch[channelNumber].lsb == lsb) && \
        (m_arrBankPatch[channelNumber].bank == presetNumber))
    {
        //Skip same bank
        return noErr;
    }
    NSLog(@"Load %d %d %d %d", msb, lsb, presetNumber, channelNumber);

    if (msb == kAUSampler_DefaultPercussionBankMSB)
    {//Drum Kit
        int count = sizeof(Drum_Banks);
        for (int i = count - 1; i >= 0; --i)
        {
            if (presetNumber >= Drum_Banks[i])
            {
                presetNumber = Drum_Banks[i];
                break;
            }
        }
    }
    
    OSStatus result = noErr;
    
    // fill out a bank preset data structure
    AUSamplerBankPresetData bpdata;
    bpdata.bankURL  = (__bridge CFURLRef) bankURL;
    bpdata.bankMSB  = msb;
    bpdata.bankLSB  = lsb;
    bpdata.presetID = (UInt8) presetNumber;
    
    // set the kAUSamplerProperty_LoadPresetFromBank property
    result = AudioUnitSetProperty(m_arrBankPatch[channelNumber].samplerUnit,
                                  kAUSamplerProperty_LoadPresetFromBank,
                                  kAudioUnitScope_Global,
                                  0,
                                  &bpdata,
                                  sizeof(AUSamplerBankPresetData));
    
    if (result == noErr)
    {
        m_arrBankPatch[channelNumber].msb = msb;
        m_arrBankPatch[channelNumber].lsb = lsb;
        m_arrBankPatch[channelNumber].bank = presetNumber;
    }
    else
    {
        NSLog(@"Load %d %d %d %d Error", msb, lsb, presetNumber, channelNumber);
        m_arrBankPatch[channelNumber].bank = 0xFF;
    }
    return result;
}

- (void) MIDIPreloadBank:(const unsigned char *)data
{
    for (int i = 0; i < SAMPLE_NODE_COUNT; ++i)
    {
        if (data[i] < 0x80)
        {
            if (i == 9)
            {
                [self loadFromDLSOrSoundFont:m_presetURL withBankMSB:kAUSampler_DefaultPercussionBankMSB withBankLSB:kAUSampler_DefaultBankLSB withPatch:data[i] withChannel:i];
            }
            else
            {
                [self loadFromDLSOrSoundFont:m_presetURL withBankMSB:kAUSampler_DefaultMelodicBankMSB withBankLSB:kAUSampler_DefaultBankLSB withPatch:data[i] withChannel:i];
            }
        }
    }
}
@end
