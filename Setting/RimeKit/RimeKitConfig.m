//
//  RimeConfig.m
//  SCU
//
//  Created by Neo on 12/29/12.
//  Copyright (c) 2012 Paradigm X. All rights reserved.
//

#import "RimeKitConfig.h"

#import <YACYAML/YACYAML.h>

#import "NSObject+DeepMutableCopy.h"
#import "NSDictionary+KeyPath.h"

#import "RimeConstants.h"
#import "NSString+Path.h"


@implementation RimeKitConfig

- (RimeKitConfig *)initWithBundledSchemaName:(NSString *)name error:(RimeConfigError **)error {
    _fromBundle = YES;
    return [self initWithConfigName:[name stringByAppendingString:RIME_SCHEMA_EXT] root:[RimeKitConfig sharedSupportFolder] error:error];
}

- (RimeKitConfig *)initWithSchemaName:(NSString *)name error:(RimeConfigError **)error {
    return [self initWithConfigName:[name stringByAppendingString:RIME_SCHEMA_EXT] error:error];
}

- (RimeKitConfig *)initWithConfigName:(NSString *)name error:(RimeConfigError **)error {
    return [self initWithConfigName:name root:[RimeKitConfig rimeFolder] error:error];
}

// initWithConfigName return nil when root configuration folder not exists OR
// requested config file not exists. Caller should prompt user to run Deploy
// command from Squirrel IME menu before any customization.
- (RimeKitConfig *)initWithConfigName:(NSString *)name root:(NSString *)folder error:(RimeConfigError **)error {
    if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
        if (error) {
            *error = [[RimeConfigError alloc] init];
            [*error setErrorType:RimeConfigFolderNotExistsError];
            [*error setConfigFolder:folder];
        }
        
        return nil;
    }
    
    _configName = [name stringByAppendingString:RIME_CONFIG_FILE_EXT];
    _customConfigName = [[name stringByAppendingString:RIME_CUSTOM_EXT] stringByAppendingString:RIME_CONFIG_FILE_EXT];
    _configPath = [NSString pathWithComponents:[NSArray arrayWithObjects:folder, _configName, nil]];
    _customConfigPath = [NSString pathWithComponents:[NSArray arrayWithObjects:folder, _customConfigName, nil]];
    _customConfigExists = NO;
    
    if (![self reload:error]) {
        return nil;
    };
    
    return self;
}

- (BOOL)reload:(RimeConfigError **)error {
    // Key assumption about loading configuration:
    // 1. M-RimeConfig, C-RimeConfigController and V-PreferencesViewController.
    // 2. Every time Squirrel run its Deploy procedure all patch values in *.custom.yaml will be merge into
    //    the actual configuration file *.yaml. Values in _config are all that matter.
    // 3. If we write something to the *.custom.yaml by calling patchValue then reload configurations without
    //    running Squirrel's Deploy command, data in _config and _customConfig will be different.
    // 4. To keep logical consistency RimeConfig should simulate Squirrel's merge procedure when populate
    //    values (see valueForKey and valueForKeyPath method). i.e. When RimeConfigController requests value
    //    for a key(path) RimeConfig always gives out merged value.
        
    if (![[NSFileManager defaultManager] fileExistsAtPath:_configPath]) {
        NSLog(@"WARNING: Config file does not exist: %@", _configPath);
        if (error) {
            *error = [[RimeConfigError alloc] init];
            [*error setErrorType:RimeConfigFileNotExistsError];
            [*error setConfigFile:_configPath];
        }        
        return NO;
    }
    
    NSString *code = [NSString stringWithContentsOfFile:_configPath encoding:NSUTF8StringEncoding error:nil];
    _config = [code YACYAMLDecode];
    
    if (_fromBundle) return YES;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_customConfigPath]) {
        NSLog(@"INFO: Custom config file does not exist: %@. Will create new one while patching values.", _customConfigPath);
    }
    else {
        _customConfig = [[[NSString stringWithContentsOfFile:_customConfigPath encoding:NSUTF8StringEncoding error:nil] YACYAMLDecode] deepMutableCopy];
        _customConfigExists = YES;
    }
    
    return YES;
}

#pragma mark - Making patch key path for *.custom.yaml

- (NSString *)patchKeyPath:(NSString *)keyPath {
    return [[RIME_CUSTOM_ROOT_KEY stringByAppendingString:@"."] stringByAppendingString:keyPath];
}

- (NSArray *)patchKeyPathArray:(NSArray *)keyPathArray {
    return [@[RIME_CUSTOM_ROOT_KEY] arrayByAddingObjectsFromArray:keyPathArray];
}



#pragma mark - write model to yaml
- (BOOL)setValue:(id)value forKeyPath:(NSString *)keyPath error:(RimeConfigError **)error
{
    BOOL res = NO;
    res = [self setValue:value forKeyPath:keyPath toDisk:YES error:error];
    return res;
    
}

- (BOOL)setValue:(id)value forKeyPath:(NSString *)keyPath toDisk:(BOOL)writeToDisk error:(RimeConfigError **)error
{
    
    BOOL res = NO;
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:_config];
    NSArray *keyPathArray = [keyPath componentsSeparatedByString:@"."];
    [dic setObject:value forKeyPathArray:keyPathArray];
    
    if (writeToDisk) {
        
        res =[[dic YACYAMLEncodedString] writeToFile:_configPath
                                                      atomically:NO
                                                        encoding:NSUTF8StringEncoding
                                                           error:error];
    }
    
    return res;
    
    
}

#pragma mark - Write model patch value

- (BOOL)patchValue:(id)value forKeyPath:(NSString *)keyPath error:(RimeConfigError **)error {
    return [self patchValue:value forKeyPath:keyPath toDisk:YES error:error];
}

- (BOOL)patchValue:(id)value forKeyPath:(NSString *)keyPath toDisk:(BOOL)writeToDisk error:(RimeConfigError **)error {
    NSArray *keyPathArray = [keyPath componentsSeparatedByString:@"."];
    return [self patchValue:value forKeyPathArray:keyPathArray toDisk:writeToDisk error:error];
}

- (BOOL)patchValue:(id)value forKeyPathArray:(NSArray *)keyPathArray error:(RimeConfigError **)error {
    return [self patchValue:value forKeyPathArray:keyPathArray toDisk:YES error:error];
}

- (BOOL)patchValue:(id)value forKeyPathArray:(NSArray *)keyPathArray toDisk:(BOOL)writeToDisk error:(RimeConfigError **)error {
    // Key assumption about patching value:
    // 1. M-RimeConfig, C-RimeConfigController and V-PreferencesViewController.
    // 2. One RimeConfig object represents a *.custom.yaml file. Any modification on the object should be
    //    sync-ed to the file immediately.
    // 3. If the file has been changed by other apps SCU may override the changes from other apps.
    // 4. If RimeConfigController orders RimeConfig to patch a value RimeConfig will save it in _customConfig
    //    and try to sync to the disk file. If syncing to file fails, _customConfig will NOT rollback. All
    //    changes will be re-tried next time patchValue being called.
    
    if (!_customConfigExists) {
        _customConfig = [[NSMutableDictionary alloc] init];
    }
    assert(_customConfig);
    
    [_customConfig setObject:value forKeyPathArray:[self patchKeyPathArray:keyPathArray]];
    if (!_customConfigExists) _customConfigExists = YES;
    
    if (writeToDisk) {
        return [[_customConfig YACYAMLEncodedString] writeToFile:_customConfigPath
                                                      atomically:NO
                                                        encoding:NSUTF8StringEncoding
                                                           error:error];
    }
    
    return YES;
    
}

#pragma mark - Read model attribute

- (id)valueForKey:(NSString *)key {
    // See comment in method reload
    if (_customConfigExists && [_customConfig valueForKeyPath:[self patchKeyPath:key]]) {
        return [_customConfig valueForKeyPath:[self patchKeyPath:key]];
    }
    else {
        return [_config valueForKey:key];
    }
}

- (id)valueForKeyPath:(NSString *)keyPath {
    // See comment in method reload
    if (_customConfigExists && [_customConfig valueForKeyPath:[self patchKeyPath:keyPath]]) {
        return [_customConfig valueForKeyPath:[self patchKeyPath:keyPath]];
    }
    else {
        return [_config valueForKeyPath:keyPath];
    }
}

// Wrappers for different data types

- (NSArray *)arrayForKey:(NSString *)key {
    id v = [self valueForKey:key];
    if (!v) {
        return [[NSArray alloc] init];
    }

    return (NSArray *)v;
}

- (NSArray *)arrayForKeyPath:(NSString *)keyPath {
    id v = [self valueForKeyPath:keyPath];
    if (!v) {
        return [[NSArray alloc] init];
    }

    return (NSArray *)v;
}

- (BOOL)boolForKey:(NSString *)key {
    return (BOOL)[self integerForKey:key];
}

- (BOOL)boolForKeyPath:(NSString *)keyPath {
    return (BOOL)[self integerForKeyPath:keyPath];
}

- (NSDictionary *)dictionaryForKey:(NSString *)key {
    id v = [self valueForKey:key];
    if (!v) {
        return [[NSDictionary alloc] init];
    }

    return (NSDictionary *)v;
}

- (NSDictionary *)dictionaryForKeyPath:(NSString *)keyPath {
    id v = [self valueForKeyPath:keyPath];
    if (!v) {
        return [[NSDictionary alloc] init];
    }
    
    return (NSDictionary *)v;
}

- (float)floatForKey:(NSString *)key {
    return [[self stringForKey:key] floatValue];
}

- (float)floatForKeyPath:(NSString *)keyPath {
    return [[self stringForKeyPath:keyPath] floatValue];
}

- (NSInteger)integerForKey:(NSString *)key{
    return [[self stringForKey:key] integerValue];
}

- (NSInteger)integerForKeyPath:(NSString *)keyPath {
    return [[self stringForKeyPath:keyPath] integerValue];
}

- (NSString *)stringForKey:(NSString *)key {
    id v = [self valueForKey:key];
    if (!v) {
        return @"";
    }

    return (NSString *)v;
}

- (NSString *)stringForKeyPath:(NSString *)keyPath {
    id v = [self valueForKeyPath:keyPath];
    if (!v) {
        return @"";
    }

    return (NSString *)v;
}

#pragma mark - Class helpers

+ (NSString *)rimeFolder {
    return [NSString rimeResource];
}

+ (BOOL)checkRimeFolder {
    return [RimeKitConfig checkFolder:[RimeKitConfig rimeFolder]];
}

+ (NSString *)sharedSupportFolder {
//    return [RIME_SHARED_SUPPORT_FOLDER stringByExpandingTildeInPath];
    return [NSString rimeResource];
}

+ (BOOL)checkSharedSupportFolder {
    return [RimeKitConfig checkFolder:[RimeKitConfig sharedSupportFolder]];
}

+ (BOOL)checkFolder:(NSString *)folder {
    if (![[NSFileManager defaultManager] fileExistsAtPath:folder]) {
        NSLog(@"WARNING: Rime config folder does not exist: %@", folder);
        return NO;
    }
    
    return YES;
}

+ (RimeKitConfig *)defaultConfig:(RimeConfigError **)error {
    RimeKitConfig *config = [[RimeKitConfig alloc] initWithConfigName:RIME_DEFAULT_CONFIG_NAME error:error];
    return config;
}

+ (RimeKitConfig *)userConfig:(RimeConfigError **)error {
    RimeKitConfig *config = [[RimeKitConfig alloc] initWithConfigName:RIME_USER_CONFIG_NAME error:error];
    return config;
}

+ (RimeKitConfig *)squirrelConfig:(RimeConfigError **)error {
    RimeKitConfig *config = [[RimeKitConfig alloc] initWithConfigName:RIME_SQUIRREL_CONFIG_NAME error:error];
    return config;
}

- (NSString *)description {
    NSString *desc = [NSString stringWithFormat:@"RimeConfig[%@]:\n%@\nRimeConfig[%@]:\n%@",
                      _configPath, _config, _customConfigPath, _customConfig];
    
    return desc;
}

@end
