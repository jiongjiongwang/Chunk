//
//  MIDIDecoder.m
//  Chunk
//
//  Created by dn210 on 16/10/17.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import "MIDIDecoder.h"

#warning 放到PCH文件中，给整个项目使用
#define kFilePath "/Users/wangjiong/Desktop/Trateil.mid"

@implementation MIDIDecoder


+(instancetype)sharedMIDIDecoder
{
    static MIDIDecoder *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [[MIDIDecoder alloc] init];
        
    });


    return instance;
}

#warning 放在这不妥当
//重写midiData的get方法
-(NSData *)midiData
{
    if (_midiData == nil)
    {
        
        _midiData = [NSData dataWithContentsOfFile:@kFilePath];
    }
    return _midiData;
}



@end
