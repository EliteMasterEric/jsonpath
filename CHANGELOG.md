# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-04-07
### Added
- Added an optional `allowNewPaths` argument to `JSONPaths.queryPaths()`, which allows for name and index selectors to be resolved even if the element does not exist. This is useful when determining paths for operations which add new elements to the JSON data.

### Changed
- Improve resolution of numeric paths targeting arrays.

### Fixed
- Fixed an issue where comparisons to `[]` would not be parsed as a comparison to an empty array.
- Fixed an issue where `undefined == []` would resolve to false, making certain filters impossible.
    - Ensured that comparisons between `null` and `[]` values always return false.
    - Ensured that comparisons between `null` and `undefined` values always return false.

### Known Issues
- A difference in handling of carriage returns in HashLink and C++ results in some tests involving regular expressions to fail.


## [1.0.0] - 2024-07-19
Initial release.
### Added
- Full support for JSONPath parsing with 99.9% compliance.
