# JSONPath

A library for parsing and evaluating [JSONPath](https://goessner.net/articles/JsonPath/) queries on JSON data objects. It supports both simple path queries and advanced filter queries.

The implementation seeks to be compliant with [RFC9535](https://datatracker.ietf.org/doc/rfc9535/), and attempts to match the [consensus result for most queries](https://cburgmer.github.io/json-path-comparison/).

## Example

```haxe
import json.path.JSONPath;

var query = '$.a.b';
var data = {"a": {"b": "c"}}

// [ "$['a']['b']" ]
trace(JSONPath.queryPaths(query, data));
// [ "c" ]
trace(JSONPath.query(query, data))
```

## Licensing

JSONPath is made available under an open source MIT License. You can read more at [LICENSE](LICENSE.md).
