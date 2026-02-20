# Find TODOs

Search the codebase for TODO, FIXME, HACK, and other markers.

## Search Patterns
- TODO: Work to be done
- FIXME: Known issues to fix
- HACK: Temporary workarounds
- XXX: Problematic code
- NOTE: Important notes
- OPTIMIZE: Performance improvements needed

## Instructions

Search the codebase for these markers and report:
1. Location (file:line)
2. The marker type
3. The associated comment
4. Priority assessment

## Usage
`/find-todos` - Search entire codebase
`/find-todos src/` - Search specific directory
`/find-todos FIXME` - Search for specific marker

## Output
Organize findings by:
- Priority (critical, high, medium, low)
- Category (TODO, FIXME, etc.)
- File/module
