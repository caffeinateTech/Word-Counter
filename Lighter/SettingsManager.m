//
//  SettingsManager.m
//  Word-Counter
//
//  Created by Rares Tamas on 4/15/26.
//  Copyright (c) 2026 Rares Tamas. All rights reserved.
//

#import "SettingsManager.h"

// Keys for NSUserDefaults
static NSString * const kDefaultReadingWPM = @"defaultReadingWPM";
static NSString * const kShowAdvancedMetrics = @"showAdvancedMetrics";
static NSString * const kOnboardingCompleted = @"onboardingCompleted";
static NSString * const kLastClipboardHash = @"lastClipboardHash";
static NSString * const kStartMonitoringOnLaunch = @"startMonitoringOnLaunch";

// Defaults
static const NSUInteger kDefaultWPM = 200;

@implementation SettingsManager

+ (void)registerDefaults {
    NSDictionary *defaults = @{
        kDefaultReadingWPM: @(kDefaultWPM),
        kShowAdvancedMetrics: @YES,
        kOnboardingCompleted: @NO,
        kStartMonitoringOnLaunch: @NO
    };
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

+ (NSUInteger)defaultReadingWordsPerMinute {
    [self registerDefaults];
    NSUInteger wpm = [[NSUserDefaults standardUserDefaults] integerForKey:kDefaultReadingWPM];
    return wpm > 0 ? wpm : kDefaultWPM;
}

+ (void)setDefaultReadingWordsPerMinute:(NSUInteger)wpm {
    if (wpm < 50 || wpm > 500) {
        wpm = kDefaultWPM; // Clamp to reasonable range
    }
    [[NSUserDefaults standardUserDefaults] setInteger:wpm forKey:kDefaultReadingWPM];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)shouldShowAdvancedMetrics {
    [self registerDefaults];
    return [[NSUserDefaults standardUserDefaults] boolForKey:kShowAdvancedMetrics];
}

+ (void)setShouldShowAdvancedMetrics:(BOOL)show {
    [[NSUserDefaults standardUserDefaults] setBool:show forKey:kShowAdvancedMetrics];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)hasCompletedOnboarding {
    [self registerDefaults];
    return [[NSUserDefaults standardUserDefaults] boolForKey:kOnboardingCompleted];
}

+ (void)setOnboardingCompleted:(BOOL)completed {
    [[NSUserDefaults standardUserDefaults] setBool:completed forKey:kOnboardingCompleted];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)lastClipboardHash {
    [self registerDefaults];
    return [[NSUserDefaults standardUserDefaults] stringForKey:kLastClipboardHash];
}

+ (void)setLastClipboardHash:(NSString *)hash {
    [[NSUserDefaults standardUserDefaults] setObject:hash forKey:kLastClipboardHash];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)shouldStartMonitoringOnLaunch {
    [self registerDefaults];
    return [[NSUserDefaults standardUserDefaults] boolForKey:kStartMonitoringOnLaunch];
}

+ (void)setShouldStartMonitoringOnLaunch:(BOOL)start {
    [[NSUserDefaults standardUserDefaults] setBool:start forKey:kStartMonitoringOnLaunch];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)resetToDefaults {
    NSArray *keys = @[kDefaultReadingWPM, kShowAdvancedMetrics, kOnboardingCompleted, kLastClipboardHash, kStartMonitoringOnLaunch];
    
    for (NSString *key in keys) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self registerDefaults];
}

@end
