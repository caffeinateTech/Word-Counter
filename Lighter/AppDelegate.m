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

#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>

@interface AppDelegate ()

- (void)registerInteractionMonitor;
- (void)unregisterInteractionMonitor;
- (void)resetInteractionInactivityTimer;
- (void)userDidInteract;
- (void)compactCounterWindow;
- (void)expandCounterWindow;
- (NSString *)formattedMetricWithTitle:(NSString *)title count:(NSUInteger)count;
- (void)buildCompactMetricsViewWithWidth:(CGFloat)compactWidth height:(CGFloat)compactHeight;
- (void)updateCompactMetricValuesWithCharacters:(NSUInteger)characters
                       charactersWithoutSpaces:(NSUInteger)charactersWithoutSpaces
                                        letters:(NSUInteger)letters
                                          words:(NSUInteger)words
                                    uniqueWords:(NSUInteger)uniqueWords
                                      sentences:(NSUInteger)sentences
                                          lines:(NSUInteger)lines
                                         spaces:(NSUInteger)spaces
                                 readingSeconds:(NSUInteger)readingSeconds
                                       syllables:(NSUInteger)syllables
                           hasReadabilityValues:(BOOL)hasReadabilityValues;

@end

@implementation AppDelegate

@synthesize aboutWindow, raresBtn, popUpView, attachedWindow, popupShowed, websiteBtn;

@synthesize counterWindow, wordsLabel, linesLabel, uniqueWordsLabel, characterLabel, sentencesLabel, charactersWithoutSpacesLabel, spacesLabel, turnOnBtn, readingTimeLabel, syllableCountLabel, lettersLabel, onShowAdvancedButton, cutResultsButton, themeButton, quitButton, aboutButton, aboutTextField, websiteTitleLabel, contactTitleLabel;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

  [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"firstTimeRunning", nil]];
  [[NSUserDefaults standardUserDefaults] synchronize];

  /*
   NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
   [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
   */
//  [counterWindow setBackgroundColor:[NSColor clearColor]];

  popupShowed = NO;
  isOn = NO;
  isWindowExpanded = NO;
  isCompactMode = NO;
  wasWindowExpandedBeforeCompact = NO;
  hasLastExpandedWindowFrame = NO;
  hasOriginalCounterWindowStyleMask = NO;
  // Load theme from user defaults, default to dark theme
  isDarkTheme = [[NSUserDefaults standardUserDefaults] objectForKey:@"isDarkTheme"] != nil ? [[NSUserDefaults standardUserDefaults] boolForKey:@"isDarkTheme"] : YES;
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



  // Setup accessibility labels
  [self setupAccessibilityLabels];

  // Lock windows to light appearance so they don't follow system theme changes
  // They will only respond to our manual theme toggle
  [counterWindow setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
  [aboutWindow setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
//  [popUpView setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];

  // Lock buttons to light appearance so they don't follow system theme changes
  // They will only respond to our manual theme toggle
  [turnOnBtn setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
  [onShowAdvancedButton setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
  [cutResultsButton setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
  [themeButton setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
  [quitButton setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
  [aboutButton setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]];
  [raresBtn setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];
  [websiteBtn setAppearance:[NSAppearance appearanceNamed:NSAppearanceNameAqua]];

  // Apply initial theme
  [self applyTheme];
  
  if (counterWindow != nil) {
    originalCounterWindowStyleMask = [counterWindow styleMask];
    hasOriginalCounterWindowStyleMask = YES;
    fullCounterContentView = [counterWindow contentView];
    originalCounterWindowBackgroundColor = [counterWindow backgroundColor];
  }
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

  isDarkTheme = !isDarkTheme;  // Toggle theme
  [[NSUserDefaults standardUserDefaults] setBool:isDarkTheme forKey:@"isDarkTheme"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  [self applyTheme];
}


// ========================
// Apply theme to all UI elements
// ========================
- (void)applyTheme {

  if (isDarkTheme) {
    // Dark theme: white text
    NSColor *textColor = [NSColor whiteColor];

    // Apply to labels - build array conditionally to avoid nil objects
    NSMutableArray *labels = [NSMutableArray array];
    for (NSTextField *label in @[wordsLabel, sentencesLabel, linesLabel, characterLabel,
                                 charactersWithoutSpacesLabel, spacesLabel, uniqueWordsLabel,
                                 lettersLabel, readingTimeLabel, syllableCountLabel,
                                 aboutTextField, websiteTitleLabel, contactTitleLabel]) {
      if (label != nil) {
        [labels addObject:label];
      }
    }
    for (NSTextField *label in labels) {
      label.textColor = textColor;
    }

    // Set button title first, then apply color
    [themeButton setTitle:@"Dark Theme"];
    [self coloredTitleButton:turnOnBtn andColor:textColor];
    [self coloredTitleButton:onShowAdvancedButton andColor:textColor];
    [self coloredTitleButton:cutResultsButton andColor:textColor];
    [self coloredTitleButton:themeButton andColor:textColor];
    [self coloredTitleButton:quitButton andColor:textColor];
    [self coloredTitleButton:aboutButton andColor:textColor];
    [self coloredTitleButton:raresBtn andColor:[NSColor linkColor]];
    [self coloredTitleButton:websiteBtn andColor:[NSColor linkColor]];

    // Update window colors for dark theme (HUD style dark background)
    if (counterWindow != nil) {
      //[counterWindow setBackgroundColor:MAATTACHEDWINDOW_DEFAULT_BACKGROUND_COLOR];
    }
    if (aboutWindow != nil) {
      //[aboutWindow setBackgroundColor:MAATTACHEDWINDOW_DEFAULT_BACKGROUND_COLOR];
    }

    // Update attachedWindow colors for dark theme
    if (attachedWindow != nil) {
      //[attachedWindow setBackgroundColor:MAATTACHEDWINDOW_DEFAULT_BACKGROUND_COLOR];
      [attachedWindow setBorderColor:MAATTACHEDWINDOW_DEFAULT_BORDER_COLOR];
    }
    
    // Compact mode theme state (persist across mode switches)
    if (compactMetricValueLabels != nil) {
      for (NSTextField *label in compactMetricValueLabels) {
        [label setTextColor:[NSColor whiteColor]];
      }
    }
    if (compactCounterContentView != nil && compactCounterContentView.layer != nil) {
      compactCounterContentView.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.0 alpha:0.9] CGColor];
    }
  } else {
    // Light theme: black text
    NSColor *textColor = [NSColor blackColor];

    // Apply to labels - build array conditionally to avoid nil objects
    NSMutableArray *labels = [NSMutableArray array];
    for (NSTextField *label in @[wordsLabel, sentencesLabel, linesLabel, characterLabel,
                                 charactersWithoutSpacesLabel, spacesLabel, uniqueWordsLabel,
                                 lettersLabel, readingTimeLabel, syllableCountLabel,
                                 aboutTextField, websiteTitleLabel, contactTitleLabel]) {
      if (label != nil) {
        [labels addObject:label];
      }
    }
    for (NSTextField *label in labels) {
      label.textColor = textColor;
    }

    // Set button title first, then apply color
    [themeButton setTitle:@"Light Theme"];
    [self coloredTitleButton:turnOnBtn andColor:textColor];
    [self coloredTitleButton:onShowAdvancedButton andColor:textColor];
    [self coloredTitleButton:cutResultsButton andColor:textColor];
    [self coloredTitleButton:themeButton andColor:textColor];
    [self coloredTitleButton:quitButton andColor:textColor];
    [self coloredTitleButton:aboutButton andColor:textColor];
    [self coloredTitleButton:raresBtn andColor:[NSColor linkColor]];
    [self coloredTitleButton:websiteBtn andColor:[NSColor linkColor]];

    // Update window colors for light theme (white background)
    if (counterWindow != nil) {
      //[counterWindow setBackgroundColor:MAATTACHEDWINDOW_LIGHT_BACKGROUND_COLOR];
    }
    if (aboutWindow != nil) {
     //[aboutWindow setBackgroundColor:MAATTACHEDWINDOW_LIGHT_BACKGROUND_COLOR];
    }

    // Update attachedWindow colors for light theme
    if (attachedWindow != nil) {
      //[attachedWindow setBackgroundColor:MAATTACHEDWINDOW_LIGHT_BACKGROUND_COLOR];
      [attachedWindow setBorderColor:MAATTACHEDWINDOW_LIGHT_BORDER_COLOR];
    }
    
    // Compact mode theme state (persist across mode switches)
    if (compactMetricValueLabels != nil) {
      for (NSTextField *label in compactMetricValueLabels) {
        [label setTextColor:[NSColor blackColor]];
      }
    }
    if (compactCounterContentView != nil && compactCounterContentView.layer != nil) {
      compactCounterContentView.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:1.0 alpha:0.9] CGColor];
    }
  }
}

- (IBAction)onCopyButtonClicked:(id)sender {
  [self userDidInteract];

  NSMutableString *resultsToCopy = [NSMutableString string];

  // Copy in specific order: characters, characters without spaces, letters, words, unique words, sentences, lines, spaces, reading time, syllables
  if (characterLabel) [resultsToCopy appendFormat:@"%@\n", characterLabel.stringValue];
  if (charactersWithoutSpacesLabel) [resultsToCopy appendFormat:@"%@\n", charactersWithoutSpacesLabel.stringValue];
  if (lettersLabel) [resultsToCopy appendFormat:@"%@\n", lettersLabel.stringValue];
  if (wordsLabel) [resultsToCopy appendFormat:@"%@\n", wordsLabel.stringValue];
  if (uniqueWordsLabel) [resultsToCopy appendFormat:@"%@\n", uniqueWordsLabel.stringValue];
  if (sentencesLabel) [resultsToCopy appendFormat:@"%@\n", sentencesLabel.stringValue];
  if (linesLabel) [resultsToCopy appendFormat:@"%@\n", linesLabel.stringValue];
  if (spacesLabel && !spacesLabel.hidden) [resultsToCopy appendFormat:@"%@\n", spacesLabel.stringValue];
  if (readingTimeLabel && !readingTimeLabel.hidden) [resultsToCopy appendFormat:@"%@\n", readingTimeLabel.stringValue];
  if (syllableCountLabel && !syllableCountLabel.hidden) [resultsToCopy appendFormat:@"%@\n", syllableCountLabel.stringValue];

  // Copy to pasteboard
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  [pasteboard clearContents];
  [pasteboard setString:resultsToCopy forType:NSPasteboardTypeString];
}

- (IBAction)onShowAdvancedButtonClick:(id)sender {
  [self userDidInteract];

  isWindowExpanded = !isWindowExpanded;  // Toggle state

  NSScreen *screen = [NSScreen mainScreen];
  CGFloat windowWidth = counterWindow.frame.size.width;
  CGFloat collapsedHeight = 300.0;
  CGFloat expandedHeight = 400.0;  // XIB size

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
    for (NSTextField *label in @[readingTimeLabel, syllableCountLabel, spacesLabel]) {
      if (label != nil) {
        [label setHidden:YES];
      }
    }
  } else {
    // Show labels instantly when expanding
    for (NSTextField *label in @[readingTimeLabel, syllableCountLabel, spacesLabel]) {
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
    isCompactMode = NO;
    if (fullCounterContentView != nil && [counterWindow contentView] != fullCounterContentView) {
      [counterWindow setContentView:fullCounterContentView];
    }

    [turnOnBtn setTitle:@"Turn Off"];

    NSScreen *screen = [NSScreen mainScreen];

    // Always start at full width when turning on.
    CGFloat windowWidth = 260.0;
    CGFloat collapsedHeight = 300.0;

    // Position at bottom-right, with collapsed height
    CGFloat x = screen.frame.size.width - windowWidth;
    CGFloat y = screen.frame.size.height - collapsedHeight;

    [counterWindow setFrame:NSMakeRect(x, y, windowWidth, collapsedHeight) display:YES];
    lastExpandedWindowFrame = [counterWindow frame];
    hasLastExpandedWindowFrame = YES;
    if (hasOriginalCounterWindowStyleMask) {
      [counterWindow setStyleMask:originalCounterWindowStyleMask];
    }
    [counterWindow setOpaque:YES];
    [counterWindow setAlphaValue:1.0];
    if (originalCounterWindowBackgroundColor != nil) {
      [counterWindow setBackgroundColor:originalCounterWindowBackgroundColor];
    }

    [counterWindow setCollectionBehavior:NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces |NSWindowCollectionBehaviorFullScreenAuxiliary];

    [counterWindow setLevel: NSStatusWindowLevel];

    [counterWindow makeKeyAndOrderFront:self];

    // Update advanced button image to show arrow-down and hide advanced labels
    [self updateAdvancedButtonImage];
    [self animateAdvancedLabelsVisibility];
    [self registerInteractionMonitor];
    [self resetInteractionInactivityTimer];

    myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(onTick) userInfo:nil repeats:YES];
  }
  else {

    isOn = NO;

    [turnOnBtn setTitle:@"Turn On"];

    [counterWindow orderOut:nil];
    if (fullCounterContentView != nil && [counterWindow contentView] != fullCounterContentView) {
      [counterWindow setContentView:fullCounterContentView];
    }
    [self unregisterInteractionMonitor];
    if (interactionInactivityTimer != nil) {
      [interactionInactivityTimer invalidate];
      interactionInactivityTimer = nil;
    }
    isCompactMode = NO;
    hasLastExpandedWindowFrame = NO;

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
  NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
  if ([pasteboard changeCount] != lastPasteboardChangeCount) {
    lastPasteboardChangeCount = [pasteboard changeCount];
    [self userDidInteract];
  }

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
  NSUInteger letters = [self numberOfLetters];
  BOOL hasReadabilityValues = (words > 0 && sentences > 0);
  NSUInteger readingSeconds = 0;
  NSUInteger syllables = 0;
  if (hasReadabilityValues) {
    readingSeconds = [TextAnalytics readingTimeInSecondsForWordCount:words wordsPerMinute:200];
    syllables = [TextAnalytics syllableCountForText:selectedText];
  }

  // Update core metrics
  [sentencesLabel setStringValue:[self formattedMetricWithTitle:@"Sentences" count:sentences]];
  [linesLabel setStringValue:[self formattedMetricWithTitle:@"Lines" count:lines]];
  [wordsLabel setStringValue:[self formattedMetricWithTitle:@"Words" count:words]];
  [uniqueWordsLabel setStringValue:[self formattedMetricWithTitle:@"Unique words" count:uniqueWords]];
  [characterLabel setStringValue:[self formattedMetricWithTitle:@"Characters" count:characters]];
  [charactersWithoutSpacesLabel setStringValue:[self formattedMetricWithTitle:@"Characters without spaces" count:charactersWithoutSpaces]];
  [spacesLabel setStringValue:[self formattedMetricWithTitle:@"Spaces" count:spaces]];

  // Letter count (alphabetic characters only)
  if (lettersLabel != nil) {
    [lettersLabel setStringValue:[self formattedMetricWithTitle:@"Letters" count:letters]];
  }

  // Calculate and display remaining readability metrics (if outlets exist)
  if (words > 0 && sentences > 0) {

    // Reading time
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
    if (syllableCountLabel != nil) {
      [syllableCountLabel setStringValue:[NSString stringWithFormat:@"Syllables: %lu", (unsigned long)syllables]];
    }

  } else {
    // Clear metrics if not enough text
    if (readingTimeLabel != nil) {
      [readingTimeLabel setStringValue:@"Reading Time: —"];
    }
    if (syllableCountLabel != nil) {
      [syllableCountLabel setStringValue:@"Syllables: —"];
    }
  }
  
  if (isCompactMode) {
    [self updateCompactMetricValuesWithCharacters:characters
                         charactersWithoutSpaces:charactersWithoutSpaces
                                          letters:letters
                                            words:words
                                      uniqueWords:uniqueWords
                                        sentences:sentences
                                            lines:lines
                                           spaces:spaces
                                   readingSeconds:readingSeconds
                                         syllables:syllables
                             hasReadabilityValues:hasReadabilityValues];
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

    // Apply current theme to the newly created attachedWindow
    [self applyTheme];

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

  // Remove all notification observers
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
  
  if (interactionInactivityTimer != nil) {
    [interactionInactivityTimer invalidate];
    interactionInactivityTimer = nil;
  }
  
  [self unregisterInteractionMonitor];
}

// =======================
// Compact mode formatting
// =======================
- (NSString *)formattedMetricWithTitle:(NSString *)title count:(NSUInteger)count {
  if (isCompactMode) {
    return [NSString stringWithFormat:@"%lu", (unsigned long)count];
  }
  return [NSString stringWithFormat:@"%@: %lu", title, (unsigned long)count];
}

// =======================
// User interaction tracker
// =======================
- (void)registerInteractionMonitor {
  if (interactionMonitor != nil) return;
  
  __weak typeof(self) weakSelf = self;
  interactionMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown) handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf == nil || !isOn || counterWindow == nil || ![counterWindow isVisible]) {
      return event;
    }
    
    NSPoint mouseLocation = [NSEvent mouseLocation];
    if (NSPointInRect(mouseLocation, [counterWindow frame])) {
      [strongSelf userDidInteract];
    }
    return event;
  }];
}

- (void)unregisterInteractionMonitor {
  if (interactionMonitor != nil) {
    [NSEvent removeMonitor:interactionMonitor];
    interactionMonitor = nil;
  }
}

- (void)resetInteractionInactivityTimer {
  if (interactionInactivityTimer != nil) {
    [interactionInactivityTimer invalidate];
  }
  interactionInactivityTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(compactCounterWindow) userInfo:nil repeats:NO];
}

- (void)userDidInteract {
  if (!isOn || counterWindow == nil || ![counterWindow isVisible]) return;
  
  [self expandCounterWindow];
  [self resetInteractionInactivityTimer];
}

- (void)compactCounterWindow {
  if (!isOn || counterWindow == nil || ![counterWindow isVisible] || isCompactMode) return;
  
  // Preserve current advanced/collapsed state so it can be restored on expand.
  wasWindowExpandedBeforeCompact = isWindowExpanded;
  isCompactMode = YES;
  isWindowExpanded = NO;
  [self animateAdvancedLabelsVisibility];
  [self updateAdvancedButtonImage];
  
  if (onShowAdvancedButton != nil) [onShowAdvancedButton setHidden:YES];
  if (cutResultsButton != nil) [cutResultsButton setHidden:YES];
  
  // Save current frame to restore exact position/size on expand.
  lastExpandedWindowFrame = [counterWindow frame];
  hasLastExpandedWindowFrame = YES;
  
  if (!hasOriginalCounterWindowStyleMask) {
    originalCounterWindowStyleMask = [counterWindow styleMask];
    hasOriginalCounterWindowStyleMask = YES;
  }
  
  CGFloat compactWidth = 40.0;
  CGFloat compactHeight = [counterWindow frame].size.height;
  [counterWindow setContentMinSize:NSMakeSize(compactWidth, compactHeight)];
  
  // Replace full constrained content with a minimal compact content view so
  // Auto Layout constraints don't enforce the original window width.
  if (fullCounterContentView == nil) {
    fullCounterContentView = [counterWindow contentView];
  }
  if (compactCounterContentView == nil) {
    compactCounterContentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, compactWidth, compactHeight)];
    [compactCounterContentView setWantsLayer:YES];
    if (isDarkTheme) {
      compactCounterContentView.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:0.0 alpha:0.9] CGColor];
    } else {
      compactCounterContentView.layer.backgroundColor = [[NSColor colorWithCalibratedWhite:1.0 alpha:0.9] CGColor];
    }
    [self buildCompactMetricsViewWithWidth:compactWidth height:compactHeight];
  }
  [compactCounterContentView setFrame:NSMakeRect(0, 0, compactWidth, compactHeight)];
  [counterWindow setContentView:compactCounterContentView];
  
  [counterWindow setStyleMask:NSWindowStyleMaskBorderless];
  [counterWindow setOpaque:NO];
  [counterWindow setBackgroundColor:[NSColor clearColor]];
  [counterWindow setAlphaValue:0.9];
  NSRect frame = lastExpandedWindowFrame;
  CGFloat rightEdge = NSMaxX(lastExpandedWindowFrame);
  frame.size.width = compactWidth;
  frame.origin.x = rightEdge - compactWidth;
  
  [compactCounterContentView setAlphaValue:0.0];
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
    context.duration = 0.22;
    context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [[counterWindow animator] setFrame:frame display:YES];
    [[compactCounterContentView animator] setAlphaValue:1.0];
  } completionHandler:nil];
  
  [self showNumbers];
}

- (void)expandCounterWindow {
  if (!isOn || counterWindow == nil || ![counterWindow isVisible]) return;
  
  BOOL wasCompact = isCompactMode;
  isCompactMode = NO;
  
  if (onShowAdvancedButton != nil) {
    [onShowAdvancedButton setHidden:NO];
    [onShowAdvancedButton setAlphaValue:0.0];
  }
  if (cutResultsButton != nil) {
    [cutResultsButton setHidden:NO];
    [cutResultsButton setAlphaValue:0.0];
  }
  if (fullCounterContentView != nil && [counterWindow contentView] != fullCounterContentView) {
    [counterWindow setContentView:fullCounterContentView];
    [fullCounterContentView setAlphaValue:0.0];
  }
  if (hasOriginalCounterWindowStyleMask) {
    [counterWindow setStyleMask:originalCounterWindowStyleMask];
  }
  [counterWindow setOpaque:YES];
  [counterWindow setAlphaValue:1.0];
  if (originalCounterWindowBackgroundColor != nil) {
    [counterWindow setBackgroundColor:originalCounterWindowBackgroundColor];
  }
  
  if (wasCompact) {
    CGFloat fullWidth = 260.0;
    [counterWindow setContentMinSize:NSMakeSize(fullWidth, 200.0)];
    NSRect targetFrame;
    if (hasLastExpandedWindowFrame) {
      targetFrame = lastExpandedWindowFrame;
    } else {
      NSRect frame = [counterWindow frame];
      frame.size.width = fullWidth;
      targetFrame = frame;
    }
    
    // Restore whichever state user had before compact mode kicked in.
    isWindowExpanded = wasWindowExpandedBeforeCompact;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
      context.duration = 0.24;
      context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
      [[counterWindow animator] setFrame:targetFrame display:YES];
      if (fullCounterContentView != nil) {
        [[fullCounterContentView animator] setAlphaValue:1.0];
      }
      if (onShowAdvancedButton != nil) {
        [[onShowAdvancedButton animator] setAlphaValue:1.0];
      }
      if (cutResultsButton != nil) {
        [[cutResultsButton animator] setAlphaValue:1.0];
      }
    } completionHandler:nil];
  } else {
    if (fullCounterContentView != nil) {
      [fullCounterContentView setAlphaValue:1.0];
    }
    if (onShowAdvancedButton != nil) {
      [onShowAdvancedButton setAlphaValue:1.0];
    }
    if (cutResultsButton != nil) {
      [cutResultsButton setAlphaValue:1.0];
    }
  }
  
  // Keep arrow icon synchronized with restored expanded/collapsed state.
  [self updateAdvancedButtonImage];
  [self animateAdvancedLabelsVisibility];
  [self showNumbers];
}

- (void)buildCompactMetricsViewWithWidth:(CGFloat)compactWidth height:(CGFloat)compactHeight {
  for (NSView *subview in [compactCounterContentView subviews]) {
    [subview removeFromSuperview];
  }
  
  compactMetricValueLabels = [NSMutableArray array];
  NSArray *tooltips = @[
    @"Characters",
    @"Characters without spaces",
    @"Letters",
    @"Words",
    @"Unique words",
    @"Sentences",
    @"Lines",
    @"Spaces",
    @"Reading time (seconds)",
    @"Syllables"
  ];
  
  NSStackView *stackView = [[NSStackView alloc] initWithFrame:NSMakeRect(0, 0, compactWidth, compactHeight)];
  [stackView setOrientation:NSUserInterfaceLayoutOrientationVertical];
  [stackView setDistribution:NSStackViewDistributionFillEqually];
  [stackView setAlignment:NSLayoutAttributeCenterX];
  [stackView setSpacing:10.0];
  [stackView setTranslatesAutoresizingMaskIntoConstraints:NO];
  
  for (NSString *tooltip in tooltips) {
    NSTextField *valueLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [valueLabel setBezeled:NO];
    [valueLabel setDrawsBackground:NO];
    [valueLabel setEditable:NO];
    [valueLabel setSelectable:NO];
    [valueLabel setAlignment:NSTextAlignmentCenter];
    [valueLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
    [valueLabel setFont:[NSFont systemFontOfSize:14.0]];
    [valueLabel setStringValue:@"0"];
    [valueLabel setTextColor:isDarkTheme ? [NSColor whiteColor] : [NSColor blackColor]];
    [valueLabel setToolTip:tooltip];
    [compactMetricValueLabels addObject:valueLabel];
    [stackView addArrangedSubview:valueLabel];
  }
  
  [compactCounterContentView addSubview:stackView];
  [NSLayoutConstraint activateConstraints:@[
    [stackView.leadingAnchor constraintEqualToAnchor:compactCounterContentView.leadingAnchor],
    [stackView.trailingAnchor constraintEqualToAnchor:compactCounterContentView.trailingAnchor],
    [stackView.topAnchor constraintEqualToAnchor:compactCounterContentView.topAnchor constant:2.0],
    [stackView.bottomAnchor constraintEqualToAnchor:compactCounterContentView.bottomAnchor constant:-2.0]
  ]];
}

- (void)updateCompactMetricValuesWithCharacters:(NSUInteger)characters
                       charactersWithoutSpaces:(NSUInteger)charactersWithoutSpaces
                                        letters:(NSUInteger)letters
                                          words:(NSUInteger)words
                                    uniqueWords:(NSUInteger)uniqueWords
                                      sentences:(NSUInteger)sentences
                                          lines:(NSUInteger)lines
                                         spaces:(NSUInteger)spaces
                                 readingSeconds:(NSUInteger)readingSeconds
                                       syllables:(NSUInteger)syllables
                           hasReadabilityValues:(BOOL)hasReadabilityValues {
  if (compactMetricValueLabels == nil || [compactMetricValueLabels count] < 10) {
    return;
  }
  
  NSArray *values = @[
    [NSString stringWithFormat:@"%lu", (unsigned long)characters],
    [NSString stringWithFormat:@"%lu", (unsigned long)charactersWithoutSpaces],
    [NSString stringWithFormat:@"%lu", (unsigned long)letters],
    [NSString stringWithFormat:@"%lu", (unsigned long)words],
    [NSString stringWithFormat:@"%lu", (unsigned long)uniqueWords],
    [NSString stringWithFormat:@"%lu", (unsigned long)sentences],
    [NSString stringWithFormat:@"%lu", (unsigned long)lines],
    [NSString stringWithFormat:@"%lu", (unsigned long)spaces],
    hasReadabilityValues ? [NSString stringWithFormat:@"%lu", (unsigned long)readingSeconds] : @"-",
    hasReadabilityValues ? [NSString stringWithFormat:@"%lu", (unsigned long)syllables] : @"-"
  ];
  
  for (NSUInteger i = 0; i < [compactMetricValueLabels count] && i < [values count]; i++) {
    NSTextField *label = compactMetricValueLabels[i];
    [label setStringValue:values[i]];
  }
}


@end
