//
//  MainWindowController.h
//  Defaulter
//
//  Created by Owen Yamauchi on 4/18/08.
//  Copyright 2008 Owen Yamauchi. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MainWindowController : NSWindowController {
  IBOutlet NSPopUpButton *browserMenu;
  IBOutlet NSPopUpButton *emailMenu;
  IBOutlet NSPopUpButton *ftpMenu;
  IBOutlet NSPopUpButton *rssMenu;
  
  NSMutableDictionary *appLists;
}

- (NSPopUpButton *)menuForScheme:(NSString *)scheme;
- (void)setupPopupMenu:(NSPopUpButton *)menuButton withScheme:(NSString *)scheme;
- (NSArray *)bundlesForURLScheme:(NSString *)scheme;
- (NSBundle *)defaultBundleForURLScheme:(NSString *)scheme;

- (IBAction)setDefaults:(id)sender;

- (void)windowWillClose:(NSNotification *)ignored;

@end

@interface NSBundle (DisplayName)

- (NSString *)displayName;

@end
