//
//  ImportsController.m
//  NFSManager
//
//  Created by Gregory John Casamento on 9/2/23.
//

#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>

#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSPanel.h>

#import "ImportsController.h"

@implementation ImportsController

static NSString *NFSFstabPath = @"/etc/fstab";

- (instancetype) init
{
    if ((self = [super init]) != nil)
    {
        self.columnsArray = [NSArray arrayWithObjects: @"fs_spec",
                                @"fs_file",@"fs_vfstype",
                                @"fs_mntops",@"fs_type",
                                @"fs_freq", @"fs_passno", nil];
        self.columnNames = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Remote Directory", @"fs_spec",
                        @"Local Directory", @"fs_file",
                        @"File System Type", @"fs_vfstype",
                        @"Mount Options", @"fs_mntops",
                        @"Version", @"fs_type",
                        @"Frequency", @"fs_freq",
                        @"Pass", @"fs_passno", nil];
        self.displayEntries = [[NSMutableArray alloc] init];
        self.nfsImportsConfig = [self loadFstabIntoDictionary];
    }
    return self;
}

- (void) removeTableColumns
{
    while ([[self.table tableColumns] count] > 0)
    {
        [self.table removeTableColumn:
         [[self.table tableColumns] objectAtIndex:0]];
    }
}

- (void) setupTableColumns
{
    NSEnumerator *en = [_columnsArray objectEnumerator];
    NSString *ident = nil;
    
    while(ident = [en nextObject])
    {
        NSTableColumn *tc = [[NSTableColumn alloc] initWithIdentifier: ident];
        NSString *colName = [_columnNames objectForKey: ident];
        
        [tc setTitle: colName];
        [self.table addTableColumn: tc];
    }
}

- (void) awakeFromNib
{
    [self removeTableColumns];
    [self setupTableColumns];
}

// Load
- (NSMutableArray *) loadFstabIntoDictionary
{
    NSMutableArray *fstabArray = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSString *fileContents = [[NSString alloc] initWithContentsOfFile:NFSFstabPath encoding:NSUTF8StringEncoding error:&error];
    if (fileContents == nil)
    {
        if (error != nil)
        {
            NSLog(@"Error reading fstab: %@", [error localizedDescription]);
        }
        return fstabArray;
    }

    NSArray *lines = [fileContents componentsSeparatedByString:@"\n"];
    unsigned int i = 0;
    
    for (i = 0; i < [lines count]; i++)
    {
        NSString *line = [lines objectAtIndex:i];
        
        // Ignore comments and empty lines
        if ([line length] == 0 || [line hasPrefix:@"#"]) {
            continue;
        }
        
        NSArray *components = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        
        if ([components count] < 4)
        {
            continue;
        }

        NSString *spec = [components objectAtIndex: 0];
        NSString *file = [components objectAtIndex: 1];
        NSString *vfsType = [components objectAtIndex: 2];
        NSString *mountOps = [components objectAtIndex: 3];

        // fstab field ordering differs slightly across platforms.
        // We pick the safest available values without assuming extras.
        NSString *type = @"";
        NSString *freq = @"0";
        NSString *passno = @"0";

        if ([components count] >= 6)
        {
            // Common 6-field format: spec file vfstype mntops freq passno
            freq = [components objectAtIndex: 4];
            passno = [components objectAtIndex: 5];
        }

        if ([components count] >= 7)
        {
            // Some platforms include an additional type/version column.
            type = [components objectAtIndex: 4];
            freq = [components objectAtIndex: 5];
            passno = [components objectAtIndex: 6];
        }

        NSMutableDictionary *entry =
            [self buildEntrySpec: spec
                            file: file
                         vfsType: vfsType
                        mountOps: mountOps
                            type: type
                            freq: freq
                          passno: passno];
        [fstabArray addObject: entry];

        // Only add NFS to display
        if ([[components objectAtIndex: 2] isEqualToString: @"nfs"]) // fs_vfstype
        {
            [self.displayEntries addObject:entry];
        }
    }
    
    return fstabArray;
}

- (void) refreshData
{
    [self.table reloadData];
}

- (NSString *)serializedFstab
{
    NSMutableArray *lines = [NSMutableArray array];

    for (NSDictionary *entry in self.nfsImportsConfig)
    {
        NSString *spec = [entry objectForKey: @"fs_spec"] ?: @"";
        NSString *file = [entry objectForKey: @"fs_file"] ?: @"";
        NSString *vfsType = [entry objectForKey: @"fs_vfstype"] ?: @"";
        NSString *mountOps = [entry objectForKey: @"fs_mntops"] ?: @"defaults";
        NSString *type = [entry objectForKey: @"fs_type"] ?: @"";
        NSString *freq = [entry objectForKey: @"fs_freq"] ?: @"0";
        NSString *passno = [entry objectForKey: @"fs_passno"] ?: @"0";

        if ([spec length] == 0 || [file length] == 0 || [vfsType length] == 0)
        {
            continue;
        }

        if ([type length] > 0)
        {
            [lines addObject: [NSString stringWithFormat: @"%@\t%@\t%@\t%@\t%@\t%@\t%@",
                               spec, file, vfsType, mountOps, type, freq, passno]];
        }
        else
        {
            [lines addObject: [NSString stringWithFormat: @"%@\t%@\t%@\t%@\t%@\t%@",
                               spec, file, vfsType, mountOps, freq, passno]];
        }
    }

    NSString *contents = [lines componentsJoinedByString: @"\n"];
    if ([contents length] > 0)
    {
        contents = [contents stringByAppendingString: @"\n"];
    }
    return contents;
}

- (BOOL)saveFstabToDisk
{
    NSError *error = nil;
    BOOL saved = [[self serializedFstab] writeToFile:NFSFstabPath
                                         atomically:YES
                                           encoding:NSUTF8StringEncoding
                                              error:&error];
    if (saved == NO)
    {
        NSRunAlertPanelRelativeToWindow(@"Unable to Save Imports",
                                        @"Could not write %@.\n\n%@",
                                        @"OK",
                                        nil,
                                        nil,
                                        self.window,
                                        NFSFstabPath,
                                        [error localizedDescription]);
    }
    return saved;
}

- (NSMutableDictionary *) buildEntrySpec: (NSString *)spec
                                    file: (NSString *)file
                                 vfsType: (NSString *)vfsType
                                mountOps: (NSString *)mountOps
                                    type: (NSString *)type
                                    freq: (NSString *)freq
                                  passno: (NSString *)passno
{
    NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                               spec, @"fs_spec",
                               file, @"fs_file",
                            vfsType, @"fs_vfstype",
                           mountOps, @"fs_mntops",
                               type, @"fs_type",
                               freq, @"fs_freq",
                             passno, @"fs_passno", nil];
    
    return entry;
}

// Imports portion of the delegate
- (IBAction) add: (id)sender
{
    if ([self.mountPoint.stringValue isEqualToString: @""])
    {
        NSRunAlertPanelRelativeToWindow(@"Mount Point", @"Specify mount point",
                                        @"OK", nil, nil, self.window);
    }
    else
    {
        [self.importFromServerWindow makeKeyAndOrderFront: self];
    }
}

- (IBAction) remove: (id)sender
{
    NSIndexSet *selection = [self.table selectedRowIndexes];
    if ([selection count] == 0)
    {
        return;
    }

    // Remove selected entries from the visible list and backing store.
    [selection enumerateIndexesWithOptions:NSEnumerationReverse
                                usingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < [self.displayEntries count])
        {
            id entry = [self.displayEntries objectAtIndex: idx];
            [self.displayEntries removeObjectAtIndex: idx];
            [self.nfsImportsConfig removeObject: entry];
        }
    }];
    [self refreshData];
}

- (IBAction) ok: (id)sender
{
    if ([self saveFstabToDisk])
    {
        [self refreshData];
        [self.window performClose: self];
    }
}

- (IBAction) revert: (id)sender
{
    [self.displayEntries removeAllObjects];
    self.nfsImportsConfig = [self loadFstabIntoDictionary];
    [self refreshData];
}

// Imports Delegate/DataSource
- (IBAction) selectRetryMethod: (id)sender
{
    // Keep latest retry selection reflected in the popup state; no-op otherwise.
    if ([sender respondsToSelector: @selector(indexOfSelectedItem)])
    {
        (void)[sender indexOfSelectedItem];
    }
}

- (IBAction) selectSetuidAction: (id)sender
{
    if ([sender respondsToSelector: @selector(indexOfSelectedItem)])
    {
        (void)[sender indexOfSelectedItem];
    }
}

- (IBAction) selectMountThread: (id)sender
{
    if ([sender respondsToSelector: @selector(indexOfSelectedItem)])
    {
        (void)[sender indexOfSelectedItem];
    }
}

- (IBAction) selectMountPermissions: (id)sender
{
    if ([sender respondsToSelector: @selector(indexOfSelectedItem)])
    {
        (void)[sender indexOfSelectedItem];
    }
}

- (IBAction) select: (id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    NSModalResponse response = [panel runModal];
    if (response == NSModalResponseOK)
    {
        self.mountPoint.stringValue = panel.URL.path;
    }
}

// Expert options
- (IBAction) setExpertOptions: (id)sender
{
    [self.expertOptionsWindow performClose: self];
}

- (IBAction) cancelExpertOptions: (id)sender
{
    [self.expertOptionsWindow performClose: self];
}

// Imports from NFS window
- (IBAction) okImport:(id)sender
{
    NSString *sName = self.serverName.stringValue;
    NSString *rDir = self.remoteDirectory.stringValue;
    
    if ([sName isEqualToString: @""] == NO
        && [rDir isEqualToString: @""] == NO)
    {
        NSString *remote = [NSString stringWithFormat: @"%@:%@", sName, rDir];
        NSMutableArray *optionTokens = [NSMutableArray array];

        NSInteger rw =  [self.readWritePopup indexOfSelectedItem];
        NSString *readWrite = (rw == 0) ? @"rw":@"ro";
        [optionTokens addObject: readWrite];

        NSInteger mnt =  [self.mountThreadPopup indexOfSelectedItem];
        [optionTokens addObject: (mnt == 0) ? @"bg" : @"fg"];

        NSInteger suid =  [self.setuidPopup indexOfSelectedItem];
        [optionTokens addObject: (suid == 0) ? @"suid" : @"nosuid"];

        NSInteger retry = [self.retryPopup indexOfSelectedItem];
        if (retry == 2)
        {
            [optionTokens addObject: @"soft"];
        }
        else
        {
            [optionTokens addObject: @"hard"];
        }

        NSDictionary *expertOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"retry", @"mountRetries",
                                       @"timeo", @"nfsTimeout",
                                       @"retrans", @"nfsRetries",
                                       @"rsize", @"readBufferSize",
                                       @"wsize", @"writeBufferSize",
                                       @"port", @"serverIPPort",
                                       nil];
        NSDictionary *expertFields = [NSDictionary dictionaryWithObjectsAndKeys:
                                      self.mountRetries, @"mountRetries",
                                      self.nfsTimeout, @"nfsTimeout",
                                      self.nfsRetries, @"nfsRetries",
                                      self.readBufferSize, @"readBufferSize",
                                      self.writeBufferSize, @"writeBufferSize",
                                      self.serverIPPort, @"serverIPPort",
                                      nil];
        for (NSString *key in expertOptions)
        {
            NSTextField *field = [expertFields objectForKey: key];
            NSString *value = [field.stringValue stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([value length] > 0)
            {
                [optionTokens addObject: [NSString stringWithFormat: @"%@=%@",
                                          [expertOptions objectForKey: key],
                                          value]];
            }
        }

        NSString *ops = [optionTokens componentsJoinedByString: @","];
        
        NSMutableDictionary *entry =
            [self buildEntrySpec: remote
                          file: self.mountPoint.stringValue
                       vfsType: @"nfs"
                      mountOps: ops
                          type: @""
                          freq: @"0"
                        passno: @"0"];
        
        [self.displayEntries addObject: entry];
        [self.nfsImportsConfig addObject: entry];
        [self refreshData];
        
        [self.importFromServerWindow performClose: self];
    }
    else
    {
        NSRunAlertPanelRelativeToWindow(@"Warning",
					@"Server or Remote Directory not specified",
                                        @"OK",
					nil,
					nil,
					self.window);
    }
}

- (IBAction) cancelImport:(id)sender
{
    [self.importFromServerWindow performClose: self];
}

// Table Delegate

// Table Data Source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [self.displayEntries count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *ident = [tableColumn identifier];
    NSDictionary *dict = [self.displayEntries objectAtIndex: row];
    NSString *value = [dict objectForKey: ident];
    return value;
}


@end
