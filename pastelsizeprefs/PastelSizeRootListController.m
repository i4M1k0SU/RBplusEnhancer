#include "PastelSizeRootListController.h"

@implementation PastelSizeRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"PastelSizePrefs" target:self] retain];
	}

	return _specifiers;
}

@end
