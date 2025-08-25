//
//  ImportsController.m
//  NFSManager
//
//  Created by Gregory John Casamento on 9/2/23.
//

/*
 * File: Sources/NFSManager/ImportsController.m
 * Platform: macOS (AppKit) & GNUstep (Linux) — reads/writes /etc/fstab
 * NOTE: Avoid Objective‑C 2.0 features (no properties, no literals for
 *       collections, no fast enumeration). Manual retain/release.
 * Style: GNU Coding Standards — brace placement, two‑space indent,
 *        block comments, and spaces before function‑like parentheses.
 */

#import "ImportsController.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/* Managed region markers to preserve user content outside our block. */
static NSString *kFstabManagedBegin = @"# BEGIN NFSManager";
static NSString *kFstabManagedEnd   = @"# END NFSManager";

/* Keys for entry dictionaries. */
static NSString *kSpecKey    = @"spec";     /* device or remote share */
static NSString *kFileKey    = @"file";     /* mount point */
static NSString *kVfsTypeKey = @"vfsType";  /* filesystem type */
static NSString *kOptsKey    = @"mountOps"; /* options (comma-separated) */
static NSString *kTypeKey    = @"type";     /* historical dump field */
static NSString *kFreqKey    = @"freq";     /* dump frequency */
static NSString *kPassnoKey  = @"passno";   /* fsck pass number */

/* Helper to provide stable columns without ObjC2 ivars/properties. */
static NSArray *
CCColumnsArray (void)
{
  static NSArray *arr = nil;
  if (!arr)
    {
      arr = [[NSArray alloc] initWithObjects:
             kSpecKey, kFileKey, kVfsTypeKey, kOptsKey, kTypeKey, kFreqKey, kPassnoKey, nil];
    }
  return arr;
}

static NSDictionary *
CCColumnNames (void)
{
  static NSDictionary *dict = nil;
  if (!dict)
    {
      dict = [[NSDictionary alloc] initWithObjectsAndKeys:
              @"Device/Spec", kSpecKey,
              @"Mount Point", kFileKey,
              @"Type",        kVfsTypeKey,
              @"Options",     kOptsKey,
              @"Dump",        kTypeKey,
              @"Freq",        kFreqKey,
              @"Pass",        kPassnoKey,
              nil];
    }
  return dict;
}

@interface ImportsController (Private)
/* Private API — declarations only (no ObjC2 features). */
- (NSString *)fstabPath;
- (NSArray *)readLinesAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)writeLines:(NSArray *)lines toPath:(NSString *)path error:(NSError **)error;
- (NSRange)managedBlockRangeInLines:(NSArray *)lines;
- (NSString *)escapeField:(NSString *)field;
- (NSString *)unescapeField:(NSString *)field;
- (NSDictionary *)parseEntryLine:(NSString *)line; /* may return nil */
- (NSString *)serializeEntry:(NSDictionary *)entry;
- (NSArray *)parseEntriesFromLines:(NSArray *)lines;
- (NSArray *)parseEntriesFromManagedBlock:(NSArray *)lines;
- (BOOL)saveFstab:(NSError **)error;
@end

@implementation ImportsController

/* We assume ivars such as `nfsImportsConfig`, `table`, `expertOptionsWindow`,
   and `importFromServerWindow` are declared in the header as IBOutlets/ivars. */

- (id)
init
{
  self = [super init];
  if (self != nil)
    {
      if (nfsImportsConfig == nil)
        {
          nfsImportsConfig = [[NSMutableArray alloc] init];
        }
    }
  return self;
}

#ifdef GNUSTEP
- (void) dealloc
{
    [nfsImportsConfig release];
    nfsImportsConfig = nil;
    [super dealloc];
}
#endif

/* Public API from header. */
- (NSMutableArray *) loadFstabIntoDictionary
{
  NSError *err = nil;
  NSString *path = [self fstabPath];
  NSArray *lines = [self readLinesAtPath:path error:&err];
  if (lines == nil)
    {
      /* Missing/unreadable fstab: treat as empty. */
      if (nfsImportsConfig != nil)
        [nfsImportsConfig removeAllObjects];
      return nfsImportsConfig;
    }

  NSArray *entries = [self parseEntriesFromManagedBlock:lines];
  if ([entries count] == 0)
    entries = [self parseEntriesFromLines:lines];

  [nfsImportsConfig removeAllObjects];
  if (entries != nil)
    {
      NSUInteger i, c = [entries count];
      for (i = 0; i < c; i++)
        {
          NSDictionary *d = [entries objectAtIndex:i];
          [nfsImportsConfig addObject:d];
        }
    }

  return nfsImportsConfig;
}

- (void) setupTableColumns
{
  [self removeTableColumns];

  NSArray *cols = CCColumnsArray ();
  NSUInteger i, c = [cols count];
  for (i = 0; i < c; i++)
    {
      NSString *identifier = [cols objectAtIndex:i];
      NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:identifier];
      [col setWidth:140.0];
      [col setMinWidth:80.0];
      id headerCell = [col headerCell];
      NSString *title = [CCColumnNames () objectForKey:identifier];
      if (title == nil)
        title = identifier;
      [headerCell setStringValue:title];
      [table addTableColumn:col];
#ifdef GNUSTEP
      [col release];
#endif
    }
  [table setDelegate:self];
  [table setDataSource:self];
  [table reloadData];
}

- (void) removeTableColumns
{
  /* Copy the array to avoid mutation during enumeration. */
  NSArray *current = [NSArray arrayWithArray:[table tableColumns]];
  NSUInteger i, c = [current count];
  for (i = 0; i < c; i++)
    [table removeTableColumn:[current objectAtIndex:i]];
}

- (void) refreshData
{
  [table reloadData];
}

- (NSMutableDictionary *)
buildEntrySpec:(NSString *)spec
           file:(NSString *)file
        vfsType:(NSString *)vfsType
       mountOps:(NSString *)mountOps
           type:(NSString *)type
           freq:(NSString *)freq
         passno:(NSString *)passno
{
  if (spec == nil) spec = @"";
  if (file == nil) file = @"";
  if (vfsType == nil || [vfsType length] == 0) vfsType = @"auto";
  if (mountOps == nil || [mountOps length] == 0) mountOps = @"defaults";
  if (type == nil || [type length] == 0) type = @"0";
  if (freq == nil || [freq length] == 0) freq = @"0";
  if (passno == nil || [passno length] == 0) passno = @"0";

  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            spec,    kSpecKey,
                            file,    kFileKey,
                            vfsType, kVfsTypeKey,
                            mountOps,kOptsKey,
                            type,    kTypeKey,
                            freq,    kFreqKey,
                            passno,  kPassnoKey,
                            nil];
  return d;
}

/* UI Actions. */
- (IBAction) add:(id)sender
{
  NSMutableDictionary *empty = [self buildEntrySpec:@"" file:@"" vfsType:@"auto" mountOps:@"defaults" type:@"0" freq:@"0" passno:@"0"];
  [nfsImportsConfig addObject:empty];
  [self refreshData];
}

- (IBAction) remove:(id)sender
{
  NSIndexSet *sel = [table selectedRowIndexes];
  if ([sel count] == 0)
    return;

  /* Remove selected rows (from highest to lowest). */
  NSUInteger idx = [sel lastIndex];
  while (idx != NSNotFound)
    {
      if (idx < [nfsImportsConfig count])
        [nfsImportsConfig removeObjectAtIndex:idx];
      idx = [sel indexLessThanIndex:idx];
    }
  [self refreshData];
}

- (IBAction)
select:(id)sender
{ [self refreshData]; }

- (IBAction)
selectMountPermissions:(id)sender
{ [self refreshData]; }

- (IBAction)
selectMountThread:(id)sender
{ [self refreshData]; }

- (IBAction)
selectSetuidAction:(id)sender
{ [self refreshData]; }

- (IBAction)
selectRetryMethod:(id)sender
{ [self refreshData]; }

- (IBAction)
setExpertOptions:(id)sender
{ [self refreshData]; [expertOptionsWindow close]; }

- (IBAction)
cancelExpertOptions:(id)sender
{ [expertOptionsWindow close]; }

- (IBAction)
cancelImport:(id)sender
{ [importFromServerWindow close]; }

- (IBAction)
okImport:(id)sender
{ [self refreshData]; [importFromServerWindow close]; }

/* Public convenience. */
- (BOOL)
saveToSystemFstabWithError:(NSError **)error
{ return [self saveFstab:error]; }

/* NSTableView DataSource / Delegate. */
- (NSInteger)
numberOfRowsInTableView:(NSTableView *)tableView
{ return (NSInteger)[nfsImportsConfig count]; }

- (id)
tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  if (row < 0 || row >= (NSInteger)[nfsImportsConfig count])
    return @"";
  NSDictionary *entry = [nfsImportsConfig objectAtIndex:(NSUInteger)row];
  NSString *key = [tableColumn identifier];
  id val = [entry objectForKey:key];
  return (val != nil) ? val : @"";
}

- (void)
tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
  if (tableColumn == nil) return;
  if (row < 0 || row >= (NSInteger)[nfsImportsConfig count]) return;
  NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary:[nfsImportsConfig objectAtIndex:(NSUInteger)row]];
  if (object == nil) object = @"";
  [m setObject:object forKey:[tableColumn identifier]];
  [nfsImportsConfig replaceObjectAtIndex:(NSUInteger)row withObject:m];
  [self refreshData];
}

/* Private: Paths & IO. */
- (NSString *)
fstabPath
{
  const char *override = getenv ("NFSMANAGER_FSTAB_PATH");
  if (override != NULL)
    return [NSString stringWithUTF8String:override];
  return @"/etc/fstab"; /* Linux & macOS. */
}

- (NSArray *)
readLinesAtPath:(NSString *)path error:(NSError **)error
{
  NSData *data = [NSData dataWithContentsOfFile:path options:0 error:error];
  if (data == nil)
    return nil;
#ifdef GNUSTEP
  NSString *content = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
#else
  NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#endif
  if (content == nil)
#ifdef GNUSTEP
    content = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
#else
    content = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
#endif
  if (content == nil)
    {
      if (error != NULL && *error == nil)
        *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                     code:NSFileReadUnknownStringEncodingError
                                 userInfo:[NSDictionary dictionaryWithObject:(path != nil ? path : @"") forKey:NSFilePathErrorKey]];
      return nil;
    }

  NSCharacterSet *newline = [NSCharacterSet newlineCharacterSet];
  NSArray *lines = [content componentsSeparatedByCharactersInSet:newline];
  return lines;
}

- (BOOL) writeLines: (NSArray *)lines toPath: (NSString *)path error: (NSError **)error
{
  /* Defensive writing: timestamped backup + atomic write. */
  NSString *dir = [path stringByDeletingLastPathComponent];
  NSString *base = [path lastPathComponent];
  NSString *stamp = [[NSDate date] description];
  NSString *backup = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@".%@.bak-%@", base, stamp]];

  NSFileManager *fm = [NSFileManager defaultManager];
  if ([fm fileExistsAtPath:path])
    (void)[fm copyItemAtPath:path toPath:backup error:nil];

  NSString *joined = [lines componentsJoinedByString:@""];
  return [joined writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:error];
}

/* Private: Managed Block. */
- (NSRange) managedBlockRangeInLines:(NSArray *)lines
{
  NSUInteger start = NSNotFound, end = NSNotFound;
  NSUInteger i, c = [lines count];
  for (i = 0; i < c; i++)
    {
      NSString *s = [lines objectAtIndex:i];
      if (start == NSNotFound && [s isEqualToString:kFstabManagedBegin])
        { start = i; continue; }
      if (start != NSNotFound && [s isEqualToString:kFstabManagedEnd])
        { end = i; break; }
    }
  if (start != NSNotFound && end != NSNotFound && end > start)
    return NSMakeRange (start, end - start + 1);
  return NSMakeRange (NSNotFound, 0);
}

/* Private: Parse & Serialize. */
- (NSString *) unescapeField:(NSString *)field
{
  /* Replace classic octal escapes like   (space),      (tab),
 (nl), \ (backslash). */
  NSMutableString *m = [field mutableCopy];
  NSError *rxErr = nil;
  NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"\\([0-7]{3})" options:0 error:&rxErr];
  if (re == nil)
#ifdef GNUSTEP
    return [m autorelease];
#else
    return m;
#endif
  NSArray *matches = [re matchesInString:m options:0 range:NSMakeRange (0, [m length])];
  NSInteger idx;
  for (idx = (NSInteger)[matches count] - 1; idx >= 0; idx--)
    {
      NSTextCheckingResult *match = [matches objectAtIndex:(NSUInteger)idx];
      NSRange r1 = [match rangeAtIndex:1];
      NSString *oct = [m substringWithRange:r1];
      unsigned val = 0; sscanf ([oct UTF8String], "%o", &val);
      unichar ch = (unichar)(val & 0xFF);
      NSString *replacement = [NSString stringWithCharacters:&ch length:1];
      [m replaceCharactersInRange:[match range] withString:replacement];
    }
#ifdef GNUSTEP
    return [m autorelease];
#else
    return m;
#endif
}

- (NSString *)
escapeField:(NSString *)field
{
  NSMutableString *m = [NSMutableString string];
  NSUInteger i, len = [field length];
  for (i = 0; i < len; i++)
    {
      unichar c = [field characterAtIndex:i];
      if (c == ' ')
        [m appendString:@"\040"];
      else if (c == '    ')
        [m appendString:@"\011"];
      else if (c == ' ')
        [m appendString:@"\012"];
      else if (c == '\'')
        [m appendString:@"\134"];
      else
        [m appendFormat:@"%C", c];
    }
  return m;
}

- (NSDictionary *)
parseEntryLine:(NSString *)line
{
  NSString *trim = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  if ([trim length] == 0)
    return nil;
  if ([trim hasPrefix:@"#"])
    return nil;

  /* Split by whitespace; fields with spaces are octal-escaped. */
  NSMutableArray *tokens = [NSMutableArray array];
  NSMutableString *cur = [NSMutableString string];
  BOOL inEscape = NO;
  NSUInteger i, L = [line length];
  for (i = 0; i < L; i++)
    {
      unichar c = [line characterAtIndex:i];
      if (c == '\'')
        { inEscape = YES; [cur appendFormat:@"%C", c]; continue; }
      if (inEscape)
        { inEscape = NO; [cur appendFormat:@"%C", c]; continue; }
      if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:c])
        {
          if ([cur length] > 0)
            {
              [tokens addObject:[NSString stringWithString:cur]];
              [cur setString:@""];
            }
          continue;
        }
      [cur appendFormat:@"%C", c];
    }
  if ([cur length] > 0)
    [tokens addObject:[NSString stringWithString:cur]];

  if ([tokens count] < 4)
    return nil; /* spec file vfs opts are mandatory */

  NSString *spec    = [self unescapeField:[tokens objectAtIndex:0]];
  NSString *file    = [self unescapeField:[tokens objectAtIndex:1]];
  NSString *vfsType = [self unescapeField:[tokens objectAtIndex:2]];
  NSString *opts    = [self unescapeField:[tokens objectAtIndex:3]];
  NSString *type    = ([tokens count] > 4) ? [tokens objectAtIndex:4] : @"0";
  NSString *freq    = ([tokens count] > 5) ? [tokens objectAtIndex:5] : @"0";
  NSString *passno  = ([tokens count] > 6) ? [tokens objectAtIndex:6] : @"0";

  NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                     spec,    kSpecKey,
                     file,    kFileKey,
                     vfsType, kVfsTypeKey,
                     opts,    kOptsKey,
                     type,    kTypeKey,
                     freq,    kFreqKey,
                     passno,  kPassnoKey,
                     nil];
  return d;
}

- (NSString *)
serializeEntry:(NSDictionary *)entry
{
  NSString *spec    = [self escapeField:([entry objectForKey:kSpecKey] != nil ? [entry objectForKey:kSpecKey] : @"")];
  NSString *file    = [self escapeField:([entry objectForKey:kFileKey] != nil ? [entry objectForKey:kFileKey] : @"")];
  NSString *vfsType = [self escapeField:([entry objectForKey:kVfsTypeKey] != nil ? [entry objectForKey:kVfsTypeKey] : @"auto")];
  NSString *opts    = [self escapeField:([entry objectForKey:kOptsKey] != nil ? [entry objectForKey:kOptsKey] : @"defaults")];
  NSString *type    = ([entry objectForKey:kTypeKey]   != nil ? [entry objectForKey:kTypeKey]   : @"0");
  NSString *freq    = ([entry objectForKey:kFreqKey]   != nil ? [entry objectForKey:kFreqKey]   : @"0");
  NSString *passno  = ([entry objectForKey:kPassnoKey] != nil ? [entry objectForKey:kPassnoKey] : @"0");

  NSArray *parts = [NSArray arrayWithObjects:spec, file, vfsType, opts, type, freq, passno, nil];
  return [parts componentsJoinedByString:@"    "]; /* tabs for readability */
}

- (NSArray *)
parseEntriesFromLines:(NSArray *)lines
{
  NSMutableArray *result = [NSMutableArray array];
  NSUInteger i, c = [lines count];
  for (i = 0; i < c; i++)
    {
      NSDictionary *d = [self parseEntryLine:[lines objectAtIndex:i]];
      if (d != nil)
        [result addObject:d];
    }
  return result;
}

- (NSArray *)
parseEntriesFromManagedBlock:(NSArray *)lines
{
  NSRange r = [self managedBlockRangeInLines:lines];
  if (r.location == NSNotFound || r.length < 3)
    return [NSArray array];
  NSUInteger begin = r.location + 1;
  NSUInteger end_index = r.location + r.length - 1; /* index of END marker */
  NSRange slice = NSMakeRange (begin, end_index - begin);
  NSArray *sub = [lines subarrayWithRange:slice];
  return [self parseEntriesFromLines:sub];
}

/* Private: Save. */
- (BOOL)
saveFstab:(NSError **)error
{
  NSString *path = [self fstabPath];
  NSError *readErr = nil;
  NSArray *original = [self readLinesAtPath:path error:&readErr];
  if (original == nil)
    original = [NSArray array];

  /* Validate entries before writing. */
  NSUInteger i, c = [nfsImportsConfig count];
  for (i = 0; i < c; i++)
    {
      NSDictionary *e = [nfsImportsConfig objectAtIndex:i];
      NSString *spec = [e objectForKey:kSpecKey];
      NSString *file = [e objectForKey:kFileKey];
      NSString *typ  = [e objectForKey:kVfsTypeKey];
      if ([spec length] == 0 || [file length] == 0 || [typ length] == 0)
        {
          if (error != NULL)
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSValidationErrorMinimum
                                     userInfo:[NSDictionary dictionaryWithObject:@"Invalid fstab entry: spec, file, and type are required."
                                                                          forKey:NSLocalizedDescriptionKey]];
          return NO;
        }
    }

  /* Build managed block. */
  NSMutableArray *managed = [NSMutableArray array];
  [managed addObject:kFstabManagedBegin];
  [managed addObject:@"# Managed by NFSManager — edits within this block may be overwritten."];
  for (i = 0; i < c; i++)
    [managed addObject:[self serializeEntry:[nfsImportsConfig objectAtIndex:i]]];
  [managed addObject:kFstabManagedEnd];

  /* Merge with original content. */
  NSRange r = [self managedBlockRangeInLines:original];
  NSMutableArray *merged = [NSMutableArray arrayWithArray:original];
  if (r.location == NSNotFound)
    {
      if ([merged count] > 0 && ![[merged lastObject] isEqualToString:@""])
        [merged addObject:@""]; /* single blank line before block */
      [merged addObjectsFromArray:managed];
    }
  else
    {
      /* Replace existing block. */
      [merged replaceObjectsInRange:r withObjectsFromArray:managed];
    }

  return [self writeLines:merged toPath:path error:error];
}

@end
