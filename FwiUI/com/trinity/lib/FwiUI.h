//  Project name: FwiUI
//  File name   : FwiUI.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 9/21/12
//  Version     : 1.00
//  --------------------------------------------------------------
//  Copyright (C) 2012, 2013 Trinity 0715. All Rights Reserved.
//  --------------------------------------------------------------
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
// NOT LIMITED  TO  THE  WARRANTIES  OF  MERCHANTABILITY,  FITNESS  FOR  A  PARTICULAR  PURPOSE  AND
// NONINFRINGEMENT OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED
// IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR  ANY
// DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
// NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR  PERFORMANCE
// OF THIS SOFTWARE.
//
//
// Disclaimer
// ----------
// Although reasonable care has been taken to ensure the correctness of  this  implementation,  this
// code should never be used in any application without proper verification and testing.  I disclaim
// all liability and responsibility to any person or entity with  respect  to  any  loss  or  damage
// caused, or alleged to be caused, directly or indirectly, by the use of this  class.  However,  if
// you discover any kind of bugs, please feel free to email me at phuc.fwi@gmail.com.

#ifndef __FWI_UI__
#define __FWI_UI__


// Extension UIControls
#import "FwiButton.h"
#import "FwiTextField.h"


// Define FwiBundle
//#define kFwiBundle                  [NSBundle bundleWithPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"FwiBundle.bundle"]]
#define kFwiBundle                  [NSBundle mainBundle]


typedef NS_ENUM(NSInteger, FwiDirection) {
    kDirection_LR = 0,
    kDirection_RL = 1,
    kDirection_UD = 2,
    kDirection_DU = 3
}; // Animation Direction


// Define calculation macro functions
static inline CGPoint FwiCalculateCenter(CGRect frame) {
    CGFloat x = frame.origin.x + (frame.size.width  / 2);
    CGFloat y = frame.origin.y + (frame.size.height / 2);
    
    return CGPointMake(x, y);
}
static inline CGRect  FwiCalculateFrameForAngle(CGRect frame, CGFloat angle) {
    CGPoint origin = frame.origin;
    CGPoint center = FwiCalculateCenter(frame);
    
    // Apply rotation matrix + translation matrix
    CGRect resultFrame;
    resultFrame.origin.x = cosf(angle) * (origin.x - center.x) - sinf(angle) * (origin.y - center.y) + center.x;
    resultFrame.origin.y = sinf(angle) * (origin.x - center.x) + cosf(angle) * (origin.y - center.y) + center.y;
    resultFrame.size     = frame.size;
    
    return resultFrame;
}
static inline CGPoint FwiCalculatePointForAngle(CGPoint origin, CGPoint point, CGFloat angle) {
    // Apply rotation matrix + translation matrix
    CGPoint resultPoint;
    resultPoint.x = cosf(angle) * (point.x - origin.x) - sinf(angle) * (point.y - origin.y) + origin.x;
    resultPoint.y = sinf(angle) * (point.x - origin.x) + cosf(angle) * (point.y - origin.y) + origin.y;
    
    return resultPoint;
}


// Define animations & completion block
typedef void(^AnimationsBlock)(void);
typedef void(^CompletionBlock)(BOOL finished);


#endif