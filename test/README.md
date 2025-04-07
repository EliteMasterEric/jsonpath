# Test Suite

The test suite is comprised of two modules:

- The `unit` module, which executes individual functions of the library with specific inputs to ensure correct behavior.
- The `consensus` module, which executes publicly available test suites to ensure correct behavior.
    - [json-path-comparison](https://github.com/cburgmer/json-path-comparison/) provides a [regression suite](https://github.com/cburgmer/json-path-comparison/blob/master/regression_suite/regression_suite.yaml), which provides a list of JSONPath queries, along with the result of those queries (as determined by consensus of implementations by libraries in other languages). Result will be NOT_SUPPORTED if most JSONPath libraries do not support the syntax.
    - [jsonpath-compliance-test-suite](https://github.com/jsonpath-standard/jsonpath-compliance-test-suite/) provides a [test suite](https://github.com/jsonpath-standard/jsonpath-compliance-test-suite/blob/main/cts.json), providing a list of JSONPath queries along with info on their expected result.

Failing tests from the `consensus` module are copied to the `unit` module, where they can be individually validated and thoroughly diagnosed.
