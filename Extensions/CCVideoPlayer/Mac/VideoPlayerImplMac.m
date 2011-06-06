/*
 * CCVideoPlayer
 *
 * cocos2d-extensions
 * https://github.com/cocos2d/cocos2d-iphone-extensions
 *
 * Copyright (c) 2010-2011 Stepan Generalov
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import "VideoPlayerImplMac.h"
#import "cocos2d.h"
#import "MyMovieView.h"

#if __MAC_OS_X_VERSION_MAX_ALLOWED

@interface VideoPlayerImplMac  (Private) <CCKeyboardEventDelegate>

-(void)movieFinishedCallback:(NSNotification*)aNotification;
-(BOOL) ccKeyDown:(NSEvent*)event;

@end



@implementation VideoPlayerImplMac

NSString *const kVideoTitle		= @"CustomVideoView";

@synthesize videoViewController;
@synthesize retainedView;


#pragma mark Interface 

- (void)playMovieAtURL:(NSURL*)theURL
{
	NSView *targetView = [[CCDirector sharedDirector] openGLView];
	[self playMovieAtURL: theURL attachedInView: targetView];
}


// start playing movie in new view, replacing and retaining targetView
- (void)playMovieAtURL:(NSURL*)theURL attachedInView: (NSView *) targetView
{		
	// Setup Movie	
	QTMovie* movie = [[QTMovie alloc] initWithURL:theURL error:nil];	
	if ( ! movie )
		return;
	
	// Prepare other systems for Playback
	[delegate movieStartsPlaying];
	
	//Setup Movie	
	[movie setAttribute:[NSNumber numberWithBool: YES] forKey:QTMovieOpenAsyncRequiredAttribute ];
	[movie setAttribute:[NSNumber numberWithBool: NO] forKey:QTMovieEditableAttribute];
	[movie setAttribute:[NSNumber numberWithBool: NO] forKey:QTMovieLoopsAttribute];
	
	//Get Movie View
	self.videoViewController =
		[[[NSViewController alloc] initWithNibName:kVideoTitle bundle:nil] autorelease];
	[(MyMovieView*)[self.videoViewController view] setMovie:movie];
	[(MyMovieView*)[self.videoViewController view] setPreservesAspectRatio:YES];
	[(MyMovieView*)[self.videoViewController view] setControllerVisible:NO];
		
	// Integrate Movie's View by Replacing the targetView from it's superview
	self.retainedView = targetView;
	NSView *windowContentView = [targetView superview];
	//[targetView removeFromSuperview];
	[windowContentView addSubview:[self.videoViewController view]];
	[[self.videoViewController view] setFrame: [windowContentView bounds]];
	
	// Start handling events on movie view
	[[CCEventDispatcher sharedDispatcher] addKeyboardDelegate: (MyMovieView *)[self.videoViewController view] 
													 priority: NSIntegerMin ];
		
	// Register for end notification
	[[NSNotificationCenter defaultCenter] addObserver: self 
											 selector:@selector(movieFinishedCallback:) 
												 name: QTMovieDidEndNotification 
											   object: movie];
	[movie play];
	[movie release];	
}

- (void) cancelPlaying
{	
	[self movieFinishedCallback: nil];
}

- (void)setDelegate: (id<VideoPlayerDelegate>) aDelegate;
{
	delegate = aDelegate;
}

#pragma mark Other Stuff

-(void)movieFinishedCallback:(NSNotification*)aNotification
{		
	// Stop receiving notifications
	QTMovie *movie = (QTMovie *)[aNotification object];	
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: QTMovieDidEndNotification
                                                  object: movie ];
	
	// Stop Playing
	[movie stop];
	[(MyMovieView*)[self.videoViewController view] setMovie:nil];
    
	// switch from movie to retained view
	NSView *windowContentView = [[self.videoViewController view] superview];
	[[self.videoViewController view] removeFromSuperview];
	//[windowContentView addSubview: self.retainedView];
	[[self retainedView] setFrame:[windowContentView bounds]];
	
	// Stop handling events on movie view
	[[CCEventDispatcher sharedDispatcher] removeKeyboardDelegate: self];
	[[windowContentView window] makeFirstResponder: self.retainedView ];
	
	
	
	// release not needed views
	self.retainedView = nil;
	self.videoViewController = nil;
	
	[delegate moviePlaybackFinished];
}

@end

#endif