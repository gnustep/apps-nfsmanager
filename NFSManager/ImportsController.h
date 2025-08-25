/*
 * File: Sources/NFSManager/ImportsController.h
 * Purpose: Controller to load and save fstab-style entries for Linux/macOS.
 * Notes: No Objective‑C 2.0 features; manual retain/release in implementation.
 * Style: GNU Coding Standards — two-space indent, brace placement, spaces
 *        before function-like parentheses, block comments.
 */

#ifndef IMPORTS_CONTROLLER_H
#define IMPORTS_CONTROLLER_H

#import <Foundation/NSObject.h>
#import <AppKit/AppKit.h>   /* NSTableView, NSWindow, IBAction */

@class NSTableView;
@class NSWindow;
@class NSMutableArray;
@class NSMutableDictionary;
@class NSError;

@interface ImportsController : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
  /* Outlets */
  IBOutlet NSTableView *table;
  IBOutlet NSWindow *expertOptionsWindow;
  IBOutlet NSWindow *importFromServerWindow;

  /* Model */
  NSMutableArray *nfsImportsConfig;   /* array of NSDictionary entries */
}

/* Loading and saving */
- (NSMutableArray *) loadFstabIntoDictionary;
- (BOOL) saveToSystemFstabWithError: (NSError **)error;

/* Table setup */
- (void) setupTableColumns;
- (void) removeTableColumns;
- (void) refreshData;

/* Entry builder */
- (NSMutableDictionary *) buildEntrySpec: (NSString *)spec
                                    file: (NSString *)file
                                 vfsType: (NSString *)vfsType
                                mountOps: (NSString *)mountOps
                                    type: (NSString *)type
                                    freq: (NSString *)freq
                                  passno: (NSString *)passno;

/* Actions */
- (IBAction) add: (id)sender;
- (IBAction) remove: (id)sender;
- (IBAction) select: (id)sender;
- (IBAction) selectMountPermissions: (id)sender;
- (IBAction) selectMountThread: (id)sender;
- (IBAction) selectSetuidAction: (id)sender;
- (IBAction) selectRetryMethod: (id)sender;

/* Expert options */
- (IBAction) setExpertOptions: (id)sender;
- (IBAction) cancelExpertOptions: (id)sender;

/* Import */
- (IBAction) cancelImport: (id)sender;
- (IBAction) okImport: (id)sender;

@end

#endif /* IMPORTS_CONTROLLER_H */
