//
//  SentimentAnalyzer.m
//  Word-Counter
//
//  Created by Rares Tamas on 4/15/26.
//  Copyright (c) 2026 Rares Tamas. All rights reserved.
//

#import "SentimentAnalyzer.h"
#import <NaturalLanguage/NaturalLanguage.h>

@implementation SentimentResult

- (instancetype)initWithScore:(double)score sentiment:(SentimentType)sentiment {
    self = [super init];
    if (self) {
        self.score = score;
        self.sentiment = sentiment;
        
        // Set label based on sentiment
        switch (sentiment) {
            case SentimentTypePositive:
                self.label = @"Positive";
                self.emoji = @"🟢";
                break;
            case SentimentTypeNeutral:
                self.label = @"Neutral";
                self.emoji = @"⚪";
                break;
            case SentimentTypeNegative:
                self.label = @"Negative";
                self.emoji = @"🔴";
                break;
            default:
                self.label = @"Unknown";
                self.emoji = @"❓";
                break;
        }
        
        // Determine confidence based on score magnitude
        double absScore = fabs(score);
        if (absScore >= 0.7) {
            self.confidence = @"High";
        } else if (absScore >= 0.4) {
            self.confidence = @"Medium";
        } else {
            self.confidence = @"Low";
        }
        
        self.language = @"en"; // Default to English
    }
    return self;
}

@end


@implementation SentimentAnalyzer

// ============================================================================
// LANGUAGE DETECTION
// ============================================================================
+ (NSString *)detectLanguageForText:(NSString *)text {
    
    if ([text length] == 0) {
        return @"en";
    }
    
    // Use NLLanguageRecognizer to detect language
    if (@available(macOS 10.14, *)) {
        NLLanguageRecognizer *recognizer = [[NLLanguageRecognizer alloc] init];
        [recognizer processString:text];
        
        NLLanguage dominantLanguage = recognizer.dominantLanguage;
        if (dominantLanguage) {
            return dominantLanguage;
        }
    }
    
    return @"en"; // Fallback to English
}

// ============================================================================
// TEXT VALIDATION FOR SENTIMENT ANALYSIS
// ============================================================================
+ (BOOL)isTextValidForSentimentAnalysisWithWordCount:(NSUInteger)wordCount {
    
    // Very short text (< 5 words) is unreliable for sentiment
    if (wordCount < 5) {
        return NO;
    }
    
    return YES;
}

// ============================================================================
// SENTIMENT ANALYSIS
// ============================================================================
+ (SentimentResult *)analyzeSentimentForText:(NSString *)text {
    
    if ([text length] == 0) {
        return [[SentimentResult alloc] initWithScore:0.0 sentiment:SentimentTypeUnknown];
    }
    
    // Create tagger for sentiment analysis
    // NaturalLanguage framework available on macOS 15.0+
    NLTagger *tagger = [[NLTagger alloc] initWithTagSchemes:@[NSLinguisticTagSchemeLemma, NSLinguisticTagSchemeLanguage, NSLinguisticTagSchemeNameType]];
    [tagger setString:text];
    
    // Try to detect language
    NSString *language = [self detectLanguageForText:text];
    SentimentResult *result = [[SentimentResult alloc] initWithScore:0.0 sentiment:SentimentTypeUnknown];
    result.language = language;
    
    // Process text to extract sentiments
    __block double totalScore = 0.0;
    __block NSUInteger sentenceCount = 0;
    __block NSUInteger positiveCount = 0;
    __block NSUInteger negativeCount = 0;
    __block NSUInteger neutralCount = 0;
    
    // Analyze by sentences for better accuracy
    [text enumerateSubstringsInRange:NSMakeRange(0, [text length])
                                options:NSStringEnumerationBySentences
                             usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                 
                                 // Simple sentiment heuristic based on keywords
                                 NSString *lowerSubstring = [substring lowercaseString];
                                 
                                 // Positive indicators
                                 NSArray *positiveWords = @[@"good", @"great", @"excellent", @"amazing", @"wonderful", @"beautiful", @"love", @"happy", @"excited", @"fantastic", @"awesome", @"brilliant", @"perfect", @"talented", @"success", @"best"];
                                 
                                 // Negative indicators
                                 NSArray *negativeWords = @[@"bad", @"terrible", @"awful", @"horrible", @"hate", @"sad", @"angry", @"disappointed", @"wrong", @"worst", @"ugly", @"failed", @"failure", @"poor", @"stupid"];
                                 
                                 NSInteger positiveMatches = 0;
                                 NSInteger negativeMatches = 0;
                                 
                                 for (NSString *word in positiveWords) {
                                     if ([lowerSubstring containsString:word]) {
                                         positiveMatches++;
                                     }
                                 }
                                 
                                 for (NSString *word in negativeWords) {
                                     if ([lowerSubstring containsString:word]) {
                                         negativeMatches++;
                                     }
                                 }
                                 
                                 // Calculate sentence sentiment
                                 double sentenceSentiment = 0.0;
                                 if (positiveMatches > negativeMatches) {
                                     sentenceSentiment = (double)positiveMatches / (double)MAX(1, positiveMatches + negativeMatches);
                                     positiveCount++;
                                 } else if (negativeMatches > positiveMatches) {
                                     sentenceSentiment = -(double)negativeMatches / (double)MAX(1, positiveMatches + negativeMatches);
                                     negativeCount++;
                                 } else {
                                     neutralCount++;
                                 }
                                 
                                 totalScore += sentenceSentiment;
                                 sentenceCount++;
                             }];
        
        // Calculate final sentiment score (average)
        if (sentenceCount > 0) {
            result.score = totalScore / (double)sentenceCount;
            result.score = MAX(-1.0, MIN(1.0, result.score)); // Clamp to -1.0 to 1.0
        } else {
            result.score = 0.0;
        }
        
        // Classify sentiment based on score
        if (result.score > 0.3) {
            result.sentiment = SentimentTypePositive;
        } else if (result.score < -0.3) {
            result.sentiment = SentimentTypeNegative;
        } else {
            result.sentiment = SentimentTypeNeutral;
        }
        
        // Determine confidence based on how clear the sentiment is
        double absScore = fabs(result.score);
        if (absScore >= 0.7) {
            result.confidence = @"High";
        } else if (absScore >= 0.4) {
            result.confidence = @"Medium";
        } else {
            result.confidence = @"Low";
        }
        
        return result;
}

// ============================================================================
// SENTIMENT SUMMARY FOR DISPLAY
// ============================================================================
+ (NSString *)sentimentSummaryFromResult:(SentimentResult *)result {
    
    if (result == nil || result.sentiment == SentimentTypeUnknown) {
        return @"Sentiment: —";
    }
    
    NSString *toneSuggestion = @"";
    
    // Add tone description
    switch (result.sentiment) {
        case SentimentTypePositive:
            if (result.score > 0.7) {
                toneSuggestion = @"Very Uplifting";
            } else {
                toneSuggestion = @"Uplifting";
            }
            break;
        case SentimentTypeNegative:
            if (result.score < -0.7) {
                toneSuggestion = @"Very Critical";
            } else {
                toneSuggestion = @"Critical";
            }
            break;
        case SentimentTypeNeutral:
            toneSuggestion = @"Neutral";
            break;
        default:
            toneSuggestion = @"Unknown";
            break;
    }
    
    return [NSString stringWithFormat:@"Sentiment: %@ %@ (%.0f%%)",
            result.emoji, toneSuggestion, (result.score + 1.0) * 50.0];
}

@end
