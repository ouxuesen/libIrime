//
//  RimeConfig.h
//  SCU
//
//  Created by Neo on 12/29/12.
//  Copyright (c) 2012 Paradigm X. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RimeConfigError.h"

@interface RimeKitConfig : NSObject {
    NSString *_configName;
    NSString *_configPath;
    NSString *_customConfigName;
    NSString *_customConfigPath;
    
    // If in bundle the config is loaded from Squirrel IME bundle and the _customConfig==nil
    BOOL _fromBundle;
    
    BOOL _customConfigExists;
    
    // _config contains all key-value pairs from the config file
    // _customConfig contains all patch key-value pairs from the custom config file
    NSDictionary *_config;
    NSMutableDictionary *_customConfig;
    
    
}

@property(nonatomic, assign)BOOL isWriteToConfig;

- (BOOL)reload:(RimeConfigError **)error;
- (RimeKitConfig *)initWithConfigName:(NSString *)name error:(RimeConfigError **)error;
- (RimeKitConfig *)initWithSchemaName:(NSString *)name error:(RimeConfigError **)error;
- (RimeKitConfig *)initWithBundledSchemaName:(NSString *)name error:(RimeConfigError **)error;

- (id)valueForKey:(NSString *)key;
- (id)valueForKeyPath:(NSString *)keyPath;
- (NSArray *)arrayForKey:(NSString *)key;
- (NSArray *)arrayForKeyPath:(NSString *)keyPath;
- (BOOL)boolForKey:(NSString *)key;
- (BOOL)boolForKeyPath:(NSString *)keyPath;
- (NSDictionary *)dictionaryForKey:(NSString *)key;
- (NSDictionary *)dictionaryForKeyPath:(NSString *)keyPath;
- (float)floatForKey:(NSString *)key;
- (float)floatForKeyPath:(NSString *)keyPath;
- (NSInteger)integerForKey:(NSString *)key;
- (NSInteger)integerForKeyPath:(NSString *)keyPath;
- (NSString *)stringForKey:(NSString *)key;
- (NSString *)stringForKeyPath:(NSString *)keyPath;

- (BOOL)setValue:(id)value forKeyPath:(NSString *)keyPath error:(RimeConfigError **)error;
- (BOOL)setValue:(id)value forKeyPath:(NSString *)keyPath toDisk:(BOOL)writeToDisk error:(RimeConfigError **)error;




- (BOOL)patchValue:(id)value forKeyPath:(NSString *)keyPath error:(RimeConfigError **)error;
- (BOOL)patchValue:(id)value forKeyPath:(NSString *)keyPath toDisk:(BOOL)writeToDisk error:(RimeConfigError **)error;
- (BOOL)patchValue:(id)value forKeyPathArray:(NSArray *)keyPathArray error:(RimeConfigError **)error;
- (BOOL)patchValue:(id)value forKeyPathArray:(NSArray *)keyPathArray toDisk:(BOOL)writeToDisk error:(RimeConfigError **)error;

+ (RimeKitConfig *)userConfig:(RimeConfigError **)error;
+ (RimeKitConfig *)defaultConfig:(RimeConfigError **)error;
+ (RimeKitConfig *)squirrelConfig:(RimeConfigError **)error;

+ (NSString *)rimeFolder;
+ (BOOL)checkRimeFolder;
+ (NSString *)sharedSupportFolder;
+ (BOOL)checkSharedSupportFolder;

- (NSString *)description;
@end
