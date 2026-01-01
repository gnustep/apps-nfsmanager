//
//  ExportsController.m
//  NFSManager
//
//  Created by Gregory John Casamento on 9/2/23.
//

#import <AppKit/NSApplication.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSTableColumn.h>

#import "ExportsController.h"

@interface ExportsController ()
@property (strong) NSMutableArray<NSMutableDictionary *> *exportEntries; // { path, options }
@end

@implementation ExportsController

- (instancetype)init
{
  self = [super init];
  if (self)
  {
    _exportEntries = [[NSMutableArray alloc] init];
    [self loadExportsFromDisk];
  }
  return self;
}

- (void)awakeFromNib
{
  [self.table reloadData];
}

#pragma mark - Helpers

- (void)loadExportsFromDisk
{
  NSString *filePath = @"/etc/exports";
  NSError *error = nil;
  NSString *fileContents = [NSString stringWithContentsOfFile:filePath
                             encoding:NSUTF8StringEncoding
                              error:&error];
  if (fileContents == nil)
  {
    if (error)
    {
      NSLog(@"Unable to read /etc/exports: %@", [error localizedDescription]);
    }
    return;
  }
  [self.exportEntries removeAllObjects];

  NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
  for (NSString *line in lines)
  {
    NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmed length] == 0 || [trimmed hasPrefix:@"#"])
    {
      continue;
    }

    NSArray *parts = [trimmed componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSMutableArray *filtered = [[parts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]] mutableCopy];
    if ([filtered count] == 0)
    {
      continue;
    }

    NSString *path = filtered[0];
    [filtered removeObjectAtIndex:0];
    NSString *options = ([filtered count] > 0)
      ? [filtered componentsJoinedByString:@" "]
      : @"";

    NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                     path, @"path",
                     options, @"options",
                     nil];
    [self.exportEntries addObject: entry];
  }
}

- (void)refreshTable
{
  [self.table reloadData];
}

- (NSMutableDictionary *)entryForRow:(NSInteger)row
{
  if (row < 0 || row >= (NSInteger)[self.exportEntries count])
  {
    return nil;
  }
  return [self.exportEntries objectAtIndex: (NSUInteger)row];
}

- (void)addOrUpdateExportAtPath:(NSString *)path withOptionToken:(NSString *)token
{
  if ([path length] == 0)
  {
    return;
  }

  NSUInteger idx = [self.exportEntries indexOfObjectPassingTest:^BOOL(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
    return [[obj objectForKey:@"path"] isEqualToString:path];
  }];

  NSMutableDictionary *entry = nil;
  if (idx != NSNotFound)
  {
    entry = [self.exportEntries objectAtIndex: idx];
  }
  else
  {
    entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
         path, @"path",
         @"", @"options",
         nil];
    [self.exportEntries addObject: entry];
  }

  NSString *existing = [entry objectForKey:@"options"] ?: @"";
  NSMutableArray *tokens = [[existing componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
  tokens = [[tokens filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]] mutableCopy];

  if (token != nil && [token length] > 0 && [tokens containsObject: token] == NO)
  {
    [tokens addObject: token];
  }

  NSString *joined = ([tokens count] > 0) ? [tokens componentsJoinedByString:@" "] : @"";
  [entry setObject: joined forKey: @"options"];
  [self refreshTable];
}

- (void)removeOption:(NSString *)token fromRow:(NSInteger)row
{
  NSMutableDictionary *entry = [self entryForRow: row];
  if (entry == nil)
  {
    return;
  }

  NSString *existing = [entry objectForKey:@"options"] ?: @"";
  NSMutableArray *tokens = [[existing componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
  tokens = [[tokens filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]] mutableCopy];
  [tokens removeObject: token];
  NSString *joined = ([tokens count] > 0) ? [tokens componentsJoinedByString:@" "] : @"";
  [entry setObject: joined forKey: @"options"];
  [self refreshTable];
}

- (void)removeRow:(NSInteger)row
{
  if (row < 0 || row >= (NSInteger)[self.exportEntries count])
  {
    return;
  }
  [self.exportEntries removeObjectAtIndex: (NSUInteger)row];
  [self refreshTable];
}

- (IBAction)revert:(id)sender
{
  [self loadExportsFromDisk];
  [self refreshTable];
}

- (IBAction)ok:(id)sender
{
  // Persisting to /etc/exports typically requires elevated privileges; we only refresh UI here.
  [self refreshTable];
  [self.window performClose: self];
}

- (IBAction)allowUnknownUsers:(id)sender
{
  NSInteger state = [self.allowUnknownUsers state];
  BOOL allow = (state != 0); // compatible with AppKit and GNUstep state values
  [self.unknownUsersPopup setEnabled: allow];
}

- (IBAction)addRootAccess:(id)sender
{
  NSInteger row = [self.table selectedRow];
  if (row < 0)
  {
    return;
  }
  [self addOrUpdateExportAtPath:[[self entryForRow: row] objectForKey:@"path"]
          withOptionToken:@"no_root_squash"];
}

- (IBAction)removeRootAccess:(id)sender
{
  NSInteger row = [self.table selectedRow];
  [self removeOption:@"no_root_squash" fromRow: row];
}

- (IBAction)addReadWrite:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.allowsMultipleSelection = NO;
  NSModalResponse response = [panel runModal];
  if (response == NSModalResponseOK)
  {
    NSString *path = panel.URL.path;
    [self addOrUpdateExportAtPath: path withOptionToken:@"rw"];
  }
}

- (IBAction)removeReadWrite:(id)sender
{
  NSInteger row = [self.table selectedRow];
  [self removeOption:@"rw" fromRow: row];
}

- (IBAction)removeReadOnly:(id)sender
{
  NSInteger row = [self.table selectedRow];
  [self removeOption:@"ro" fromRow: row];
}

- (IBAction)addReadOnly:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.allowsMultipleSelection = NO;
  NSModalResponse response = [panel runModal];
  if (response == NSModalResponseOK)
  {
    NSString *path = panel.URL.path;
    [self addOrUpdateExportAtPath: path withOptionToken:@"ro"];
  }
}

// Table Delegate

// Table Data Source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
  return (NSInteger)[self.exportEntries count];
}

- (id)tableView: (NSTableView *)tableView
      objectValueForTableColumn: (NSTableColumn *)tableColumn
	    row: (NSInteger)row
{
  NSDictionary *entry = [self entryForRow: row];
  if (entry == nil)
  {
    return nil;
  }

  NSString *ident = [tableColumn identifier];
  if ([ident isEqualToString:@"path"])
  {
    return [entry objectForKey:@"path"];
  }
  if ([ident isEqualToString:@"options"])
  {
    return [entry objectForKey:@"options"];
  }

  // Fallback: show the combined line if the identifier is unknown.
  NSString *path = [entry objectForKey:@"path"] ?: @"";
  NSString *options = [entry objectForKey:@"options"] ?: @"";
  if ([options length] > 0)
  {
    return [NSString stringWithFormat:@"%@ %@", path, options];
  }
  return path;
}

@end
