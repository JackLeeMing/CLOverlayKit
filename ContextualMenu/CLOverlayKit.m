//
//  OverlayMenu.m
//  ContextualMenu
//
//  Created by Christopher Cohen on 1/29/15.
//  Copyright (c) 2015 YES. All rights reserved.
//

#import "CLOverlayKit.h"

@interface CLOverlayKit()

@property (nonatomic, strong) UIView *panelView;
@property (nonatomic, strong) UIView *tintView;
@property (nonatomic, readwrite) CGPoint touchPoint;
@property (nonatomic, readwrite) CLEquatorPosition equatorPosition;
@property (nonatomic, readwrite) CLHorizontalPosition horizontalPosition;
@property (nonatomic, readwrite) CLOverlayAppearance appearance;
@property (nonatomic, readwrite) CLOverlayFormat format;
@end

@implementation CLOverlayKit

#pragma mark - API Methods

+(void)presentContextualMenuInView:(UIView *)view delegate:(id)delegate touchPoint:(CGPoint)touchPoint strings:(NSArray*)strings appearance:(CLOverlayAppearance)appearance {
    
    CLOverlayKit *menuOverlay = [CLOverlayKit newContextualOverlayInView:view delegate:delegate touchPoint:touchPoint appearance:appearance];

    menuOverlay.format = MenuOverlay;
    
    [menuOverlay applyTintToSuperview];
    [menuOverlay composeMenuPanelWithStrings:strings];
    [menuOverlay animateOverlayAppearance];
}

+(void)presentContextualDescriptionInView:(UIView *)view delegate:(id)delegate touchPoint:(CGPoint)touchPoint bodyString:(NSString*)bodyString headerString:(NSString *)headerString appearance:(CLOverlayAppearance)appearance {
    
    CLOverlayKit *descriptionOverlay = [CLOverlayKit newContextualOverlayInView:view delegate:delegate touchPoint:touchPoint appearance:appearance];
    
    descriptionOverlay.format = DescriptionOverlay;
    
    [descriptionOverlay applyTintToSuperview];
    [descriptionOverlay composeDescriptionPanelWithBodyString:bodyString andHeaderString:headerString];
    [descriptionOverlay animateOverlayAppearance];
}

+(void)presentSideMenuInView:(UIView *)view delegate:(id)delegate touchPoint:(CGPoint)touchPoint strings:(NSArray*)strings appearance:(CLOverlayAppearance)appearance {
    
    CLOverlayKit *sideMenu = [CLOverlayKit newContextualOverlayInView:view delegate:delegate touchPoint:touchPoint appearance:appearance];
    
    sideMenu.format = SideMenu;
    
    [sideMenu composeSideMenuPanelWithStrings:strings];
    [sideMenu animateSideMenuAppearance];
}

#pragma mark - UI Composition

+(CLOverlayKit *)newContextualOverlayInView:(UIView *)view delegate:(id)delegate touchPoint:(CGPoint)touchPoint appearance:(CLOverlayAppearance)appearance {
    
    CLOverlayKit *overlay; {
        
        overlay = [[CLOverlayKit alloc] initWithFrame:view.frame];
        
        // Assign Properties
        overlay.appearance      = appearance;
        overlay.delegate        = delegate;
        overlay.backgroundColor = [UIColor clearColor];
        overlay.touchPoint      = touchPoint;
        overlay.equatorPosition = (touchPoint.y > view.bounds.size.height/2) ? AboveEquator : BelowEquator;
        [view addSubview:overlay];
    }
    
    return overlay;
}

- (void)composeButtonListFromStrings:(NSArray *)strings inPanelView:(UIView *)panelView {
    //Calculate button size
    CGSize buttonSize = CGSizeMake(panelView.frame.size.width, panelView.frame.size.height/strings.count);
    CGFloat verticalOffset = 0;
    
    //Create a button representing each string in the 'strings' array
    for (NSInteger index = 0; index < strings.count; index++) {
        
        //Compose UIButton
        UIButton *button; {
            button = [[UIButton alloc] initWithFrame:(CGRect){0,verticalOffset, buttonSize}];
            [button setTitle:[strings objectAtIndex:index] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithCGColor:self.appearance.textColor] forState:UIControlStateNormal];
            [button addTarget:self action:@selector(onTapMenuItem:) forControlEvents:UIControlEventTouchUpInside];
            button.titleLabel.font = [UIFont systemFontOfSize:button.frame.size.height*.35];
            button.tag = index;
            [panelView addSubview:button];
        }
            
        //Add a partition line to all buttons excluding the last item
        if (index != strings.count-1) [self addPartitionLineToBottonOfView:button];
        
        //Update vertical offset
        verticalOffset += buttonSize.height;
    }
}

-(void)addPartitionLineToBottonOfView:(UIView *)view {

    //Add partition line to button
    UIView *partitionLine; {
        
        partitionLine = [[UIView alloc] initWithFrame:CGRectMake(0, view.frame.size.height-_appearance.partitionLineThickness, view.frame.size.width*.9, _appearance.partitionLineThickness)];
        partitionLine.center = CGPointMake(view.center.x, partitionLine.center.y);
        partitionLine.backgroundColor = [[UIColor colorWithCGColor:self.appearance.textColor] colorWithAlphaComponent:.75];
        [view addSubview:partitionLine];
    }
}

-(UIView *)composePanelViewWithSize:(CGSize)size {

    UIView *panelView;
    
    //Calculate panel height for string quantity
    CGSize panelSize                = size;
    panelView                       = [[UIView alloc] initWithFrame:(CGRect){0,0, panelSize}];
    panelView.center                = _touchPoint;
    panelView.frame                 = [self adjustFrameForPosition:panelView.frame];
    panelView.backgroundColor       = [UIColor colorWithCGColor:_appearance.panelColor];
    panelView.layer.cornerRadius    = _appearance.cornerRadius;
    panelView.layer.borderWidth     = _appearance.borderWidth;
    panelView.layer.borderColor     = _appearance.textColor;
        
    return panelView;
}

-(void)composeMenuPanelWithStrings:(NSArray *)strings {
    
    //Compose panel view
    UIView *panelView = [self composePanelViewWithSize:CGSizeMake(_appearance.panelWidth, _appearance.contentHeight*strings.count)];
    [self addSubview:panelView];
    
    //Retain strong reference to panel view object
    _panelView = panelView;
    
    [self composeButtonListFromStrings:strings inPanelView:panelView];
}

-(void)composeDescriptionPanelWithBodyString:(NSString*)text andHeaderString:(NSString *)headerString{
    
    //Compose panel view
    UIView *panelView = [self composePanelViewWithSize:CGSizeMake(_appearance.panelWidth, _appearance.contentHeight*7)];
    [self addSubview:panelView];
    
    //Retain strong reference to panel view object
    _panelView = panelView;
    
    UILabel *headerLabel; {
        headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, panelView.frame.size.width, _appearance.contentHeight)];
        headerLabel.text = headerString;
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.font = [UIFont systemFontOfSize:headerLabel.bounds.size.height*.45];
        [panelView addSubview:headerLabel];
        
        [self addPartitionLineToBottonOfView:headerLabel];
    }
    
    UIView *descriptionContainerView; {
        descriptionContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, headerLabel.bounds.size.height, panelView.bounds.size.width, panelView.bounds.size.height-headerLabel.bounds.size.height)];
        [panelView addSubview:descriptionContainerView];
        
        UILabel *descriptionLabel; {
            
            CGRect frame = CGRectMake(descriptionContainerView.bounds.size.width*.05, 0, descriptionContainerView.bounds.size.width*.9, descriptionContainerView.bounds.size.height);
            descriptionLabel                = [[UILabel alloc] initWithFrame:frame];
            descriptionLabel.text           = text;
            descriptionLabel.textColor      = [UIColor colorWithCGColor:self.appearance.textColor];
            descriptionLabel.numberOfLines  = 0;
            [descriptionLabel sizeThatFits:descriptionContainerView.frame.size];
            [descriptionLabel setAdjustsFontSizeToFitWidth:YES];
            [descriptionContainerView addSubview:descriptionLabel];
        }
    }
}

-(void)composeSideMenuPanelWithStrings:(NSArray*)strings {
    
    //Determine horizontal position
    if (_touchPoint.x > self.frame.size.width/2) _horizontalPosition = RightOfCenter;
    else _horizontalPosition = LeftOfCenter;
    
    //Capture screenshot of the superview
    UIImageView *screenshot; {
        
        CGFloat xPosition = (_horizontalPosition) ? -_appearance.panelWidth : _appearance.panelWidth;
        screenshot = [[UIImageView alloc] initWithFrame:CGRectMake(xPosition, 0, self.bounds.size.width, self.bounds.size.height)];
        screenshot.image = [self snapshot:self.superview];
        [self addSubview:screenshot];
        
        //Add tint to screenshot
        UIView *screenshotTintView; {
            screenshotTintView = [[UIView alloc] initWithFrame:screenshot.bounds];
            screenshotTintView.backgroundColor = [[UIColor colorWithCGColor:_appearance.tintColor] colorWithAlphaComponent:TINT_ALPHA];
            [screenshot addSubview:screenshotTintView];
        }
    }

    //Compose panel view
    UIView *panelView; {
        CGFloat xPosition = (_horizontalPosition) ? self.frame.size.width-_appearance.panelWidth : 0;
        panelView = [[UIView alloc] initWithFrame:CGRectMake(xPosition, 0, _appearance.panelWidth, self.bounds.size.height)];
        panelView.backgroundColor = [UIColor colorWithCGColor:_appearance.panelColor];
        [self addSubview:panelView];
        
        //Retain strong reference to panel view object
        _panelView = panelView;
    }
    
    [self composeButtonListFromStrings:strings inPanelView:panelView];
    
    //Change the font size of all button objects
    for (NSObject *object in panelView.subviews) if ([object isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)object;
        button.titleLabel.font = [UIFont systemFontOfSize:self.bounds.size.height*.025];
    }
}

-(void)applyTintToSuperview {
    
    _tintView = [[UIView alloc] initWithFrame:self.superview.frame];
    _tintView.backgroundColor = [[UIColor colorWithCGColor:_appearance.tintColor] colorWithAlphaComponent:TINT_ALPHA];
    _tintView.alpha = 0;
    [self.superview insertSubview:_tintView belowSubview:self];
}

#pragma mark - Animation

-(void)animateSideMenuAppearance {
    
    //Get reference to screenshot view
    UIImageView *screenShot;
    for (screenShot in self.subviews) if ([screenShot isKindOfClass:[UIImageView class]]) break;
    
    //Get reference to the screenshot's tint-view
    UIView *screenshotTintView;
    for (screenshotTintView in screenShot.subviews) if ([screenshotTintView isKindOfClass:[UIView class]]) break;
    
    //Set destination points
    CGPoint screenShotDestination   = screenShot.center;
    CGPoint sideMenuDestination     = _panelView.center;
    
    //Set starting states for menu elements
    screenShot.frame = self.frame;
    screenshotTintView.alpha = 0;
    CGFloat panelStartingX = (_horizontalPosition) ? self.bounds.size.width : -_panelView.bounds.size.width;
    _panelView.frame = CGRectMake(panelStartingX, 0, _panelView.bounds.size.width, _panelView.bounds.size.height);
    
    // Animate Menu Appearance
    self.hidden = NO;
    
    [UIView animateWithDuration:SIDE_MENU_ANIMATION_SPEED animations:^{
        screenShot.center   = screenShotDestination;
        _panelView.center   = sideMenuDestination;
        screenshotTintView.alpha = 1;
    } completion:^(BOOL finished) {
        if (self.delegate) [self.delegate overlayKit:self didFinishPresentingWithFormat:_format];
    }];
}

-(void)animateSideMenuDismissal {
    
    //Get reference to screenshot view
    UIImageView *screenShot;
    for (screenShot in self.subviews) if ([screenShot isKindOfClass:[UIImageView class]]) break;
    
    //Get reference to the screenshot's tint-view
    UIView *screenshotTintView;
    for (screenshotTintView in screenShot.subviews) if ([screenshotTintView isKindOfClass:[UIView class]]) break;
    
    CGFloat panelDestinationX = (_horizontalPosition) ? self.bounds.size.width : -_panelView.bounds.size.width;
    
    [UIView animateWithDuration:SIDE_MENU_ANIMATION_SPEED animations:^{
        screenShot.frame = self.frame;
        _panelView.frame = CGRectMake(panelDestinationX, 0, _panelView.bounds.size.width, _panelView.bounds.size.height);
        screenshotTintView.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.delegate) [self.delegate overlayDidDismissWithFormat:_format];
        [self removeFromSuperview];
    }];
}

-(void)animateOverlayAppearance
{
    // Animate Menu Appearance
    self.alpha      = 0;
    self.hidden     = NO;
    _tintView.alpha = 0;
    
    [UIView animateWithDuration:OVERLAY_ANIMATION_SPEED animations:^{
        self.alpha      = 1;
        _tintView.alpha = 1;
    } completion:^(BOOL finished) {
        if (self.delegate) [self.delegate overlayKit:self didFinishPresentingWithFormat:_format];
    }];
}

-(void)animateOverlayDismissal
{
    if (_format == SideMenu) [self animateSideMenuDismissal];
    
    else {
        
        [UIView animateWithDuration:OVERLAY_ANIMATION_SPEED animations:^{
            self.alpha      = 0;
            _tintView.alpha = 0;
        } completion:^(BOOL finished) {
            [_tintView removeFromSuperview];
            if (self.delegate) [self.delegate overlayDidDismissWithFormat:_format];
            [self removeFromSuperview];
        }];
    }
}

#pragma mark - Target Method(s)

-(void)onTapMenuItem:(id)sender {
    if (self.delegate) [self.delegate overlayKit:self itemSelectedAtIndex:[(UIView *)sender tag]];
}

#pragma mark - User Interaction

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self animateOverlayDismissal];
}

#pragma mark - Convenience Function(s)

-(CGRect)adjustFrameForPosition:(CGRect)frame
{
    CGFloat adjustedX = frame.origin.x;
    CGFloat adjustedY = frame.origin.y;
    
    // Add origin.y content offset
    CGFloat verticalOffset = (frame.size.height/2)+self.frame.size.height*.025;
    adjustedY = (self.equatorPosition) ? adjustedY+verticalOffset : adjustedY-verticalOffset;
    
    // Adjust the x origin to fit within the visible bounds
    CGFloat edgeBuffer = self.bounds.size.width*.01;
    if (frame.origin.x < 0) adjustedX = edgeBuffer;
    else if (frame.origin.x > self.bounds.size.width-frame.size.width) adjustedX = self.bounds.size.width-frame.size.width-edgeBuffer;
    
    return (CGRect){adjustedX, adjustedY, frame.size};
}

- (UIImage *)snapshot:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)drawRect:(CGRect)rect {
    
    //Do not draw arrow if overlay is a side menu
    if (_format == SideMenu) return;
    
    CGFloat verticalOffset = (_equatorPosition) ? 1 : self.panelView.bounds.size.height-1;
    
    UIBezierPath* arrowPath = UIBezierPath.bezierPath;
    [arrowPath moveToPoint: CGPointMake(self.panelView.center.x+_appearance.arrowWidth, self.panelView.frame.origin.y+verticalOffset)];
    [arrowPath addLineToPoint: self.touchPoint];
    [arrowPath addLineToPoint: CGPointMake(self.panelView.center.x-_appearance.arrowWidth, self.panelView.frame.origin.y+verticalOffset)];
    [[UIColor colorWithCGColor:(_appearance.borderWidth) ? self.appearance.textColor : self.appearance.panelColor] setFill];
    [arrowPath fill];
}

@end