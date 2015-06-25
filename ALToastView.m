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


// Set visibility duration
static const CGFloat kDuration = 2;


// Static dictionary with queue variables per each UIView
static NSMutableDictionary *dtoasts;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@interface ALToastView ()

@property (nonatomic, readonly) UILabel *textLabel;

- (void)fadeToastOut;
+ (void)nextToastInView:(UIView *)parentView;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@implementation ALToastView

@synthesize textLabel = _textLabel;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)initWithText:(NSString *)text withView:(UIView*) pview {
	if ((self = [self initWithFrame:CGRectZero])) {
		// Add corner radius
		self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.6];
		self.layer.cornerRadius = 5;
		self.autoresizingMask = UIViewAutoresizingNone;
		self.autoresizesSubviews = NO;
        _parentView = pview;
		
		// Init and add label
		_textLabel = [[UILabel alloc] init];
		_textLabel.text = text;
		_textLabel.minimumFontSize = 14;
		_textLabel.font = [UIFont systemFontOfSize:14];
		_textLabel.textColor = [UIColor whiteColor];
		_textLabel.adjustsFontSizeToFitWidth = NO;
		_textLabel.backgroundColor = [UIColor clearColor];
		[_textLabel sizeToFit];
		
		[self addSubview:_textLabel];
		_textLabel.frame = CGRectOffset(_textLabel.frame, 10, 5);
	}
	
	return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

+ (void)toastInView:(UIView *)parentView withText:(NSString *)text {
	// Add new instance to queue
	ALToastView *view = [[ALToastView alloc] initWithText:text withView:parentView];
  
	CGFloat lWidth = view.textLabel.frame.size.width;
	CGFloat lHeight = view.textLabel.frame.size.height;
	CGFloat pWidth = parentView.frame.size.width;
	CGFloat pHeight = parentView.frame.size.height;

    // Change toastview frame
	view.frame = CGRectMake(((pWidth - lWidth - 20) / 2.), (pHeight - lHeight - 60), lWidth + 20, lHeight + 10);
	view.alpha = 0.0f;
	
    NSString *key = [NSString stringWithFormat:@"%p", parentView];
    
    if (dtoasts == nil) {
        dtoasts = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    NSMutableArray *ltoasts;

    @synchronized(dtoasts) {
        ltoasts = [dtoasts objectForKey:key];
        if(ltoasts == nil) {
            ltoasts = [[NSMutableArray alloc] initWithCapacity:1];
            [ltoasts addObject:view];
            [dtoasts setObject:ltoasts forKey: key];
            [ALToastView nextToastInView:parentView withViewList:ltoasts];
        } else {
            [ltoasts addObject:view];
        }
    }
    
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (void)fadeToastOut {
    // Fade in parent view
    NSMutableArray *ltoasts;
    NSString *key = [NSString stringWithFormat:@"%p", self.parentView];
    ltoasts = [dtoasts objectForKey:key];
    
    if(ltoasts == nil) {
        NSLog(@"fadeToastOut: ltoast is nil");
        return;
    }
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction
     
                     animations:^{
                         self.alpha = 0.f;
                     }
                     completion:^(BOOL finished){
                         UIView *parentView = self.superview;
                         [self removeFromSuperview];
                         
                         @synchronized(dtoasts) {
                             NSMutableArray *ltoasts;
                             NSString *key = [NSString stringWithFormat:@"%p", self.parentView];
                             ltoasts = [dtoasts objectForKey:key];
                             
                             if(ltoasts != nil) {
                                 // Remove current view from array
                                 [ltoasts removeObject:self];
                                 if ([ltoasts count] == 0) {
                                     [dtoasts removeObjectForKey:key];
                                 }
                                 else
                                     [ALToastView nextToastInView:parentView withViewList:ltoasts];
                             }
                         }
                     }];
}


+ (void)nextToastInView:(UIView *)parentView withViewList:(NSMutableArray*) ltoasts{
    @synchronized(dtoasts) {
        if ([ltoasts count] > 0) {
            ALToastView *view = [ltoasts objectAtIndex:0];
            
            // Fade into parent view
            [parentView addSubview:view];
            [UIView animateWithDuration:.5  delay:0 options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 view.alpha = 1.0;
                             } completion:^(BOOL finished){}];
            
            // Start timer for fade out
            [view performSelector:@selector(fadeToastOut) withObject:nil afterDelay:kDuration];
        }
    }
}

@end
