//
//  SentimentAnalyzer.h
//  Word-Counter
//
//  Created by Rares Tamas on 4/15/26.
//  Copyright (c) 2026 Rares Tamas. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SentimentType) {
    SentimentTypePositive,
    SentimentTypeNeutral,
    SentimentTypeNegative,
    SentimentTypeUnknown
};

@interface SentimentResult : NSObject

@property (nonatomic) double score;           // -1.0 to 1.0
@property (nonatomic) SentimentType sentiment; // Positive, Neutral, Negative
@property (nonatomic, copy) NSString *label;   // "Positive", "Neutral", "Negative"
@property (nonatomic, copy) NSString *emoji;   // 🟢, ⚪, 🔴
@property (nonatomic, copy) NSString *language; // Detected language
@property (nonatomic, copy) NSString *confidence; // "High", "Medium", "Low"

- (instancetype)initWithScore:(double)score sentiment:(SentimentType)sentiment;

@end


@interface SentimentAnalyzer : NSObject

/**
 Analyze sentiment of text using Apple's NaturalLanguage framework
 Returns a SentimentResult object with score, classification, and UI hints
 
 @param text The text to analyze
 @return SentimentResult with sentiment analysis
 */
+ (SentimentResult *)analyzeSentimentForText:(NSString *)text;

/**
 Detect the dominant language of text
 
 @param text The text to analyze
 @return ISO language code (e.g., "en", "fr", "de")
 */
+ (NSString *)detectLanguageForText:(NSString *)text;

/**
 Check if text is reliable for sentiment analysis
 (must be long enough, not code, not URL-heavy, etc.)
 
 @param text The text to validate
 @return YES if sentiment analysis would be meaningful
 */
+ (BOOL)isTextValidForSentimentAnalysisWithWordCount:(NSUInteger)wordCount;

/**
 Get a concise sentiment summary for display
 e.g., "🟢 Positive - Uplifting tone"
 
 @param result The SentimentResult from sentiment analysis
 @return User-friendly summary string
 */
+ (NSString *)sentimentSummaryFromResult:(SentimentResult *)result;

@end
