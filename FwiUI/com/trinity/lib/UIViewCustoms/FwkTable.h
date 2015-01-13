//  Project name: FwiUI
//  File name   : FwkTable.h
//
//  Author      : Phuc, Tran Huu
//  Created date: 12/24/12
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

#import <UIKit/UIKit.h>


static inline NSUInteger FwiRotateIndex(NSInteger index, NSInteger itemCount, BOOL isRotable) {
    if (itemCount == 0) return 0;
    
    if (!isRotable) index = MIN(MAX(index, 0), itemCount - 1);
    else index -= (NSInteger)floorf((CGFloat)index / (CGFloat)itemCount) * itemCount;
    
    return index;
}
static inline CGFloat FwiRotateOffset(CGFloat offset, NSInteger itemCount, BOOL isRotable) {
    if (itemCount == 0) return 0.0f;
    
    if (!isRotable) offset = fminf(fmaxf(0.0f, offset), (CGFloat)itemCount - 1.0f);
    else offset = itemCount ? (offset - floorf(offset / (CGFloat)itemCount) * itemCount) : 0.0f;
    
    return offset;
}
static inline CGFloat FwkOffsetForIndex(NSInteger index, CGFloat scrollOffset, NSUInteger itemCount, BOOL isRotable) {
    // Handle special case for one item
    if (itemCount == 1) return 0.0f;
    
    //calculate relative position
    CGFloat offset = (CGFloat)index - scrollOffset;
    
    if (isRotable) {
        if (offset > itemCount / 2) offset -= itemCount;
        else if (offset < -itemCount / 2) offset += itemCount;
    }
    return offset;
}

static inline CGFloat FwkCalculateAnimationTime(CGFloat time) {
    return (time < 0.5f) ? (0.5f * powf(time * 2.0f, 3.0f)) : (0.5f * powf(time * 2.0f - 2.0f, 3.0f) + 1.0f);
}
static inline CGFloat FwkCalculateDecelerationDistance(CGFloat startVelocity) {
    float decelerationAmplifier = 30.0f;
    float decelerationRate      = 0.95f;
    
    // Calculate deceleration distance
    float deceleration = -startVelocity * decelerationAmplifier * (1.0f - decelerationRate);
    float distance = -powf(startVelocity, 2.0f) / (2.0f * deceleration);
    
    return distance;
}
static inline CGFloat FwkCalculateDistanceBetweenOffsets(CGFloat offsetFrom, CGFloat offsetTo, NSInteger itemCount, BOOL isRotable) {
    float distance = offsetTo - offsetFrom;
    
    if (isRotable) {
        float wrappedDistance = fminf(offsetTo, offsetFrom) + itemCount - fmaxf(offsetTo, offsetFrom);
        if (offsetFrom < offsetTo) wrappedDistance *= -1;
        
        distance = (fabsf(distance) <= fabsf(wrappedDistance)) ? distance : wrappedDistance;
    }
    return distance;
}


static inline CGFloat FwkCalculateTranslationFactor(CGFloat scrollOffset, CGFloat bounceDistance, NSInteger itemCount, BOOL isBouncing, BOOL isRotable) {
    float factor = 1.0f;
    
    // Validate rotate offset
    float offset = FwiRotateOffset(scrollOffset, itemCount, isRotable);
    
    // Calculate factor value if it is not rotating and is bouncing
    if (!isRotable && isBouncing) {
        factor = 1.0f - fminf(bounceDistance, fabsf(scrollOffset - offset)) / bounceDistance;
    }
    return factor;
}
static inline float FwkCalculateTranslationVelocity(CGPoint velocity, float translationFactor, float itemWidth, BOOL isVertical) {
    float s = 0.5f;   // Scroll speed
    float v = 0.0f;   // Start velocity

    // Finalize velocity value
    v = -(!isVertical ? velocity.x : velocity.y) * translationFactor * s / itemWidth;
    return v;
}


typedef enum {
    kTableOption_SpaceFactor = 0    // itemWidth = itemWidth * spaceFactor
} FwkTableOption;


@protocol FwkTableDataSource, FwkTableDelegate;


@interface FwkTable : UIView {

@private
    NSMutableDictionary *_itemHolder;
    NSMutableSet        *_itemQueue;
    
    CGFloat             _itmW;           // Item's width
    NSUInteger          _itmCnt;         // Number of items
    NSUInteger          _visibleCount;   // Number of visible items
}

@property (nonatomic, assign) IBOutlet id<FwkTableDataSource> datasource;
@property (nonatomic, assign) IBOutlet id<FwkTableDelegate>   delegate;

@property (nonatomic, assign) BOOL enableScroll;
@property (nonatomic, assign) BOOL isBouncing;
@property (nonatomic, assign) BOOL isRotable;


/**
 * Return array of visible indexes for this table
 */
- (NSArray *)visibleIndexes;

/**
 * Return array of visible items for this table
 */
- (NSArray *)visibleItems;

/**
 * Reload carousel
 */
- (void)reload;
/**
 * Render carousel
 */
- (void)render;

/**
 * Insert new item to the end of the table
 */
- (void)insertItem;
- (void)insertItemWithCompletion:(CompletionBlock)completion;

/**
 * Delete item at index
 */
- (void)removeItem;
- (void)removeItemAtIndex:(NSInteger)index;
- (void)removeItemAtIndex:(NSInteger)index completion:(CompletionBlock)completion;

@end




@protocol FwkTableDataSource <NSObject>

@required
/**
 * Number of items within table
 */
- (NSUInteger)itemCount:(FwkTable *)table;

/**
 * Return an item for table
 */
- (UIView *)table:(FwkTable *)table itemAtIndex:(NSInteger)index reusingItem:(UIView *)view;

@optional
/**
 * Item's width
 */
- (CGFloat)itemWidth:(FwkTable *)table;

@end




@protocol FwkTableDelegate <NSObject>

@required
/**
 * Handle insert new item into table
 */
- (void)table:(FwkTable *)table willInsertItem:(UIView *)item atIndex:(NSInteger)index;
- (void)table:(FwkTable *)table didInsertItem:(UIView *)item atIndex:(NSInteger)index;

/**
 * Handle remove item from table
 */
- (void)table:(FwkTable *)table willRemoveItem:(UIView *)item atIndex:(NSInteger)index;
- (void)table:(FwkTable *)table didRemoveItem:(UIView *)item atIndex:(NSInteger)index;

@optional
/**
 * Allow user to change default value for each option
 */
- (CGFloat)table:(FwkTable *)table valueForOption:(FwkTableOption)option defaultValue:(CGFloat)defaultValue;

/**
 * Control remove item from table at index
 */
- (BOOL)table:(FwkTable *)table shouldInsertItemAtIndex:(NSInteger)index;

/**
 * Control remove item from table at index
 */
- (BOOL)table:(FwkTable *)table shouldRemoveItem:(UIView *)item atIndex:(NSInteger)index;

@end