//
//  AppDelegate.m
//  PercentCalculator
//
//  Created by Rares Tamas on 12/17/14.
//  Copyright (c) 2014 Rares Tamas. All rights reserved.
//

#import "AppDelegate.h"
#import <ServiceManagement/ServiceManagement.h>
#import <QuartzCore/QuartzCore.h>
#import "TextAnalytics.h"
#import "SentimentAnalyzer.h"

#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize aboutWindow, raresBtn, popUpView, attachedWindow, popupShowed, websiteBtn;

@synthesize counterWindow, wordsLabel, linesLabel, uniqueWordsLabel, characterLabel, sentencesLabel, charactersWithoutSpacesLabel, spacesLabel, turnOnBtn, readingTimeLabel, gradeLabel, fleshEaseLabel, sentimentLabel, syllableCountLabel, lettersLabel, onShowAdvancedButton, cutResultsButton, themeButton;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"firstTimeRunning", nil]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    /*
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    */
    
    popupShowed = NO;
    isOn = NO;
    isWindowExpanded = NO;
    lastPasteboardChangeCount = 0;
    
    [aboutWindow orderOut:self];
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:mainMenu];
    [statusItem setHighlightMode:YES];
    statusItem.enabled = YES;
    [statusItem setToolTip:@"Word-Counter"];  // app name
    [statusItem setImage:[NSImage imageNamed:@"MenuBarIcon.png"]];
    [[statusItem image] setTemplate:YES];
    [statusItem setTarget:self];
    [statusItem setAction:@selector(openPopUp:)];
    
    // For dark mode in yosemite
    SInt32 OSXversionMajor, OSXversionMinor;
    if (Gestalt(gestaltSystemVersionMajor, &OSXversionMajor) == noErr && Gestalt(gestaltSystemVersionMinor, &OSXversionMinor) == noErr) {
        
        if (OSXversionMajor == 10 && OSXversionMinor >= 10) {
            
            [statusItem.image setTemplate:YES];
        }
    }
    
    // check if app is running for the first time
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"firstTimeRunning"] == YES) {
        
        [self openPopUp:nil];
        
        BOOL firstTimeRun = NO;
        
        [[NSUserDefaults standardUserDefaults] setBool:firstTimeRun forKey:@"firstTimeRunning"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    [self coloredTitleButton:raresBtn andColor:[NSColor blueColor]];
    [self coloredTitleButton:websiteBtn andColor:[NSColor blueColor]];
    
    // Setup accessibility labels
    [self setupAccessibilityLabels];
}



// ========================================
// take string from the paste board (cmd+c)
// ========================================
- (NSString *)stringForType {
    
    NSPasteboard *myPasteboard = [NSPasteboard generalPasteboard];
    
    NSString *text = [myPasteboard stringForType:NSPasteboardTypeString];
    
    // Handle nil or empty pasteboard
    if (text == nil) {
        selectedText = @"";
    } else {
        selectedText = text;
    }
    
    return selectedText;
}


- (IBAction)onThemeButtonClicked:(id)sender {
}

- (IBAction)onCopyButtonClicked:(id)sender {
    
    NSMutableString *resultsToCopy = [NSMutableString string];
    
    // Copy in specific order: characters, characters without spaces, letters, words, unique words, sentences, lines, spaces, reading time, grade level, flesch ease, sentiment, syllables
    if (characterLabel) [resultsToCopy appendFormat:@"%@\n", characterLabel.stringValue];
    if (charactersWithoutSpacesLabel) [resultsToCopy appendFormat:@"%@\n", charactersWithoutSpacesLabel.stringValue];
    if (lettersLabel) [resultsToCopy appendFormat:@"%@\n", lettersLabel.stringValue];
    if (wordsLabel) [resultsToCopy appendFormat:@"%@\n", wordsLabel.stringValue];
    if (uniqueWordsLabel) [resultsToCopy appendFormat:@"%@\n", uniqueWordsLabel.stringValue];
    if (sentencesLabel) [resultsToCopy appendFormat:@"%@\n", sentencesLabel.stringValue];
    if (linesLabel) [resultsToCopy appendFormat:@"%@\n", linesLabel.stringValue];
    if (spacesLabel && !spacesLabel.hidden) [resultsToCopy appendFormat:@"%@\n", spacesLabel.stringValue];
    if (readingTimeLabel && !readingTimeLabel.hidden) [resultsToCopy appendFormat:@"%@\n", readingTimeLabel.stringValue];
    if (gradeLabel && !gradeLabel.hidden) [resultsToCopy appendFormat:@"%@\n", gradeLabel.stringValue];
    if (fleshEaseLabel && !fleshEaseLabel.hidden) [resultsToCopy appendFormat:@"%@\n", fleshEaseLabel.stringValue];
    if (sentimentLabel && !sentimentLabel.hidden) [resultsToCopy appendFormat:@"%@\n", sentimentLabel.stringValue];
    if (syllableCountLabel && !syllableCountLabel.hidden) [resultsToCopy appendFormat:@"%@\n", syllableCountLabel.stringValue];
    
    // Copy to pasteboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    [pasteboard setString:resultsToCopy forType:NSPasteboardTypeString];
}

- (IBAction)onShowAdvancedButtonClick:(id)sender {
    
    isWindowExpanded = !isWindowExpanded;  // Toggle state
    
    NSScreen *screen = [NSScreen mainScreen];
    CGFloat windowWidth = counterWindow.frame.size.width;
    CGFloat collapsedHeight = 300.0;
    CGFloat expandedHeight = 510.0;  // XIB size
    
    // Calculate new height based on state
    CGFloat newHeight = isWindowExpanded ? expandedHeight : collapsedHeight;
    
    // Keep x the same, adjust y so window expands upward
    CGFloat x = counterWindow.frame.origin.x;
    CGFloat newY = screen.frame.size.height - newHeight;
    
    // Animate the window resize with smooth easing
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.35];
    [[NSAnimationContext currentContext] setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[counterWindow animator] setFrame:NSMakeRect(x, newY, windowWidth, newHeight) display:YES];
    [NSAnimationContext endGrouping];
    
    // Animate label visibility with fade effect
    [self animateAdvancedLabelsVisibility];
    
    // Update button image
    [self updateAdvancedButtonImage];
}


// ==============================
// Animate advanced labels with fade
// ==============================
- (void)animateAdvancedLabelsVisibility {
    
    BOOL shouldHide = !isWindowExpanded;
    
    // Hide labels instantly when collapsing
    if (shouldHide) {
        for (NSTextField *label in @[readingTimeLabel, syllableCountLabel, sentimentLabel, fleshEaseLabel, gradeLabel, spacesLabel]) {
            if (label != nil) {
                [label setHidden:YES];
            }
        }
    } else {
        // Show labels instantly when expanding
        for (NSTextField *label in @[readingTimeLabel, syllableCountLabel, sentimentLabel, fleshEaseLabel, gradeLabel, spacesLabel]) {
            if (label != nil) {
                [label setHidden:NO];
            }
        }
    }
}


// ========================
// Update advanced button image
// ========================
- (void)updateAdvancedButtonImage {
    
    if (onShowAdvancedButton == nil) return;
    
    if (isWindowExpanded) {
        // Arrow up (collapse)
        onShowAdvancedButton.image = [NSImage imageNamed:@"arrow_up_icon"];
    } else {
        // Arrow down (expand)
        onShowAdvancedButton.image = [NSImage imageNamed:@"arrow_down_icon"];
    }
}

- (IBAction)clickedTurnOn:(id)sender {
        
    if (isOn == NO) {
        
        isOn = YES;
        isWindowExpanded = NO;  // Start collapsed
        
        [turnOnBtn setTitle:@"Turn Off"];
                
        NSScreen *screen = [NSScreen mainScreen];
        
        // Get current window width
        CGFloat windowWidth = counterWindow.frame.size.width;
        CGFloat collapsedHeight = 300.0;
        
        // Position at bottom-right, with collapsed height
        CGFloat x = screen.frame.size.width - windowWidth;
        CGFloat y = screen.frame.size.height - collapsedHeight;
        
        [counterWindow setFrame:NSMakeRect(x, y, windowWidth, collapsedHeight) display:YES];
        
        [counterWindow setCollectionBehavior:NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces |NSWindowCollectionBehaviorFullScreenAuxiliary];
        
        [counterWindow setLevel: NSStatusWindowLevel];
            
        [counterWindow makeKeyAndOrderFront:self];
        
        // Update advanced button image to show arrow-down and hide advanced labels
        [self updateAdvancedButtonImage];
        [self animateAdvancedLabelsVisibility];
        
        myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTick) userInfo:nil repeats:YES];
    }
    else {
        
        isOn = NO;
        
        [turnOnBtn setTitle:@"Turn On"];
        
        [counterWindow orderOut:nil];
        
        if (myTimer != nil) {
            
            [myTimer invalidate];
            
            myTimer = nil;
        }
    }
}



// ============================
// refresh every second numbers
// ============================
- (void)onTick {
   
    [self stringForType];
    
    [self showNumbers];
}


// ================================
// update stats from pasteboard
// ================================
- (void)updateFromPasteboard {
    
    [self stringForType];
    [self showNumbers];
    
    debounceTimer = nil;
}



// ===================
// get number of lines
// ===================
- (NSUInteger)numberOfLines {
    
    NSString *string = selectedText;
    
    // Handle nil or empty string
    if (string == nil || [string length] == 0) {
        return 0;
    }
    
    NSUInteger numberOfLines = 0;
    NSRange searchRange = NSMakeRange(0, 0);
    
    while (searchRange.location < [string length]) {
        
        searchRange.location = NSMaxRange([string lineRangeForRange:searchRange]);
        numberOfLines++;
    }
    
    return numberOfLines;
}



// ===================
// get number of words
// ===================
- (NSUInteger)numberOfWords {
    
    NSString *string = selectedText;
    
    if (string == nil || [string length] == 0) {
        return 0;
    }
    
    __block NSUInteger numberOfWords = 0;
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationByWords
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                numberOfWords++;
                            }];
    return numberOfWords;
}



// ==========================
// get number of unique words
// ==========================
- (NSUInteger)numberOfUniqueWords {
    
    NSString *string = selectedText;
    
    if (string == nil || [string length] == 0) {
        return 0;
    }
    
    NSString *lowerString = [string lowercaseString];
    NSMutableSet *uniqueWords = [NSMutableSet set];
    
    [lowerString enumerateSubstringsInRange:NSMakeRange(0, [lowerString length])
                                   options:NSStringEnumerationByWords
                                usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                    [uniqueWords addObject:substring];
                                }];
    
    return [uniqueWords count];
}



// =======================
// get number of sentences
// =======================
- (NSUInteger)numberOfSentences {
    
    NSString *string = selectedText;
    
    if (string == nil || [string length] == 0) {
        return 0;
    }
    
    __block NSUInteger numberOfSentences = 0;
    
    [string enumerateSubstringsInRange:NSMakeRange(0, [string length])
                               options:NSStringEnumerationBySentences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                numberOfSentences++;
                            }];
    
    return numberOfSentences;
}



// ========================
// get number of characters
// ========================
- (NSUInteger)numberOfCharacters {
    
    NSString *string = selectedText;
    
    if (string == nil) {
        return 0;
    }
    
    return [string length];
}



// =======================================
// get number of characters without spaces
// =======================================
- (NSUInteger)numberOfCharactersWithoutSpaces {
    
    NSString *string = selectedText;
    
    if (string == nil || [string length] == 0) {
        return 0;
    }
    
    int times = (int)[[string componentsSeparatedByString:@" "] count] - 1;
    
    int number = (int)[string length] - times;
    
    return number;
}



// ====================
// get number of spaces
// ====================
- (NSUInteger)numberOfSpaces {
    
    NSString *string = selectedText;
    
    if (string == nil || [string length] == 0) {
        return 0;
    }
    
    int times = (int)[[string componentsSeparatedByString:@" "] count] - 1;
    
    return times;
}



// ====================
// get number of letters
// ====================
- (NSUInteger)numberOfLetters {
    
    NSString *string = selectedText;
    
    if (string == nil || [string length] == 0) {
        return 0;
    }
    
    NSUInteger count = 0;
    for (NSUInteger i = 0; i < [string length]; i++) {
        unichar c = [string characterAtIndex:i];
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) {
            count++;
        }
    }
    
    return count;
}



// ======================
// show numbers in labels
// ======================
- (void)showNumbers {
    
    // Get metrics
    NSUInteger words = [self numberOfWords];
    NSUInteger sentences = [self numberOfSentences];
    NSUInteger lines = [self numberOfLines];
    NSUInteger uniqueWords = [self numberOfUniqueWords];
    NSUInteger characters = [self numberOfCharacters];
    NSUInteger charactersWithoutSpaces = [self numberOfCharactersWithoutSpaces];
    NSUInteger spaces = [self numberOfSpaces];
    
    // Update core metrics
    [sentencesLabel setStringValue:[NSString stringWithFormat:@"Sentences: %lu", (unsigned long)sentences]];
    [linesLabel setStringValue:[NSString stringWithFormat:@"Lines: %lu", (unsigned long)lines]];
    [wordsLabel setStringValue:[NSString stringWithFormat:@"Words: %lu", (unsigned long)words]];
    [uniqueWordsLabel setStringValue:[NSString stringWithFormat:@"Unique words: %lu", (unsigned long)uniqueWords]];
    [characterLabel setStringValue:[NSString stringWithFormat:@"Characters: %lu", (unsigned long)characters]];
    [charactersWithoutSpacesLabel setStringValue:[NSString stringWithFormat:@"Characters without spaces: %lu", (unsigned long)charactersWithoutSpaces]];
    [spacesLabel setStringValue:[NSString stringWithFormat:@"Spaces: %lu", (unsigned long)spaces]];
    
    // Letter count (alphabetic characters only)
    NSUInteger letters = [self numberOfLetters];
    if (lettersLabel != nil) {
        [lettersLabel setStringValue:[NSString stringWithFormat:@"Letters: %lu", (unsigned long)letters]];
    }
    
    // Calculate and display readability metrics (if outlets exist)
    if (words > 0 && sentences > 0) {
        
        // Reading time
        NSUInteger readingSeconds = [TextAnalytics readingTimeInSecondsForWordCount:words wordsPerMinute:200];
        if (readingTimeLabel != nil) {
            if (readingSeconds < 60) {
                [readingTimeLabel setStringValue:[NSString stringWithFormat:@"Reading Time: %lus", (unsigned long)readingSeconds]];
            } else {
                NSUInteger minutes = readingSeconds / 60;
                NSUInteger secs = readingSeconds % 60;
                [readingTimeLabel setStringValue:[NSString stringWithFormat:@"Reading Time: %lum %lus", (unsigned long)minutes, (unsigned long)secs]];
            }
        }
        
        // Syllable count
        NSUInteger syllables = [TextAnalytics syllableCountForText:selectedText];
        if (syllableCountLabel != nil) {
            [syllableCountLabel setStringValue:[NSString stringWithFormat:@"Syllables: %lu", (unsigned long)syllables]];
        }
        
        // Grade level & difficulty
        double gradeLevel = [TextAnalytics fleschKincaidGradeLevelForText:selectedText words:words sentences:sentences];
        ReadabilityDifficulty difficulty = [TextAnalytics difficultyLevelForGradeLevel:gradeLevel];
        NSString *emoji = [TextAnalytics difficultyEmojiForLevel:difficulty];
        
        if (gradeLabel != nil) {
            [gradeLabel setStringValue:[NSString stringWithFormat:@"Grade Level: %@ %.1f", emoji, gradeLevel]];
        }
        
        // Flesch Reading Ease
        double readingEase = [TextAnalytics fleschReadingEaseForText:selectedText words:words sentences:sentences];
        if (fleshEaseLabel != nil) {
            NSString *easeDescription;
            if (readingEase >= 90) {
                easeDescription = @"Very Easy";
            } else if (readingEase >= 80) {
                easeDescription = @"Easy";
            } else if (readingEase >= 70) {
                easeDescription = @"Standard";
            } else if (readingEase >= 60) {
                easeDescription = @"Somewhat Difficult";
            } else {
                easeDescription = @"Very Difficult";
            }
            [fleshEaseLabel setStringValue:[NSString stringWithFormat:@"Flesch Ease: %.1f (%@)", readingEase, easeDescription]];
        }
    } else {
        // Clear readability metrics if not enough text
        if (readingTimeLabel != nil) {
            [readingTimeLabel setStringValue:@"Reading Time: —"];
        }
        if (syllableCountLabel != nil) {
            [syllableCountLabel setStringValue:@"Syllables: —"];
        }
        if (gradeLabel != nil) {
            [gradeLabel setStringValue:@"Grade Level: —"];
        }
        if (fleshEaseLabel != nil) {
            [fleshEaseLabel setStringValue:@"Flesch Ease: —"];
        }
    }
    
    // Sentiment analysis (if outlet exists and text is valid)
    if (sentimentLabel != nil && words >= 5) {
        SentimentResult *sentiment = [SentimentAnalyzer analyzeSentimentForText:selectedText];
        NSString *sentimentDisplay = [SentimentAnalyzer sentimentSummaryFromResult:sentiment];
        [sentimentLabel setStringValue:sentimentDisplay];
    } else if (sentimentLabel != nil) {
        [sentimentLabel setStringValue:@"Sentiment: —"];
    }
}



// ========================
// show popUp from menu bar
// ========================
- (void)openPopUp:(id)sender {
    
    if (![counterWindow isVisible]) {
        isOn = NO;
        
        [turnOnBtn setTitle:@"Turn On"];
        
    }
    else {
        isOn = YES;
        
        [turnOnBtn setTitle:@"Turn Off"];
    }
    
    if (popupShowed == NO) {
        
        NSRect frame = [[statusItem valueForKey:@"window"] frame];
        
        NSPoint pt = NSMakePoint(NSMidX(frame), NSMinY(frame));
        attachedWindow = [[MAAttachedWindow alloc] initWithView:popUpView
                                                attachedToPoint:pt
                                                       inWindow:nil
                                                         onSide:MAPositionBottom
                                                     atDistance:5.0];
        
        attachedWindow.appDelegateObject = self;
        
        [attachedWindow makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
        
        popupShowed = YES;
    }
    else {
        
        [attachedWindow orderOut:nil];
        
        popupShowed = NO;
    }
}


// =======================
// setup accessibility labels
// =======================
- (void)setupAccessibilityLabels {
    
    // Core metrics
    [wordsLabel setAccessibilityLabel:@"Word count"];
    [sentencesLabel setAccessibilityLabel:@"Sentence count"];
    [linesLabel setAccessibilityLabel:@"Line count"];
    [characterLabel setAccessibilityLabel:@"Character count"];
    [charactersWithoutSpacesLabel setAccessibilityLabel:@"Characters without spaces"];
    [spacesLabel setAccessibilityLabel:@"Space count"];
    [uniqueWordsLabel setAccessibilityLabel:@"Unique word count"];
    
    // Readability metrics
    if (readingTimeLabel != nil) {
        [readingTimeLabel setAccessibilityLabel:@"Estimated reading time"];
    }
    if (gradeLabel != nil) {
        [gradeLabel setAccessibilityLabel:@"Grade level"];
    }
    if (fleshEaseLabel != nil) {
        [fleshEaseLabel setAccessibilityLabel:@"Flesch reading ease score"];
    }
    
    // Sentiment
    if (sentimentLabel != nil) {
        [sentimentLabel setAccessibilityLabel:@"Text sentiment analysis"];
    }
    
    // Buttons
    [turnOnBtn setAccessibilityLabel:@"Toggle text counter"];
}


// =================
// show about window
// =================
- (IBAction)clickedAbout:(id)sender {

    [aboutWindow makeKeyAndOrderFront:self];
}



// =========================
// set color to buttons text
// =========================
- (void)coloredTitleButton:(NSButton *)myButton andColor: (NSColor *)myColor {
    
    NSColor *color = myColor;
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[myButton attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
    [myButton setAttributedTitle:colorTitle];
}



// ==================
// send mail to rares
// ==================
- (IBAction)clickedRaresContact:(id)sender {
    
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"mailto:office@caffeinatetech.com"]];
}

// ========================
// send user to our website
// ========================
- (IBAction)clickedWebsite:(id)sender {
    
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"https://www.caffeinatetech.com"]];
}


// =======================
// cleanup on app shutdown
// =======================
- (void)dealloc {
    
    // Remove pasteboard notification observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Invalidate any outstanding timers
    if (myTimer != nil) {
        [myTimer invalidate];
        myTimer = nil;
    }
    
    if (debounceTimer != nil) {
        [debounceTimer invalidate];
        debounceTimer = nil;
    }
}


@end
