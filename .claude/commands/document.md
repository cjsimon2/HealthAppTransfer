# Documentation Generation

Generate or improve documentation for code.

## Documentation Types

### Docstrings
Add/update function and class docstrings.

### README
Update project README with:
- Installation instructions
- Usage examples
- API documentation

### API Docs
Generate API documentation for public interfaces.

### Comments
Add explanatory comments for complex logic.

## Usage
`/document src/api/` - Document all files in directory
`/document src/utils.py` - Document specific file
`/document README` - Update README
`/document ALL` - Comprehensive project-wide documentation update

## ALL Mode

When invoked with `ALL`, perform a comprehensive documentation sweep:

### 1. Project Analysis
- Read and understand the full codebase structure
- Analyze all modules, classes, and functions
- Identify public APIs and key interfaces
- Map dependencies and data flows

### 2. Update These Files
- **README.md** - Project overview, installation, usage, examples
- **CLAUDE.md** - Development guidance, patterns, conventions
- **STATE.md** - Current project state and metrics
- **Any other .md files** - Keep them accurate and current

### 3. Code Documentation
- Add/update docstrings for all public functions and classes
- Document complex private functions that need explanation
- Add module-level docstrings describing purpose

### 4. Analysis Approach
- Study actual source code, not just git history
- Trace execution paths to understand behavior
- Identify undocumented features or APIs
- Note any discrepancies between docs and implementation

### 5. Output
- List all files updated
- Summarize major documentation changes
- Flag any areas needing human review

## Guidelines
- Use project's docstring format
- Keep documentation concise
- Include examples where helpful
- Document public APIs thoroughly
- Don't over-document obvious code
