//
//  RimeConfigController.h
//  SCU
//
//  Created by Neo on 12/29/12.
//  Copyright (c) 2012 Paradigm X. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RimeKitConfig.h"

// We ONLY handle 3 hotkeys for switcher (default.yaml: switcher.hotkeys)
#define SWITCHER_HOTKEY_COUNT 3

@interface RimeConfigController : NSObject {
    RimeKitConfig *_defaultConfig;
    RimeKitConfig *_squirrelConfig;
    RimeKitConfig *_userConfig;

    NSArray *_schemaIds;
    NSMutableSet *_enabledSchemaIds;
}



@property NSMutableArray *schemata;

// Category: General
@property (nonatomic) BOOL useUSKeyboardLayout;
@property (nonatomic) NSUInteger showNotificationWhen;
@property (nonatomic) BOOL showNotificationViaNotificationCenter;
@property (nonatomic) NSString *switcherCaption;
@property (nonatomic) NSArray *switcherHotkeys;

// Category: Style
@property (nonatomic) BOOL isHorizontal;
@property (nonatomic) NSInteger lineSpacing;
@property (nonatomic) NSInteger numberOfCandidates;
@property (nonatomic) NSString *fontFace;
@property (nonatomic) NSInteger fontPoint;
@property (nonatomic) NSInteger cornerRadius;
@property (nonatomic) NSInteger borderHeight;
@property (nonatomic) NSInteger borderWidth;
@property (nonatomic) float alpha;
@property (readonly) NSArray *colorThemes;
@property (nonatomic) NSString *colorTheme;

// Category: Apps
@property (nonatomic) NSMutableArray *appOptions;


@property(nonatomic, strong)NSString* currentSchema;



+(instancetype)sharedInstance;

-(void)reloadConfig;
-(void)loadConfig;
-(BOOL)loadConfig:(RimeConfigError **)error;

// Override property setters to do patching
- (void)setUseUSKeyboardLayout:(BOOL)value;
- (void)setShowNotificationWhen:(NSUInteger)value;
- (void)setShowNotificationViaNotificationCenter:(BOOL)value;
- (void)setSwitcherCaption:(NSString *)value;
- (void)setSwitcherHotkeys:(NSArray *)value;

- (void)setIsHorizontal:(BOOL)value;
- (void)setLineSpacing:(NSInteger)value;
- (void)setNumberOfCandidates:(NSInteger)value;
- (void)setFontFace:(NSString *)value;
- (void)setFontPoint:(NSInteger)value;
- (void)setCornerRadius:(NSInteger)value;
- (void)setBorderHeight:(NSInteger)value;
- (void)setBorderWidth:(NSInteger)value;
- (void)setAlpha:(float)value;
- (void)setColorTheme:(NSString *)value;

- (void)setOptionASCIIMode:(BOOL)ascii forApp:(NSString *)appId;
- (void)setOptionSoftCursor:(BOOL)cursor forApp:(NSString *)appId;

- (void)setEnabled:(BOOL)enabled forSchema:(NSString *)schemaId;

// Class helpers
+ (NSString *)rimeFolder;
+ (BOOL)checkRimeFolder;
@end
