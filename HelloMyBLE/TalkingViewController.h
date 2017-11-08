//
//  TalkingViewController.h
//  HelloMyBLE
//
//  Created by Ｍasqurin on 2017/7/26.
//  Copyright © 2017年 Ｍasqurin. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreBluetooth/CoreBluetooth.h>

@interface TalkingViewController : UIViewController

@property (nonatomic,strong) CBCharacteristic *targetCharacteristic;

@end
