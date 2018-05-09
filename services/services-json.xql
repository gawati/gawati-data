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
 : The Services from Gawati-Data output in both XML and JSON formats, 
 : you just need to attach `json` at the end to typically get the json
 : output of the XML output service
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
 : Returns a listing summary of documents in the database.
 : This API allows filtering documents by language. 
 : Called as : 
 : 
 : @param $doclang - the language of the document to filter by
 : @param $count - the number of documents to return
 : @param $from - the point at the entire listing where to start returning documents from
 : @return  the sum of $first and $second
 : @author Ashok Hariharan
 : @since 1.1
 : 
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
    %rest:path("/gw/search/years/summary/json")
    %rest:query-param("year", "{$year}", "2016")
    %rest:query-param("count", "{$count}", "10")
    %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")    
function services-json:search-years-summary($year as xs:string*, $count as xs:string*, $from as xs:string*) {
    services:search-years-summary($year, $count, $from)
};


declare
    %rest:GET
    %rest:path("/gw/search/keywords/summary/json")
    %rest:query-param("kw", "{$kw}", "Legislation")
    %rest:query-param("count", "{$count}", "10")
    %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")    
function services-json:search-keywords-summary($kw as xs:string*, $count as xs:string*, $from as xs:string*) {
    services:search-keywords-summary($kw, $count, $from)
};

declare
    %rest:GET
    %rest:path("/gw/search/countries/summary/json")
    %rest:query-param("country", "{$country}", "ke")
    %rest:query-param("count", "{$count}", "10")
    %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")    
function services-json:search-countries-summary($country as xs:string*, $count as xs:string*, $from as xs:string*) {
    services:search-countries-summary($country, $count, $from)
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
    %rest:path("/gw/themes/expressions/summary/json")
     %rest:query-param("themes", "{$themes}", "unknown")
     %rest:query-param("count", "{$count}", "10")
     %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/json")
    %output:media-type("application/json")  
    %output:method("json")  
function services-json:themes-expressions-summary($themes as xs:string*, $count as xs:string*, $from as xs:string*) {
   services:themes-expressions-summary($themes, $count, $from)
};


declare
    %rest:GET
    %rest:path("/gw/recent/expressions/summary/json")
     %rest:query-param("count", "{$count}", "10")
     %rest:query-param("from", "{$from}", "1")    
    %rest:produces("application/json")
    %output:media-type("application/json")  
    %output:method("json")  
function services-json:recent-expressions-summary($count as xs:string*, $from as xs:string*) {
    services:recent-expressions-summary($count, $from)
};


declare
    %rest:GET
    %rest:path("/gw/doc/json")
    %rest:query-param("iri", "{$iri}", "")
    %rest:produces("application/json")
    %output:media-type("application/json")  
    %output:method("json")  
function services-json:doc-iri($iri) {
   services:doc-iri-xml($iri)
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



declare
    %rest:GET
    %rest:path("/gw/filter/timeline/json")
    %rest:query-param("q", "{$q}", "")
    %rest:produces("application/json")
    %output:media-type("application/json")  
    %output:method("json")  
function services-json:filter-timeline($q as xs:string*) {
    services:filter-timeline($q)
};


declare
    %rest:GET
    %rest:path("/gw/search/filter/json")
    %rest:query-param("count", "{$count}", "10")
    %rest:query-param("from", "{$from}", "1")
    %rest:query-param("q", "{$q}", "")
    %rest:produces("application/json")
    %output:media-type("application/json")  
    %output:method("json")  
function services-json:search-filter($count as xs:string*, $from as xs:string*, $q as xs:string*) {
    services:search-filter($count, $from, $q)
};


declare
    %rest:GET
    %rest:path("/gw/doc/search/json")
    %rest:query-param("iri", "{$iri}", "")
    %rest:query-param("term", "{$term}", "")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
function services-json:search-doc($iri, $term) {
    services:search-doc($iri, $term)
};


declare
    %rest:GET
    %rest:path("/gw/search-category/json")
    %rest:query-param("term", "{$term}", "Legal")
    %rest:query-param("category", "{$category}", "keyword")
    %rest:query-param("count", "{$count}", "10")
    %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/json")
    %output:media-type("application/json")  
    %output:method("json")    
function services-json:search-category($term as xs:string*, $category as xs:string*, $count as xs:string*, $from as xs:string*) {
        services:search-category($term, $category, $count, $from)
};

declare
    %rest:POST("{$json}")
    %rest:path("/gw/doc/exists")
    %rest:produces("application/json")
    %output:media-type("application/json")  
    %output:method("json")
function services-json:exists-xml($json) {
        services:exists-xml($json)
};