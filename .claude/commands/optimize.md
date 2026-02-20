# Performance Optimization

Analyze and improve performance of code or queries.

## Analysis Steps

1. **Identify Bottlenecks**
   - Profile the code
   - Find slow functions
   - Check database queries

2. **Measure Baseline**
   - Record current performance
   - Set targets

3. **Optimize**
   - Apply targeted improvements
   - Re-measure after each change

## Common Optimizations

### Algorithmic
- Use better data structures
- Reduce time complexity
- Cache computed values

### Database
- Add indexes
- Optimize queries
- Reduce N+1 queries

### Memory
- Reduce allocations
- Use generators/iterators
- Clean up references

### I/O
- Batch operations
- Use async where appropriate
- Add caching

## Usage
`/optimize src/data_processor.py`
`/optimize database queries in user module`
