//
//  TextAnalytics.h
//  Word-Counter
//
//  Created by Rares Tamas on 4/15/26.
//  Copyright (c) 2026 Rares Tamas. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ReadabilityDifficulty) {
    ReadabilityDifficultyEasy,      // Grade 1-6 (very easy to moderate)
    ReadabilityDifficultyModerate,  // Grade 6-12 (moderate to college)
    ReadabilityDifficultyHard       // Grade 12+ (college to graduate)
};

@interface TextAnalytics : NSObject

/**
 Calculate Flesch-Kincaid Grade Level
 Formula: 0.39 × (words / sentences) + 11.8 × (syllables / words) − 15.59
 Returns a grade level (e.g., 8.5 = 8th grade level)
 */
+ (double)fleschKincaidGradeLevelForText:(NSString *)text
                                   words:(NSUInteger)wordCount
                               sentences:(NSUInteger)sentenceCount;

/**
 Calculate Flesch Reading Ease score (0-100)
 Formula: 206.835 − 1.015 × (words / sentences) − 84.6 × (syllables / words)
 Higher score = easier to read (90-100 = very easy, 0-30 = very difficult)
 */
+ (double)fleschReadingEaseForText:(NSString *)text
                              words:(NSUInteger)wordCount
                          sentences:(NSUInteger)sentenceCount;

/**
 Calculate reading time in seconds at a given WPM (words per minute)
 Default: 200 WPM
 */
+ (NSUInteger)readingTimeInSecondsForWordCount:(NSUInteger)wordCount
                               wordsPerMinute:(NSUInteger)wpm;

/**
 Categorize difficulty based on Flesch-Kincaid grade level
 */
+ (ReadabilityDifficulty)difficultyLevelForGradeLevel:(double)gradeLevel;

/**
 Count syllables in text using a fast heuristic method
 Counts vowel groups and applies rules for common endings
 More efficient than NLTokenizer for real-time updates
 */
+ (NSUInteger)syllableCountForText:(NSString *)text;

/**
 Get human-readable color representation for difficulty
 Returns a string suitable for binding to UI
 */
+ (NSString *)difficultyDescriptionForLevel:(ReadabilityDifficulty)level;

/**
 Get emoji representation for difficulty
 */
+ (NSString *)difficultyEmojiForLevel:(ReadabilityDifficulty)level;

/**
 Detect if text appears to be code (simple heuristic)
 Checks for common programming patterns
 */
+ (BOOL)looksLikeCodeForText:(NSString *)text;

/**
 Get estimated reading difficulty as a user-friendly string
 e.g., "College Level - Moderately Difficult"
 */
+ (NSString *)readabilityRatingForText:(NSString *)text
                                 words:(NSUInteger)wordCount
                             sentences:(NSUInteger)sentenceCount;

@end
