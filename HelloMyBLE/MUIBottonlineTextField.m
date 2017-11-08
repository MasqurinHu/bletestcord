//
//  MUIBottonlineTextField.m
//  FieldDispatch
//
//  Created by Ｍasqurin on 2017/7/22.
//  Copyright © 2017年 Ｍasqurin. All rights reserved.
//

#import "MUIBottonlineTextField.h"

@implementation MUIBottonlineTextField
{
    NSLayoutConstraint *scapegoat;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    NSLayoutConstraint *constraint;
    UIView *bottomline = [UIView new];
    bottomline.backgroundColor = [UIColor blackColor];
    [bottomline setTranslatesAutoresizingMaskIntoConstraints:false];
    CGFloat widht = self.frame.size.width;
    [self addSubview:bottomline];
    constraint = [NSLayoutConstraint
                  constraintWithItem:bottomline
                  attribute:NSLayoutAttributeWidth
                  relatedBy:NSLayoutRelationEqual
                  toItem:self
                  attribute:NSLayoutAttributeWidth
                  multiplier:1.0 constant:-widht];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint
                  constraintWithItem:bottomline
                  attribute:NSLayoutAttributeHeight
                  relatedBy:NSLayoutRelationEqual
                  toItem:self
                  attribute:NSLayoutAttributeHeight
                  multiplier:.02 constant:.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint
                  constraintWithItem:bottomline
                  attribute:NSLayoutAttributeTop
                  relatedBy:NSLayoutRelationEqual
                  toItem:self
                  attribute:NSLayoutAttributeBottom
                  multiplier:1.0 constant:-1.0];
    [self addConstraint:constraint];
    constraint = [NSLayoutConstraint
                  constraintWithItem:bottomline
                  attribute:NSLayoutAttributeCenterX
                  relatedBy:NSLayoutRelationEqual
                  toItem:self
                  attribute:NSLayoutAttributeCenterX
                  multiplier:1.0 constant:.0];
    [self addConstraint:constraint];
//    [self setNeedsLayout];
    [self layoutIfNeeded];
    [UIView animateWithDuration:.9 animations:^{
        for (NSLayoutConstraint *tmp in self.constraints) {
            if (tmp.firstItem == bottomline &&
                tmp.firstAttribute == NSLayoutAttributeWidth &&
                tmp.constant == -widht) {
                tmp.constant = 0.0;
                
//                scapegoat = tmp;
//                scapegoat.constant = 0.0;
                //            tmp.constant = 0.0;
                //            scapegoat.constant = 0.0;
                
            }
        }
        [self layoutIfNeeded];
    }];
    
//    scapegoat.constant = 0.0;
    
    
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [UIView animateWithDuration:.6 animations:^{
//            scapegoat.constant = 0.0;
//        }];
//        [self setNeedsLayout]; //更新视图
//        [self layoutIfNeeded];
//    });
}

-(instancetype)initWithPlaseHold:(NSString *)placeHold{
    self = [super init];
    self.placeholder = placeHold;
    return self;
}

//-(instancetype)initAnima{
//    self = [super init];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [UIView animateWithDuration:10.6 animations:^{
//            scapegoat.constant = 0.0;
//            //            [self setNeedsLayout];
//            //            [self layoutIfNeeded];
//        }];
//    });

//    [self.view layoutIfNeeded];
//    [UIView animateWithDuration:3.0 animations:^{

//        NSArray *constrains = self.view.constraints;
//        for (NSLayoutConstraint* constraint in constrains) {
//            if (constraint.firstAttribute == NSLayoutAttributeHeight) {
//                constraint.constant = 300;
//            }
//        }

//        [self.view layoutIfNeeded];
//    } completion:^(BOOL finished) {
//    }];
    
    
    
    
//    return self;
//}
@end
