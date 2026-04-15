//
//  TextAnalytics.m
//  Word-Counter
//
//  Created by Rares Tamas on 4/15/26.
//  Copyright (c) 2026 Rares Tamas. All rights reserved.
//

#import "TextAnalytics.h"

@implementation TextAnalytics

// ============================================================================
// SYLLABLE COUNTING - Simplified accurate algorithm (proven method)
// Based on vowel group counting - ~85% accurate without dictionary lookup
// ============================================================================
+ (NSUInteger)syllableCountForText:(NSString *)text {
    
    if (text.length == 0) {
        return 0;
    }
    
    NSString *cleanText = [text lowercaseString];
    NSUInteger totalSyllables = 0;
    
    // Split by whitespace and punctuation
    NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@" \t\n\r()\"',.;:!?—-"];
    NSArray *words = [cleanText componentsSeparatedByCharactersInSet:delimiters];
    
    for (NSString *word in words) {
        // Remove any remaining non-alphabetic characters
        NSMutableString *cleanWord = [NSMutableString string];
        for (NSUInteger i = 0; i < word.length; i++) {
            unichar c = [word characterAtIndex:i];
            if ((c >= 'a' && c <= 'z')) {
                [cleanWord appendFormat:@"%c", c];
            }
        }
        
        if (cleanWord.length > 0) {
            totalSyllables += [self syllableCountForWord:cleanWord];
        }
    }
    
    return MAX(1, totalSyllables);
}

// ============================================================================
// Helper: Count syllables in a single word
// ============================================================================
+ (NSUInteger)syllableCountForWord:(NSString *)word {
    
    if (word.length == 0) {
        return 0;
    }
    
    NSString *w = [word lowercaseString];
    NSUInteger count = 0;
    BOOL previousWasVowel = NO;
    
    // Define vowel set
    NSCharacterSet *vowelSet = [NSCharacterSet characterSetWithCharactersInString:@"aeiouy"];
    
    // Count vowel groups
    for (NSUInteger i = 0; i < w.length; i++) {
        unichar c = [w characterAtIndex:i];
        BOOL isVowel = [vowelSet characterIsMember:c];
        
        // Special case: 'y' is only a vowel if NOT at start of word
        if (c == 'y' && i == 0) {
            isVowel = NO;
        }
        
        // Increment count on transition into vowel group
        if (isVowel && !previousWasVowel) {
            count++;
        }
        
        previousWasVowel = isVowel;
    }
    
    // Apply only the most reliable rule: silent 'e' at end
    // Subtract 1 for final silent 'e', but not for 'le' endings (keep those)
    if ([w hasSuffix:@"e"] && w.length > 1) {
        // If ends in 'le' after a consonant, the 'le' creates a syllable - keep count as is
        if ([w hasSuffix:@"le"] && w.length > 2) {
            unichar beforeLE = [w characterAtIndex:w.length-3];
            // Consonant before 'le' - leave count as is (le = extra syllable already counted as vowel group)
            if (beforeLE != 'a' && beforeLE != 'e' && beforeLE != 'i' && 
                beforeLE != 'o' && beforeLE != 'u' && beforeLE != 'y') {
                // This is correct already
            } else {
                // Vowel before 'le' - subtract 1 for silent e
                if (count > 0) count--;
            }
        } else {
            // Regular 'e' ending - subtract 1 for silent e
            if (count > 0) {
                count--;
            }
        }
    }
    
    // Minimum 1 syllable per word
    if (count == 0) {
        count = 1;
    }
    
    return count;
}

// ============================================================================
// FLESCH-KINCAID GRADE LEVEL
// Formula: 0.39 × (words / sentences) + 11.8 × (syllables / words) − 15.59
// ============================================================================
+ (double)fleschKincaidGradeLevelForText:(NSString *)text
                                   words:(NSUInteger)wordCount
                               sentences:(NSUInteger)sentenceCount {
    
    // Handle edge cases
    if (wordCount == 0 || sentenceCount == 0) {
        return 0.0;
    }
    
    // Count total syllables
    __block NSUInteger totalSyllables = 0;
    
    // Split by words and count syllables in each
    [text enumerateSubstringsInRange:NSMakeRange(0, [text length])
                             options:NSStringEnumerationByWords
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                              totalSyllables += [self syllableCountForText:substring];
                          }];
    
    if (totalSyllables == 0) {
        totalSyllables = 1;
    }
    
    // Flesch-Kincaid formula
    double gradeLevel = 0.39 * ((double)wordCount / (double)sentenceCount) +
                       11.8 * ((double)totalSyllables / (double)wordCount) -
                       15.59;
    
    // Clamp to reasonable range (0-18)
    gradeLevel = MAX(0.0, MIN(18.0, gradeLevel));
    
    return gradeLevel;
}

// ============================================================================
// FLESCH READING EASE
// Formula: 206.835 − 1.015 × (words / sentences) − 84.6 × (syllables / words)
// Score: 90-100 = very easy, 60-70 = standard, 0-30 = very difficult
// ============================================================================
+ (double)fleschReadingEaseForText:(NSString *)text
                              words:(NSUInteger)wordCount
                          sentences:(NSUInteger)sentenceCount {
    
    // Handle edge cases
    if (wordCount == 0 || sentenceCount == 0) {
        return 0.0;
    }
    
    // Count total syllables
    __block NSUInteger totalSyllables = 0;
    
    [text enumerateSubstringsInRange:NSMakeRange(0, [text length])
                             options:NSStringEnumerationByWords
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                              totalSyllables += [self syllableCountForText:substring];
                          }];
    
    if (totalSyllables == 0) {
        totalSyllables = 1;
    }
    
    // Flesch Reading Ease formula
    double readingEase = 206.835 -
                        1.015 * ((double)wordCount / (double)sentenceCount) -
                        84.6 * ((double)totalSyllables / (double)wordCount);
    
    // Clamp to 0-100 range
    readingEase = MAX(0.0, MIN(100.0, readingEase));
    
    return readingEase;
}

// ============================================================================
// READING TIME CALCULATION
// ============================================================================
+ (NSUInteger)readingTimeInSecondsForWordCount:(NSUInteger)wordCount
                               wordsPerMinute:(NSUInteger)wpm {
    
    if (wpm == 0) {
        wpm = 200; // Default 200 WPM
    }
    
    // (wordCount / wpm) * 60 = time in seconds
    NSUInteger seconds = (wordCount * 60) / wpm;
    
    // Minimum 1 second reading time
    return MAX(1, (int)seconds);
}

// ============================================================================
// DIFFICULTY CATEGORIZATION
// ============================================================================
+ (ReadabilityDifficulty)difficultyLevelForGradeLevel:(double)gradeLevel {
    
    if (gradeLevel <= 6.0) {
        return ReadabilityDifficultyEasy;
    } else if (gradeLevel <= 12.0) {
        return ReadabilityDifficultyModerate;
    } else {
        return ReadabilityDifficultyHard;
    }
}

+ (NSString *)difficultyDescriptionForLevel:(ReadabilityDifficulty)level {
    
    switch (level) {
        case ReadabilityDifficultyEasy:
            return @"Easy";
        case ReadabilityDifficultyModerate:
            return @"Moderate";
        case ReadabilityDifficultyHard:
            return @"Hard";
        default:
            return @"Unknown";
    }
}

+ (NSString *)difficultyEmojiForLevel:(ReadabilityDifficulty)level {
    
    switch (level) {
        case ReadabilityDifficultyEasy:
            return @"🟢"; // Green
        case ReadabilityDifficultyModerate:
            return @"🔵"; // Blue
        case ReadabilityDifficultyHard:
            return @"🔴"; // Red
        default:
            return @"⚪"; // Gray
    }
}

// ============================================================================
// CODE DETECTION (simple heuristic)
// ============================================================================
+ (BOOL)looksLikeCodeForText:(NSString *)text {
    
    NSString *lowerText = [text lowercaseString];
    
    // Check for common code patterns
    NSArray *codeIndicators = @[
        @"function ", @"const ", @"let ", @"var ",
        @"if (", @"for (", @"while (", @"return ",
        @"class ", @"def ", @"import ", @"export ",
        @"{", @"}", @"=>", @"->", @"&&", @"||"
    ];
    
    NSInteger codeIndicatorCount = 0;
    
    for (NSString *indicator in codeIndicators) {
        if ([lowerText containsString:indicator]) {
            codeIndicatorCount++;
        }
    }
    
    // If 3+ code indicators found, likely code
    return codeIndicatorCount >= 3;
}

// ============================================================================
// READABILITY RATING (user-friendly summary)
// ============================================================================
+ (NSString *)readabilityRatingForText:(NSString *)text
                                 words:(NSUInteger)wordCount
                             sentences:(NSUInteger)sentenceCount {
    
    // Handle empty/invalid text
    if (wordCount == 0 || sentenceCount == 0) {
        return @"Insufficient text";
    }
    
    // Check if looks like code
    if ([self looksLikeCodeForText:text]) {
        return @"Code snippet detected";
    }
    
    // Calculate grade level and difficulty
    double gradeLevel = [self fleschKincaidGradeLevelForText:text
                                                       words:wordCount
                                                   sentences:sentenceCount];
    
    ReadabilityDifficulty difficulty = [self difficultyLevelForGradeLevel:gradeLevel];
    NSString *emoji = [self difficultyEmojiForLevel:difficulty];
    NSString *difficultyText = [self difficultyDescriptionForLevel:difficulty];
    
    // Determine grade description
    NSString *gradeDescription;
    if (gradeLevel <= 6) {
        gradeDescription = @"Elementary";
    } else if (gradeLevel <= 9) {
        gradeDescription = @"High School";
    } else if (gradeLevel <= 13) {
        gradeDescription = @"College";
    } else {
        gradeDescription = @"Graduate";
    }
    
    return [NSString stringWithFormat:@"%@ %@ (%@, Grade %.1f)",
            emoji, gradeDescription, difficultyText, gradeLevel];
}

@end
