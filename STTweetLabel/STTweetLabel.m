//
//  STTweetLabel.m
//  STTweetLabel
//
//  Created by Sebastien Thiebaud on 12/14/12.
//  Copyright (c) 2012 Sebastien Thiebaud. All rights reserved.
//

#import "STTweetLabel.h"

@implementation STTweetLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Set the basic properties
        [self setBackgroundColor:[UIColor clearColor]];
        [self setUserInteractionEnabled:YES];
        [self setNumberOfLines:0];
        [self setLineBreakMode:NSLineBreakByWordWrapping]; // why do we even set a line break mode?
        
        // Alloc and init the arrays which stock the touchable words and their location
        touchLocations = [[NSMutableArray alloc] init];
        touchWords = [[NSMutableArray alloc] init];
        substringsFromString = [[NSMutableArray alloc] init];
        widthOfSubstringsFromString = [[NSMutableArray alloc] init];
        
        // Init touchable words colors
        _colorHashtag = [UIColor colorWithWhite:170.0/255.0 alpha:1.0];
        _colorLink = [UIColor colorWithRed:129.0/255.0 green:171.0/255.0 blue:193.0/255.0 alpha:1.0];
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect
{
    if (_fontHashtag == nil)
    {
        _fontHashtag = self.font;
    }
    
    if (_fontLink == nil)
    {
        _fontLink = self.font;
    }
    
    [touchLocations removeAllObjects];
    [touchWords removeAllObjects];
    [substringsFromString removeAllObjects];
    [widthOfSubstringsFromString removeAllObjects];
    
    // Separate words by spaces and lines
    NSArray *words = [[self htmlToText:self.text] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // Init a point which is the reference to draw words
    CGPoint drawPoint = CGPointMake(0.0, 0.0);
    // Calculate the size of a space with the actual font
    CGSize sizeSpace = [@" " sizeWithFont:self.font constrainedToSize:rect.size lineBreakMode:self.lineBreakMode];

    [self.textColor set];

    // Regex to catch @mention #hashtag and link http(s)://
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"((@|#)([A-Z0-9a-z(é|ë|ê|è|à|â|ä|á|ù|ü|û|ú|ì|ï|î|í)_]+))|(http(s)?://([A-Z0-9a-z._-]*(/)?)*)" options:NSRegularExpressionCaseInsensitive error:&error];

    // Regex to catch newline d
    NSRegularExpression *regexNewLine = [NSRegularExpression regularExpressionWithPattern:@">newLine" options:NSRegularExpressionCaseInsensitive error:&error];
    
    for (NSString *word in words)
    {
        CGSize sizeWord = [word sizeWithFont:self.font];
        
        // Check if it's even possible to put the word in a single line
        if (sizeWord.width > rect.size.width) {
            [self workWithString:word atPoint:drawPoint];
            while ([[widthOfSubstringsFromString lastObject] CGSizeValue].width > rect.size.width) {
                CGPoint pseudoNewLineDrawPoint = CGPointMake(0.0, drawPoint.y + sizeWord.height);
                NSString *string = [substringsFromString lastObject];
                [substringsFromString removeLastObject];
                [widthOfSubstringsFromString removeLastObject];
                [self workWithString:string atPoint:pseudoNewLineDrawPoint];
            }
            
            //NSLog(@"Needed amount of lines: %i",[widthOfSubstringsFromString count]);
            //NSLog(@"Lines: %@",substringsFromString);
            //what we have:
            // substringsFromString:
            // - 1.object: text for first line
            // - 2.object: text for lines between
            // - 3.object: text for last line
            
            // Should be something like that
            /*            NSTextCheckingResult *match = [regex firstMatchInString:word options:0 range:NSMakeRange(0, [word length])];
             NSTextCheckingResult *match2 = [regex firstMatchInString:word options:0 range:NSMakeRange(0, [[substringsFromString objectAtIndex:0] length])];
             NSTextCheckingResult *match3 = [regex firstMatchInString:word options:0 range:NSMakeRange(0, [[substringsFromString lastObject] length])];
             
             // Dissolve the word (for example a hashtag: #youtube!, we want only #youtube)
             NSString *preCharacters = [word substringToIndex:match.range.location];
             NSString *wordCharacters = [word substringWithRange:match.range];
             NSString *postCharacters = [word substringFromIndex:match.range.location + match.range.length];
             
             NSString *preCharacters2 = [[substringsFromString objectAtIndex:0] substringToIndex:match2.range.location];
             NSString *wordCharacters2 = [[substringsFromString objectAtIndex:0] substringWithRange:match2.range];
             NSString *postCharacters2 = [[substringsFromString lastObject] substringFromIndex:match3.range.location + match3.range.length];
             
             
             // Draw the prefix of the word (if it has a prefix)
             if (![preCharacters2 isEqualToString:@""])
             {
             [self.textColor set];
             CGSize sizePreCharacters = [preCharacters2 sizeWithFont:self.font];
             [preCharacters2 drawAtPoint:drawPoint withFont:self.font];
             drawPoint = CGPointMake(drawPoint.x + sizePreCharacters.width, drawPoint.y);
             }
             
             // Draw the touchable word
             if (![wordCharacters2 isEqualToString:@""])
             {
             // Set the color for mention/hashtag OR weblink
             if ([wordCharacters2 hasPrefix:@"#"] || [wordCharacters2 hasPrefix:@"@"])
             {
             [_colorHashtag set];
             }
             else if ([wordCharacters2 hasPrefix:@"http"])
             {
             [_colorLink set];
             }
             
             CGSize sizeWordCharacters = [wordCharacters2 sizeWithFont:self.font];
             [wordCharacters2 drawAtPoint:drawPoint withFont:self.font];
             
             // Stock the touchable zone
             [touchWords addObject:wordCharacters];
             [touchLocations addObject:[NSValue valueWithCGRect:CGRectMake(drawPoint.x, drawPoint.y, sizeWordCharacters.width, sizeWordCharacters.height)]];
             
             drawPoint = CGPointMake(0.0, drawPoint.y + sizeWordCharacters.height);
             
             
             NSMutableArray *strings = [NSMutableArray arrayWithArray:substringsFromString];
             [strings removeLastObject];
             [strings removeObjectAtIndex:0];
             
             for(int x=0;x<[strings count];x++) {
             CGSize sizeWordCharacters = [[strings objectAtIndex:x] sizeWithFont:self.font];
             [[strings objectAtIndex:x] drawAtPoint:drawPoint withFont:self.font];
             
             [touchWords addObject:wordCharacters];
             [touchLocations addObject:[NSValue valueWithCGRect:CGRectMake(drawPoint.x, drawPoint.y, sizeWordCharacters.width, sizeWordCharacters.height)]];
             
             drawPoint = CGPointMake(0.0, drawPoint.y + sizeWordCharacters.height);
             }
             
             [substringsFromString removeAllObjects]; //important!
             [widthOfSubstringsFromString removeAllObjects]; //important!
             
             CGSize sizeWordCharacters3 = [[substringsFromString lastObject] sizeWithFont:self.font];
             [[substringsFromString lastObject] drawAtPoint:drawPoint withFont:self.font];
             
             // Stock the touchable zone
             [touchWords addObject:wordCharacters];
             [touchLocations addObject:[NSValue valueWithCGRect:CGRectMake(drawPoint.x, drawPoint.y, sizeWordCharacters3.width, sizeWordCharacters3.height)]];
             
             drawPoint = CGPointMake(drawPoint.x + sizeWordCharacters3.width, drawPoint.y);
             }
             if (![postCharacters2 isEqualToString:@""])
             {
             [self.textColor set];
             
             NSTextCheckingResult *matchNewLine = [regexNewLine firstMatchInString:postCharacters2 options:0 range:NSMakeRange(0, [postCharacters2 length])];
             
             // If a newline is match
             if (matchNewLine)
             {
             [[postCharacters substringToIndex:matchNewLine.range.location] drawAtPoint:drawPoint withFont:self.font];
             drawPoint = CGPointMake(0.0, drawPoint.y + sizeWord.height);
             [[postCharacters substringFromIndex:matchNewLine.range.location + matchNewLine.range.length] drawAtPoint:drawPoint withFont:self.font];
             drawPoint = CGPointMake(drawPoint.x + [[postCharacters substringFromIndex:matchNewLine.range.location + matchNewLine.range.length] sizeWithFont:self.font].width, drawPoint.y);
             }
             else
             {
             CGSize sizePostCharacters = [postCharacters2 sizeWithFont:self.font];
             [postCharacters2 drawAtPoint:drawPoint withFont:self.font];
             drawPoint = CGPointMake(drawPoint.x + sizePostCharacters.width, drawPoint.y);
             }
             }
             
             drawPoint = CGPointMake(drawPoint.x + sizeSpace.width, drawPoint.y);*/

            
        } else {
        
        // Test if the new word must be in a new line
        if (drawPoint.x + sizeWord.width > rect.size.width)
        {
            drawPoint = CGPointMake(0.0, drawPoint.y + sizeWord.height);
        }
                
        NSTextCheckingResult *match = [regex firstMatchInString:word options:0 range:NSMakeRange(0, [word length])];
        
        // Dissolve the word (for example a hashtag: #youtube!, we want only #youtube)
        NSString *preCharacters = [word substringToIndex:match.range.location];
        NSString *wordCharacters = [word substringWithRange:match.range];
        NSString *postCharacters = [word substringFromIndex:match.range.location + match.range.length];
        
        // Draw the prefix of the word (if it has a prefix)
        if (![preCharacters isEqualToString:@""])
        {
            [self.textColor set];
            CGSize sizePreCharacters = [preCharacters sizeWithFont:self.font];
            [preCharacters drawAtPoint:drawPoint withFont:self.font];
            drawPoint = CGPointMake(drawPoint.x + sizePreCharacters.width, drawPoint.y);
        }
        
        // Draw the touchable word
        if (![wordCharacters isEqualToString:@""])
        {
            // Set the color for mention/hashtag OR weblink
            if ([wordCharacters hasPrefix:@"#"] || [wordCharacters hasPrefix:@"@"])
            {
                [_colorHashtag set];
            }
            else if ([wordCharacters hasPrefix:@"http"])
            {
                [_colorLink set];
            }
            
            CGSize sizeWordCharacters = [wordCharacters sizeWithFont:self.font];
            [wordCharacters drawAtPoint:drawPoint withFont:self.font];
            
            // Stock the touchable zone
            [touchWords addObject:wordCharacters];
            [touchLocations addObject:[NSValue valueWithCGRect:CGRectMake(drawPoint.x, drawPoint.y, sizeWordCharacters.width, sizeWordCharacters.height)]];
            
            drawPoint = CGPointMake(drawPoint.x + sizeWordCharacters.width, drawPoint.y);
        }
        
        // Draw the suffix of the word (if it has a suffix) else the word is not touchable
        if (![postCharacters isEqualToString:@""])
        {
            [self.textColor set];
            
            NSTextCheckingResult *matchNewLine = [regexNewLine firstMatchInString:postCharacters options:0 range:NSMakeRange(0, [postCharacters length])];

            // If a newline is match
            if (matchNewLine)
            {
                [[postCharacters substringToIndex:matchNewLine.range.location] drawAtPoint:drawPoint withFont:self.font];
                drawPoint = CGPointMake(0.0, drawPoint.y + sizeWord.height);
                [[postCharacters substringFromIndex:matchNewLine.range.location + matchNewLine.range.length] drawAtPoint:drawPoint withFont:self.font];
                drawPoint = CGPointMake(drawPoint.x + [[postCharacters substringFromIndex:matchNewLine.range.location + matchNewLine.range.length] sizeWithFont:self.font].width, drawPoint.y);
            }
            else
            {
                CGSize sizePostCharacters = [postCharacters sizeWithFont:self.font];
                [postCharacters drawAtPoint:drawPoint withFont:self.font];
                drawPoint = CGPointMake(drawPoint.x + sizePostCharacters.width, drawPoint.y);
            }
        }
        
        drawPoint = CGPointMake(drawPoint.x + sizeSpace.width, drawPoint.y);
    }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = event.allTouches.anyObject;
    CGPoint touchPoint = [touch locationInView:self];
    
    [touchLocations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
    {
        CGRect touchZone = [obj CGRectValue];
        
        if (CGRectContainsPoint(touchZone, touchPoint))
        {
            //A touchable word is found
            
            NSString *url = [touchWords objectAtIndex:idx];
            
            if ([[touchWords objectAtIndex:idx] hasPrefix:@"@"])
            {
                //Twitter account clicked
                if ([_delegate respondsToSelector:@selector(twitterAccountClicked:)]) {
                    [_delegate twitterAccountClicked:url];
                }
            }
            else if ([[touchWords objectAtIndex:idx] hasPrefix:@"#"])
            {
                //Twitter hashtag clicked
                if ([_delegate respondsToSelector:@selector(twitterHashtagClicked:)]) {
                    [_delegate twitterHashtagClicked:url];
                }
            }
            else if ([[touchWords objectAtIndex:idx] hasPrefix:@"http"])
            {
                
                //Twitter hashtag clicked
                if ([_delegate respondsToSelector:@selector(websiteClicked:)]) {
                    [_delegate websiteClicked:url];
                }
            }
        }
    }];
}

- (NSString *)htmlToText:(NSString *)htmlString
{
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&amp;"  withString:@"&"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&lt;"  withString:@"<"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&gt;"  withString:@">"];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&quot;" withString:@""""];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"&#039;"  withString:@"'"];
    
    // Newline character (if you have a better idea...)
    // first CR LF :)
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"\r\n"  withString:@" >newLine"];
    // LF
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"\n"  withString:@" >newLine"];
    // CR
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"\r"  withString:@" >newLine"];
   
    // Extras
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"<3" withString:@"♥"];
    
    return htmlString;
}

// Split it into two strings (string 1: first line, string 2: the other line[s])
- (void)workWithString:(NSString *)word atPoint:(CGPoint)drawPoint {
    NSString *substring;
    for (int i=1; i<[word length]; i++) {
        substring = [word substringToIndex:[word length] - i];
        CGSize sizeSubstring = [substring sizeWithFont:self.font];
        if (drawPoint.x + sizeSubstring.width <= self.frame.size.width) {            
            NSString *substring2 = [word substringFromIndex:[substring length]];
            CGSize sizeSubstring2 = [substring2 sizeWithFont:self.font];
            [substringsFromString addObject:substring];
            [widthOfSubstringsFromString addObject:[NSValue valueWithCGSize:sizeSubstring]];
            [substringsFromString addObject:substring2];
            [widthOfSubstringsFromString addObject:[NSValue valueWithCGSize:sizeSubstring2]];           
            break;
        }
    }
}

@end
