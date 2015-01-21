//
//  AKTableViewFooter.h
//  AvitoTestTask
//
//  Created by Пользователь on 22.01.15.
//  Copyright (c) 2015 AlKol. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AKTableViewFooter;

@protocol  AKTableViewFooterDelegate <NSObject>

-(void)didTapBackgroundBtnOnTableViewFooter:(AKTableViewFooter*)footer;

@end

/**
 * Class for UITableView footer
 */
@interface AKTableViewFooter : UIView


@property (nonatomic,weak) id<AKTableViewFooterDelegate> delegate;


@property (nonatomic,weak) UILabel *mainLabel;
@property (nonatomic,weak) UILabel *subLabel;
@property (nonatomic,weak) UIButton *backgroundBtn;
@property (nonatomic,weak) UIActivityIndicatorView *activityIndicator;

/**
 * Starts animating. Hides other views.
 */
-(void)startAnimatingActivityIndicator;

/**
 * Stops animating. Shows other views. Enables background button.
 */
-(void)stopAnimatingActivityIndicator;


@end
