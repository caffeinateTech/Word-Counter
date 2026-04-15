//
//  SettingsManager.h
//  Word-Counter
//
//  Created by Rares Tamas on 4/15/26.
//  Copyright (c) 2026 Rares Tamas. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 SettingsManager - Centralized preferences management
 Stores user preferences to NSUserDefaults
 */
@interface SettingsManager : NSObject

// Default WPM (words per minute) for reading time calculation - default 200
+ (NSUInteger)defaultReadingWordsPerMinute;
+ (void)setDefaultReadingWordsPerMinute:(NSUInteger)wpm;

// Whether to show advanced metrics (readability, sentiment) - default YES
+ (BOOL)shouldShowAdvancedMetrics;
+ (void)setShouldShowAdvancedMetrics:(BOOL)show;

// Whether onboarding has been completed
+ (BOOL)hasCompletedOnboarding;
+ (void)setOnboardingCompleted:(BOOL)completed;

// Last clipboard content hash (for debounce optimization)
+ (NSString *)lastClipboardHash;
+ (void)setLastClipboardHash:(NSString *)hash;

// Whether to start monitoring on app launch
+ (BOOL)shouldStartMonitoringOnLaunch;
+ (void)setShouldStartMonitoringOnLaunch:(BOOL)start;

// Reset all settings to defaults
+ (void)resetToDefaults;

@end
