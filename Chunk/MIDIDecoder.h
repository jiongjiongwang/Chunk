//
//  MIDIDecoder.h
//  Chunk
//
//  Created by dn210 on 16/10/17.
//  Copyright © 2016年 dn210. All rights reserved.
//

#import <Foundation/Foundation.h>
//解码MIDI文件
@interface MIDIDecoder : NSObject


//传入MIDI文件的路径来初始化NSData数据
@property (nonatomic,strong)NSData *midiData;


@end
