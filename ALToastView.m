//
//  ALToastView.h
//
//  Created by Alex Leutgöb on 17.07.11.
//  Copyright 2011 alexleutgoeb.com. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import <QuartzCore/QuartzCore.h>
#import "ALToastView.h"


// Set default visibility duration
static const CGFloat kDuration = 2;

// Set default font size
static const int fontSize = 16;

// Set default padding arround the label
static const int leftPadding = 10;
static const int topPadding = 5;
static const int distanceToBottom = 40;

// Static toastview queue variable
static NSMutableArray *toasts;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@interface ALToastView ()

@property (nonatomic, readonly) UILabel *textLabel;
@property (nonatomic) int duration;
@property (nonatomic) UIView *parentView;

- (void)fadeToastOut;
+ (void)nextToastInView:(UIView *)parentView withDuration:(int)duration;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@implementation ALToastView

@synthesize textLabel = _textLabel, duration = _duration;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)initWithText:(NSString *)text andParentView:(UIView *)parentView {
    if ((self = [self initWithFrame:CGRectZero])) {
        self.parentView = parentView;
        
        // Add corner radius
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.6];
        self.layer.cornerRadius = 5;
        self.autoresizingMask = UIViewAutoresizingNone;
        self.autoresizesSubviews = NO;
        
        // Compute the label's size
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:fontSize]}];
        CGRect rect = [attributedText boundingRectWithSize:(CGSize){self.parentView.bounds.size.width - 2 * leftPadding, self.parentView.bounds.size.height / 2}
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
        
        // Init and add label
        _textLabel = [[UILabel alloc] initWithFrame:rect];
        _textLabel.text = text;
        _textLabel.font = [UIFont systemFontOfSize:fontSize];
        _textLabel.minimumScaleFactor = 12.0/16.0;
        _textLabel.textColor = [UIColor whiteColor];
        _textLabel.adjustsFontSizeToFitWidth = YES;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.numberOfLines = 3;
        
        self.duration = kDuration;
        
        [self addSubview:_textLabel];
        _textLabel.frame = CGRectOffset(_textLabel.frame, leftPadding, topPadding);
        
        [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification  object:nil];
    }
    
    return self;
}


- (void)dealloc {
    [_textLabel release];
    
    [super dealloc];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

+ (void)toastInView:(UIView *)parentView withText:(NSString *)text {
    [ALToastView toastInView:parentView withText:text andBackgroundColor:nil andDuration:kDuration];
}

+ (void)toastInView:(UIView *)parentView withText:(NSString *)text andBackgroundColor:(UIColor *)backgroundColor {
    [ALToastView toastInView:parentView withText:text andBackgroundColor:backgroundColor andDuration:kDuration];
}

+ (void)toastInView:(UIView *)parentView withText:(NSString *)text andDuration:(int)duration {
    [ALToastView toastInView:parentView withText:text andBackgroundColor:nil andDuration:duration];
}

+ (void)toastInView:(UIView *)parentView withText:(NSString *)text andBackgroundColor:(UIColor *)backgroundColor andDuration:(int)duration {
    // Add new instance to queue
    ALToastView *view = [[ALToastView alloc] initWithText:text andParentView:parentView];
    
    if (backgroundColor) {
        view.backgroundColor = backgroundColor;
    }
    
    if (duration != kDuration) {
        view.duration = duration;
    }
    
    CGFloat lWidth = view.textLabel.frame.size.width;
    CGFloat lHeight = view.textLabel.frame.size.height;
    CGFloat pWidth = parentView.frame.size.width;
    CGFloat pHeight = parentView.frame.size.height;
    
    // Change toastview frame
    view.frame = CGRectMake((pWidth - lWidth - 2 * leftPadding) / 2., pHeight - lHeight - distanceToBottom, lWidth + 2 * leftPadding, lHeight + 2 * topPadding);
    view.alpha = 0.0f;
    
    if (toasts == nil) {
        toasts = [[NSMutableArray alloc] initWithCapacity:1];
        [toasts addObject:view];
        [ALToastView nextToastInView:parentView withDuration:duration];
    }
    else {
        [toasts addObject:view];
    }
    
    [view release];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (void)orientationChanged:(NSNotification *)notification {
    [self adjustViewsForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void) adjustViewsForOrientation:(UIInterfaceOrientation) orientation {
    for (ALToastView *view in toasts) {
        // Update all toast view's frames
        CGFloat lWidth = view.textLabel.frame.size.width;
        CGFloat lHeight = view.textLabel.frame.size.height;
        CGFloat pWidth = view.parentView.frame.size.width;
        CGFloat pHeight = view.parentView.frame.size.height;
        
        view.frame = CGRectMake((pWidth - lWidth - 2 * leftPadding) / 2., pHeight - lHeight - distanceToBottom, lWidth + 2 * leftPadding, lHeight + 2 * topPadding);
    }
}

- (void)fadeToastOut {
    // Fade in parent view
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction
     
                     animations:^{
                         self.alpha = 0.f;
                     }
                     completion:^(BOOL finished){
                         UIView *parentView = self.superview;
                         [self removeFromSuperview];
                         
                         // Remove current view from array
                         [toasts removeObject:self];
                         if ([toasts count] == 0) {
                             [toasts release];
                             toasts = nil;
                         }
                         else
                             [ALToastView nextToastInView:parentView withDuration:[(ALToastView *)[toasts objectAtIndex:0] duration]];
                     }];
}

+ (void)nextToastInView:(UIView *)parentView withDuration:(int)duration {
    if ([toasts count] > 0) {
        ALToastView *view = [toasts objectAtIndex:0];
        
        // Fade into parent view
        [parentView addSubview:view];
        [UIView animateWithDuration:.5  delay:0 options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             view.alpha = 1.0;
                         } completion:^(BOOL finished){}];
        
        // Start timer for fade out
        [view performSelector:@selector(fadeToastOut) withObject:nil afterDelay:duration];
    }
}

@end
