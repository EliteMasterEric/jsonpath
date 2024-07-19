package json.path;

import json.util.TypeUtil;
import json.path.JSONPath;
import yaml.util.ObjectMap;
import json.JSONData;

class JSONPathConsensusTest {
    public static function test():Void {
        var queries:Queries = parseSuiteData();

        testSupported(queries.supported);
        testNoConsensus(queries.noConsensus);
        testUnsupported(queries.unsupported);
    }

    static function testQuery(query:TestQuery):Bool {
        // trace('* ${query.id}, ${query.selector}, ${query.document}, ${query.consensus}');

        var result = JSONPath.query(query.selector, query.document);

        var success = json.util.ArrayUtil.equalsUnordered(result, query.consensus);

        if (success) {
            trace('SUCCESS - ${query.id}');
        } else {
            trace('FAILURE - ${query.id}');
            trace('  Expected (${Type.typeof(query.consensus)}): ${query.consensus}');
            trace('  Actual (${Type.typeof(result)}): ${result}');
        }

        return success;
    }

    static function evalQuery(query:TestQuery):Bool {
        // trace('* ${query.id}, ${query.selector}, ${query.document}, ${query.consensus}');

        var result = JSONPath.query(query.selector, query.document);

        trace('RESULT - ${query.id}');
        trace('  ${result}');

        return true;
    }

    static function testSupported(queryData:Array<TestQuery>):Void {
        trace('===TESTS===');
        trace('Testing supported queries...');
        
        var successes = 0;
        var failures = 0;
        var errors = 0;

        for (query in queryData) {
            try {
                var result = testQuery(query);
                
                if (result) successes++;
                else failures++;
            } catch (e) {
                trace('ERROR - ${query.id}');
                trace('  ${e}');
                errors++;
            }
        }

        trace('===RESULTS===');
        trace('Successes: ${successes}');
        trace('Failures: ${failures}');
        trace('Errors: ${errors}');
    }
    
    static function testNoConsensus(queryData:Array<TestQuery>):Void {
        trace('===TESTS===');
        trace('Testing no consensus queries...');
        
        var successes = 0;
        var failures = 0;
        var errors = 0;

        for (query in queryData) {
            try {
                var result = evalQuery(query);
                successes++;                
            } catch (e) {
                trace('ERROR - ${query.id}');
                trace('  ${e}');
                errors++;
            }
        }

        trace('===RESULTS===');
        trace('Successes: ${successes}');
        trace('Errors: ${errors}');
    }

    static function testUnsupported(queryData:Array<TestQuery>):Void {
        trace('===TESTS===');
        trace('Testing unsupported queries...');
        
        var successes = 0;
        var failures = 0;
        var errors = 0;

        for (query in queryData) {
            try {
                var result = testQuery(query);
                
                if (result) successes++;
                else failures++;
            } catch (e) {
                trace('ERROR - ${query.id}');
                trace('  ${e}');
                errors++;
            }
        }

        trace('===RESULTS===');
        trace('Successes: ${successes}');
        trace('Failures: ${failures}');
        trace('Errors: ${errors}');
    }

    static function parseSuiteData():Queries {
        var testData:Dynamic = yaml.Yaml.read("../../json-path-comparison/regression_suite/regression_suite.yaml", yaml.Parser.options().useObjects());

        var queryData:Array<TestQuery> = [];

        var queries:Array<Dynamic> = testData.queries;
        for (query in queries) {
            var queryEntry:TestQuery = {
                id: query.id,
                selector: query.selector,
                document: query.document,
                consensus: query.consensus
            };

            queryData.push(queryEntry);
        }

        var queryData_Supported:Array<TestQuery> = [];
        var queryData_Unsupported:Array<TestQuery> = [];
        var queryData_NoConsensus:Array<TestQuery> = [];

        for (queryEntry in queryData) {
            if (queryEntry.consensus == null) {
                queryData_NoConsensus.push(queryEntry);
            } else if (queryEntry.consensus == "NOT_SUPPORTED") {
                queryData_Unsupported.push(queryEntry);
            } else {
                queryData_Supported.push(queryEntry);
            }
        }

        trace('Parsed consensus data:');
        trace('- ${queryData_Supported.length} supported queries');
        trace('- ${queryData_Unsupported.length} NOT_SUPPORTED queries');
        trace('- ${queryData_NoConsensus.length} queries without consensus');

        return {
            supported: queryData_Supported,
            unsupported: queryData_Unsupported,
            noConsensus: queryData_NoConsensus
        }
    }
}

typedef Queries = {
    var supported: Array<TestQuery>;
    var unsupported: Array<TestQuery>;
    var noConsensus: Array<TestQuery>;
}

typedef TestQuery = {
    var id: String;
    var selector: String;
    var document: Dynamic;
    var consensus: Dynamic;
}