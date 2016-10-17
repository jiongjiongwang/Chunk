//
//  MIDIDecoder.h
//  Chunk
//
//  Created by dn210 on 16/10/17.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import <Foundation/Foundation.h>
//解码MIDI文件的工具
@interface MIDIDecoder : NSObject

//单例类
+(instancetype)sharedMIDIDecoder;

//MIDI源文件转换成NSData来存放
@property (nonatomic,strong)NSData *midiData;

@end
