# Find Dead Code

Identify unused code that can be safely removed.

## What to Look For

### Unused Functions
Functions that are never called.

### Unused Variables
Variables that are assigned but never used.

### Unreachable Code
Code after return/raise that never executes.

### Unused Imports
Imports that aren't used in the file.

### Commented Code
Old code that's been commented out.

### Unused Classes
Classes that are never instantiated.

## Instructions

1. Analyze the codebase for unused code
2. Verify findings (check for dynamic usage)
3. Report with confidence level
4. Suggest safe removals

## Usage
`/dead-code` - Scan entire codebase
`/dead-code src/` - Scan specific directory

## Guidelines
- Be conservative - false positives are worse than false negatives
- Check for dynamic imports/calls
- Consider test files separately
- Note any uncertainty
