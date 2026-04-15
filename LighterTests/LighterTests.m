//
//  LighterTests.m
//  LighterTests
//
//  Created by Rares Tamas on 12/17/14.
//  Copyright (c) 2014 Rares Tamas. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "TextAnalytics.h"
#import "SentimentAnalyzer.h"

@interface LighterTests : XCTestCase

@end

@implementation LighterTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - TextAnalytics Tests

- (void)testSyllableCountingBasic {
    // Simple word syllable counts
    NSUInteger syllables = [TextAnalytics syllableCountForText:@"hello"];
    XCTAssertGreaterThan(syllables, 0, @"Syllable count should be positive");
    
    // "cat" = 1 syllable
    syllables = [TextAnalytics syllableCountForText:@"cat"];
    XCTAssertEqual(syllables, 1, @"'cat' should have 1 syllable");
}

- (void)testFleschKincaidGradeLevelSimple {
    // Very simple text (should be easy level - grade 1-6)
    NSString *simpleText = @"I like cats. They are nice. Cats are fun. I have a cat.";
    double gradeLevel = [TextAnalytics fleschKincaidGradeLevelForText:simpleText words:11 sentences:4];
    XCTAssertLessThan(gradeLevel, 7.0, @"Simple text should have low grade level");
    XCTAssertGreaterThan(gradeLevel, 0.0, @"Grade level should be positive");
}

- (void)testFleschKincaidGradeLevelComplex {
    // More complex text (should be higher level)
    NSString *complexText = @"The implementation of sophisticated computational methodologies necessitates comprehensive understanding of advanced linguistic principles.";
    double gradeLevel = [TextAnalytics fleschKincaidGradeLevelForText:complexText words:14 sentences:1];
    XCTAssertGreaterThan(gradeLevel, 12.0, @"Complex text should have high grade level");
}

- (void)testFleschReadingEase {
    // Reading ease should be between 0-100
    NSString *text = @"The quick brown fox jumps over the lazy dog. This is a test sentence.";
    double ease = [TextAnalytics fleschReadingEaseForText:text words:15 sentences:2];
    XCTAssertGreaterThanOrEqual(ease, 0.0, @"Reading ease should be >= 0");
    XCTAssertLessThanOrEqual(ease, 100.0, @"Reading ease should be <= 100");
}

- (void)testReadingTimeCalculation {
    // 200 words at 200 WPM = 60 seconds
    NSUInteger seconds = [TextAnalytics readingTimeInSecondsForWordCount:200 wordsPerMinute:200];
    XCTAssertEqual(seconds, 60, @"200 words at 200 WPM should be 60 seconds");
    
    // 100 words at 200 WPM = 30 seconds
    seconds = [TextAnalytics readingTimeInSecondsForWordCount:100 wordsPerMinute:200];
    XCTAssertEqual(seconds, 30, @"100 words at 200 WPM should be 30 seconds");
}

- (void)testDifficultyClassification {
    // Grade 3 = Easy
    ReadabilityDifficulty difficulty = [TextAnalytics difficultyLevelForGradeLevel:3.0];
    XCTAssertEqual(difficulty, ReadabilityDifficultyEasy, @"Grade 3 should be Easy");
    
    // Grade 9 = Moderate
    difficulty = [TextAnalytics difficultyLevelForGradeLevel:9.0];
    XCTAssertEqual(difficulty, ReadabilityDifficultyModerate, @"Grade 9 should be Moderate");
    
    // Grade 14 = Hard
    difficulty = [TextAnalytics difficultyLevelForGradeLevel:14.0];
    XCTAssertEqual(difficulty, ReadabilityDifficultyHard, @"Grade 14 should be Hard");
}

- (void)testCodeDetection {
    // Code-like text should be detected
    NSString *codeText = @"const x = 5; if (x > 3) { return true; } function test() { }";
    BOOL isCode = [TextAnalytics looksLikeCodeForText:codeText];
    XCTAssertTrue(isCode, @"Code-like text should be detected as code");
    
    // Regular text should not be detected as code
    NSString *regularText = @"This is just a normal sentence with no code in it at all.";
    isCode = [TextAnalytics looksLikeCodeForText:regularText];
    XCTAssertFalse(isCode, @"Regular text should not be detected as code");
}

- (void)testReadabilityRatingEmpty {
    // Empty text should show "Insufficient text"
    NSString *rating = [TextAnalytics readabilityRatingForText:@"" words:0 sentences:0];
    XCTAssertEqualObjects(rating, @"Insufficient text", @"Empty text should show insufficient message");
}

- (void)testReadabilityRatingCode {
    // Code should show code detected message
    NSString *codeText = @"function test() { const x = 5; if (x > 3) { return true; } }";
    NSString *rating = [TextAnalytics readabilityRatingForText:codeText words:10 sentences:1];
    XCTAssertEqualObjects(rating, @"Code snippet detected", @"Code should show code detected message");
}

#pragma mark - SentimentAnalyzer Tests

- (void)testSentimentAnalysisPositive {
    // Obviously positive text
    NSString *positiveText = @"This is absolutely wonderful and fantastic. I love it. The best thing ever.";
    SentimentResult *result = [SentimentAnalyzer analyzeSentimentForText:positiveText];
    XCTAssertNotNil(result, @"Sentiment result should not be nil");
    XCTAssertEqual(result.sentiment, SentimentTypePositive, @"Clearly positive text should be classified as positive");
    XCTAssertGreaterThan(result.score, 0.0, @"Positive sentiment score should be > 0");
}

- (void)testSentimentAnalysisNegative {
    // Obviously negative text
    NSString *negativeText = @"This is terrible and awful. I hate it. The worst thing ever.";
    SentimentResult *result = [SentimentAnalyzer analyzeSentimentForText:negativeText];
    XCTAssertNotNil(result, @"Sentiment result should not be nil");
    XCTAssertEqual(result.sentiment, SentimentTypeNegative, @"Clearly negative text should be classified as negative");
    XCTAssertLessThan(result.score, 0.0, @"Negative sentiment score should be < 0");
}

- (void)testSentimentAnalysisNeutral {
    // Neutral text with no emotional words
    NSString *neutralText = @"The cat sat on the mat. The mat was blue. The cat was white.";
    SentimentResult *result = [SentimentAnalyzer analyzeSentimentForText:neutralText];
    XCTAssertNotNil(result, @"Sentiment result should not be nil");
    XCTAssertEqual(result.sentiment, SentimentTypeNeutral, @"Neutral text should be classified as neutral");
}

- (void)testSentimentResultProperties {
    // Test that SentimentResult is properly initialized
    SentimentResult *result = [[SentimentResult alloc] initWithScore:0.75 sentiment:SentimentTypePositive];
    XCTAssertEqual(result.score, 0.75, @"Score should be set correctly");
    XCTAssertEqual(result.sentiment, SentimentTypePositive, @"Sentiment should be positive");
    XCTAssertEqualObjects(result.label, @"Positive", @"Label should be 'Positive'");
    XCTAssertEqualObjects(result.emoji, @"🟢", @"Emoji should be green circle");
}

- (void)testLanguageDetection {
    // English text
    NSString *englishText = @"This is a sample text in English.";
    NSString *language = [SentimentAnalyzer detectLanguageForText:englishText];
    XCTAssertNotNil(language, @"Language detection should return a value");
    // Should return "en" or similar language code
    XCTAssertEqual([language length], 2, @"Language code should be 2 characters");
}

- (void)testTextValidationForSentiment {
    // Very short text (< 5 words)
    BOOL isValid = [SentimentAnalyzer isTextValidForSentimentAnalysisWithWordCount:3];
    XCTAssertFalse(isValid, @"Text with < 5 words should not be valid for sentiment");
    
    // Sufficient text (>= 5 words)
    isValid = [SentimentAnalyzer isTextValidForSentimentAnalysisWithWordCount:10];
    XCTAssertTrue(isValid, @"Text with >= 5 words should be valid for sentiment");
}

- (void)testSentimentSummaryDisplay {
    // Test summary generation
    SentimentResult *positiveResult = [[SentimentResult alloc] initWithScore:0.8 sentiment:SentimentTypePositive];
    NSString *summary = [SentimentAnalyzer sentimentSummaryFromResult:positiveResult];
    XCTAssertNotNil(summary, @"Sentiment summary should not be nil");
    XCTAssertTrue([summary containsString:@"🟢"], @"Summary should contain positive emoji");
    XCTAssertTrue([summary containsString:@"Sentiment"], @"Summary should contain word 'Sentiment'");
}

#pragma mark - Integration Tests

- (void)testFullTextAnalysisPipeline {
    // Test complete analysis of a text sample
    NSString *sampleText = @"The implementation of this excellent system is wonderful. It works perfectly.";
    
    // Count words & sentences (simple version)
    __block NSUInteger wordCount = 0;
    [sampleText enumerateSubstringsInRange:NSMakeRange(0, [sampleText length])
                                   options:NSStringEnumerationByWords
                                usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                    wordCount++;
                                }];
    
    __block NSUInteger sentenceCount = 0;
    [sampleText enumerateSubstringsInRange:NSMakeRange(0, [sampleText length])
                                   options:NSStringEnumerationBySentences
                                usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                    sentenceCount++;
                                }];
    
    // Test readability
    double gradeLevel = [TextAnalytics fleschKincaidGradeLevelForText:sampleText words:wordCount sentences:sentenceCount];
    XCTAssertGreaterThan(gradeLevel, 0.0, @"Grade level should be calculated");
    
    double readingEase = [TextAnalytics fleschReadingEaseForText:sampleText words:wordCount sentences:sentenceCount];
    XCTAssertGreaterThanOrEqual(readingEase, 0.0, @"Reading ease should be calculated");
    
    NSUInteger readingTime = [TextAnalytics readingTimeInSecondsForWordCount:wordCount wordsPerMinute:200];
    XCTAssertGreaterThan(readingTime, 0, @"Reading time should be calculated");
    
    // Test sentiment
    SentimentResult *sentiment = [SentimentAnalyzer analyzeSentimentForText:sampleText];
    XCTAssertNotNil(sentiment, @"Sentiment should be analyzed");
}

@end
