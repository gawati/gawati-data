xquery version "3.1";

(:
   Copyright 2017-present African Innovation Foundation

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
:)

(:~
 : This module provides JSON Endpoints for the Gawati Data server.
 : The JSON end-points are merely wrappers on the XML service end-points
 :
 : in the eXist-db server. 
 : @version 1.0alpha
 : @author Ashok Hariharan
 :)

module namespace services-json="http://gawati.org/xq/db/services-json";


declare namespace gw="http://gawati.org/ns/1.0";
declare namespace gwd="http://gawati.org/ns/1.0/data";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace xh="http://www.w3.org/1999/xhtml";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
import module namespace services="http://gawati.org/xq/db/services" at "services.xql";
import module namespace caching="http://gawati.org/xq/db/caching" at "../modules/caching.xql";

(:~
 :  This is an example service implementation, that produces JSON output instead of XML.
 :  The JSON serializer is simply a wrapper on the XML service output
 :)
declare
    %rest:GET
    %rest:path("/gw/search/languages/summary/json")
     %rest:query-param("doclang", "{$doclang}", "eng")
     %rest:query-param("count", "{$count}", "10")
     %rest:query-param("from", "{$from}", "1")
     %rest:produces("application/json")
     %output:media-type("application/json")
     %output:method("json")    
function services-json:search-languages-summary(
    $doclang as xs:string*, 
    $count as xs:string*, 
    $from as xs:string*
    ) {
    services:search-languages-summary($doclang, $count, $from)
};

declare
    %rest:GET
    %rest:path("/gw/searchAC/json")
    %rest:query-param("query", "{$query}", "Legal")
    %rest:produces("application/json")
    %output:media-type("application/json")  
    %output:method("json")    
function services-json:searchAC($query as xs:string*) {
        services:searchAC($query)
};


declare
    %rest:GET
    %rest:path("/gw/filter-cache/json")
    %rest:produces("application/json")
function services-json:filter-cache(
    ) {
    serialize(
        caching:filter-cache(), 
        <output:serialization-parameters>
            <output:method>json</output:method>
        </output:serialization-parameters>
    )
};