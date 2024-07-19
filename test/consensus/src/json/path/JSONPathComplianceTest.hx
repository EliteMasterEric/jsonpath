package test.consensus.src.json.path;

import json.path.JSONPath;
import sys.io.File;
import json.JSONData;

class JSONPathComplianceTest {
    public static function test():Void {
        var queries:Array<TestQuery> = parseComplianceData();

        testCompliance(queries);
    }
    
    static function validateTest(query:TestQuery):Void {
        if (query.result == null && query.results == null && !(query.invalid_selector ?? false)) {
            throw "INVALID TEST";
        }

        switch (query.name) {
            case "functions, search, dot matcher on \\u2028":
                // Fails because PCRE regex strings match \r on the pattern '.'
                throw "SKIPPED TEST";
            case "functions, search, dot matcher on \\u2029":
                // Fails because PCRE regex strings match \r on the pattern '.'
                throw "SKIPPED TEST";
            case "functions, match, dot matcher on \\u2028":
                // Fails because PCRE regex strings match \r on the pattern '.'
                throw "SKIPPED TEST";
            case "functions, match, dot matcher on \\u2029":
                // Fails because PCRE regex strings match \r on the pattern '.'
                throw "SKIPPED TEST";
        }
    }

    static function testQuery(query:TestQuery):Bool {
        try {
            validateTest(query);

            var result = JSONPath.query(query.selector, query.document);
            
            var expected = query.result ?? query.results[0];

            var success = json.util.ArrayUtil.equalsUnordered(result, expected);
            
            if (query.invalid_selector) {
                trace('FAILURE (invalid selector) - ${query.name}');
                trace('  Expected: ERROR');
                trace('  Actual (${Type.typeof(result)}): ${result}');
                return false;
            }
            else if (success) {
                trace('SUCCESS - ${query.name}');
                return true;
            } else {
                trace('FAILURE - ${query.name}');
                trace('  Expected (${Type.typeof(query.result)}): ${query.result}');
                trace('  Actual (${Type.typeof(result)}): ${result}');
                return false;
            }
            
            return success;
        } catch (e) {
            if ('$e' == "INVALID TEST" || '$e' == "SKIPPED TEST") {
                throw e;
            } else if (query.invalid_selector) {
                trace('SUCCESS - ${query.name}');
                return true;
            } else {
                throw e;
            }
        }
    }

    static function testCompliance(queryData:Array<TestQuery>):Void {
        trace('===TESTS===');
        trace('Testing ${queryData.length} compliance queries...');
        
        var successes = 0;
        var failures = 0;
        var errors = 0;
        var skipped = 0;

        for (query in queryData) {
            try {
                var result = testQuery(query);
            
                if (result) successes++;
                else failures++;
            } catch (e) {
                if ('$e' == "INVALID TEST") {
                    trace('INVALID - ${query.name}');
                    errors++;
                } else if ('$e' == "SKIPPED TEST") {
                    trace('SKIPPED - ${query.name}');
                    skipped++;
                } else {   
                    trace('ERROR - ${query.name}');
                    trace('  ${e}');
                    errors++;
                }
            }
        }
        
        trace('===RESULTS===');
        trace('Successes: ${successes}');
        trace('Failures: ${failures}');
        trace('Errors: ${errors}');
        trace('Skipped: ${skipped}');
    }

    static function parseComplianceData():Array<TestQuery> {
        var testDataStr:String = File.getContent("../../jsonpath-compliance-test-suite/cts.json");
        var testData:JSONData = JSONData.parse(testDataStr);

        var tests:Array<JSONData> = testData.getData('tests');

        var queries:Array<TestQuery> = [];
        for (test in tests) {
            var query:TestQuery = {
                name: test.getData('name'),
                selector: test.getData('selector'),
                invalid_selector: test.getData('invalid_selector'),
                document: test.getData('document'),
                result: test.getData('result'),
                results: test.getData('results')
            };
            queries.push(query);
        }

        return queries;
    }

}

typedef TestQuery = {
    var name:String;
    var selector:String;
    var invalid_selector:Bool;
    var document:Dynamic;
    var result:Dynamic;
    var results:Array<Dynamic>;
}