//
// Copyright 2011 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "NIDOM.h"

#import "NIStylesheet.h"
#import "NimbusCore.h"


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation NIDOM


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
  NI_RELEASE_SAFELY(_stylesheet);
  NI_RELEASE_SAFELY(_registeredViews);
  NI_RELEASE_SAFELY(_viewToSelectorsMap);

  [super dealloc];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (id)domWithStylesheet:(NIStylesheet *)stylesheet {
  return [[[self alloc] initWithStylesheet:stylesheet] autorelease];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (id)domWithStylesheetRootPath:(NSString *)rootPath filenames:(NSString *)stylesheetPath, ... {
  va_list ap;
  va_start(ap, stylesheetPath);

  NIStylesheet* compositeStylesheet = [[[NIStylesheet alloc] init] autorelease];

  while (nil != stylesheetPath) {
    NIDASSERT([stylesheetPath isKindOfClass:[NSString class]]);

    if ([stylesheetPath isKindOfClass:[NSString class]]) {
      NIStylesheet* stylesheet = [[NIStylesheet alloc] init];
      if ([stylesheet loadFromPath:stylesheetPath pathPrefix:rootPath]) {
        [compositeStylesheet addStylesheet:stylesheet];
      }
      NI_RELEASE_SAFELY(stylesheet);
    }
    stylesheetPath = va_arg(ap, NSString*);
  }
  va_end(ap);

  return [[[self alloc] initWithStylesheet:compositeStylesheet] autorelease];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStylesheet:(NIStylesheet *)stylesheet {
  if ((self = [super init])) {
    _stylesheet = [stylesheet retain];
    _registeredViews = [[NSMutableSet alloc] init];
    _viewToSelectorsMap = [[NSMutableDictionary alloc] init];
  }
  return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Styling Views


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)refreshStyleForView:(UIView *)view withSelectorName:(NSString *)selectorName {
  [_stylesheet applyStyleToView:view withClassName:selectorName];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)keyForView:(UIView *)view {
  return [NSNumber numberWithLong:(long)view];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerSelector:(NSString *)selector withView:(UIView *)view {
  id key = [self keyForView:view];
  NSMutableArray* selectors = [_viewToSelectorsMap objectForKey:key];
  if (nil == selectors) {
    selectors = [[[NSMutableArray alloc] init] autorelease];
    [_viewToSelectorsMap setObject:selectors forKey:key];
  }
  [selectors addObject:selector];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerView:(UIView *)view {
  NSString* selector = NSStringFromClass([view class]);
  [self registerSelector:selector withView:view];

  [_registeredViews addObject:view];
  [self refreshStyleForView:view withSelectorName:selector];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)registerView:(UIView *)view withCSSClass:(NSString *)cssClass {
  [self registerView:view];

  NSString* selector = [@"." stringByAppendingString:cssClass];
  [self registerSelector:selector withView:view];

  [self refreshStyleForView:view withSelectorName:selector];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unregisterView:(UIView *)view {
  [_registeredViews removeObject:view];
  [_viewToSelectorsMap removeObjectForKey:[self keyForView:view]];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)unregisterAllViews {
  [_registeredViews removeAllObjects];
  [_viewToSelectorsMap removeAllObjects];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)refresh {
  for (UIView* view in _registeredViews) {
    for (NSString* selector in [_viewToSelectorsMap objectForKey:[self keyForView:view]]) {
      [self refreshStyleForView:view withSelectorName:selector];
    }
  }
}

@end
