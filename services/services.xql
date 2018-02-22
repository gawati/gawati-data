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
 : This module provides Service Endpoints for the Gawati Data server.
 : The services here are exposed via the RESTXQ Implementation in eXist-db 3.x.
 : You will need to enable the RESTXQ Trigger in collection.xconf for these 
 : services to be enabled, this should happen automatically when the XAR is deployed
 : in the eXist-db server. 
 : 
 : Gawati data is never accessed natively by other applications, the data access
 : is only via these services. The services are always prefixed with the <code>/gw/</code>.
 : 
 : @see http://exquery.github.io/exquery/exquery-restxq-specification/restxq-1.0-specification.html
 : @see http://exist-db.org/exist/apps/demo/examples/xforms/demo.html?restxq=/exist/restxq/
 : @see https://gist.github.com/joewiz/28dd9b8454d14b4164a0
 : @version 1.0alpha
 : @author Ashok Hariharan
 :)
module namespace services="http://gawati.org/xq/db/services";
declare namespace gw="http://gawati.org/ns/1.0";
declare namespace gwd="http://gawati.org/ns/1.0/data";
declare namespace pkg="http://expath.org/ns/pkg";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace http="http://expath.org/ns/http-client";
import module namespace config="http://gawati.org/xq/db/config" at "../modules/config.xqm";
import module namespace data="http://gawati.org/xq/db/data" at "../modules/data.xql";
import module namespace search="http://gawati.org/xq/db/search" at "../modules/search.xql";
import module namespace caching="http://gawati.org/xq/db/caching" at "../modules/caching.xql";

(:~
 : This Service provides returns the 10 most recent documents in the system. 
 : Recency is established based on Updated date (which is different from Modified date). 
 : 
 : @params none 
 : @returns full AKN documents in a gawati data envelop in descending order of updated date.
 :) 
declare
    %rest:GET
    %rest:path("/gw/recent/expressions/full")
    %rest:produces("application/xml", "text/xml")
function services:recent-expressions-full() {
    let $docs := data:recent-docs-full(10, 1)
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:aknDocs orderedby="dt-updated-desc"> {
           $docs
        }</gwd:aknDocs>
   </gwd:package>
};

(:~
 : This Service provides returns the summary of the 10 most recent documents in the system. 
 : Recency is established based on Updated date (which is different from Modified date). 
 : Example summary output is provided below. 
 :  <gwd:exprAbstracts xmlns:gwd="http://gawati.org/ns/1.0/data" orderedby="dt-updated-desc">
 :    <gwd:exprAbstract work-iri="/akn/ke/act/1989-12-15/CAP16/main" expr-iri="/akn/ke/act/1989-12-15/CAP16/eng@2009-07-23/main">
 :       <gwd:date name="work" value="1989-12-15"/>
 :       <gwd:date name="expression" value="2009-07-23"/>
 :       <gwd:country value="ke"/>
 :       <gwd:language value="eng"/>
 :       <gwd:publishedAs showAs="The Advocates Act, 1989"/>
 :       <gwd:number value="CAP16" showAs="CAP 16"/>
 :       <gwd:componentLink value="/akn/ke/act/1989-12-15/CAP16/eng@2009-07-2/main.pdf"/>
 :    </gwd:exprAbstract>
 :    (....)
 :   </gwd:exprAbstracts>
 :
 : @params none 
 : @returns metadata summary of documents in a gawati data envelop in descending order of updated date.
 :) 
declare
    %rest:GET
    %rest:path("/gw/recent/expressions/summary")
     %rest:query-param("count", "{$count}", "10")
     %rest:query-param("from", "{$from}", "1")    
    %rest:produces("application/xml", "text/xml")
function services:recent-expressions-summary($count as xs:string*, $from as xs:string*) {
    let $map-docs := data:recent-docs-summary(xs:integer($count[1]), xs:integer($from[1]))
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:exprAbstracts orderedby="dt-updated-desc"
            records="{$map-docs('records')}"
            pagesize="{$map-docs('page-size')}"
            itemsfrom="{$map-docs('items-from')}"
            totalpages="{$map-docs('total-pages')}" 
            currentpage="{$map-docs('current-page')}">
            {
                $map-docs('data')
            }
        </gwd:exprAbstracts>
    </gwd:package>
};

(:~
 :
 : This service provides support for dynamic filtered searches on the Data Service
 : The queries are constructed in the front-end, and passed to the service middle-ware
 : which constructs the XQuery and calls the data service.
 :
 : @params $count 
 : @params $from 
 : @params $q This is a query format :
 : e.g. the following is search filter by language:
 : [.//an:FRBRlanguage[ @language eq 'eng' ]]
 : and the following is is a search by country (in this case by 'burkina faso' and 'mauritania')
 : [.//an:FRBRcountry[ @value eq 'bf' or @value eq 'mr' ]]
 : queries can also be stacked:
 : [.//an:FRBRlanguage[ @language eq 'eng' ]][.//an:FRBRcountry[ @value eq 'bf' or @value eq 'mr' ]]
 :)
declare
    %rest:GET
    %rest:path("/gw/search/filter")
    %rest:query-param("count", "{$count}", "10")
    %rest:query-param("from", "{$from}", "1")
    %rest:query-param("q", "{$q}", "")
    %rest:produces("application/xml", "text/xml")
function services:search-filter($count as xs:string*, $from as xs:string*, $q as xs:string*) {
    let $map-docs := data:search-filter(xs:integer($count), xs:integer($from), $q)
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:exprAbstracts orderedby="natural" 
            records="{$map-docs('records')}"
            pagesize="{$map-docs('page-size')}"
            itemsfrom="{$map-docs('items-from')}"
            totalpages="{$map-docs('total-pages')}" 
            currentpage="{$map-docs('current-page')}"> 
            {
            $map-docs('data')
            }
        </gwd:exprAbstracts>
    </gwd:package>
};

declare
    %rest:GET
    %rest:path("/gw/search/countries/summary")
     %rest:query-param("country", "{$country}", "ke")
     %rest:query-param("count", "{$count}", "10")
     %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/xml", "text/xml")
function services:search-countries-summary($country as xs:string*, $count as xs:string*, $from as xs:string*) {
    let $map-docs := data:search-country-summary($country, xs:integer($count[1]), xs:integer($from[1]))
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:exprAbstracts orderedby="dt-updated-desc" 
            records="{$map-docs('records')}"
            pagesize="{$map-docs('page-size')}"
            itemsfrom="{$map-docs('items-from')}"
            totalpages="{$map-docs('total-pages')}" 
            currentpage="{$map-docs('current-page')}"> 
            {
            $map-docs('data')
            }
        </gwd:exprAbstracts>
    </gwd:package>
};


declare
    %rest:GET
    %rest:path("/gw/search/languages/summary")
     %rest:query-param("doclang", "{$doclang}", "eng")
     %rest:query-param("count", "{$count}", "10")
     %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/xml", "text/xml")
function services:search-languages-summary($doclang as xs:string*, $count as xs:string*, $from as xs:string*) {
    let $map-docs := data:search-language-summary($doclang, xs:integer($count[1]), xs:integer($from[1]))
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:exprAbstracts orderedby="dt-updated-desc" 
            records="{$map-docs('records')}"
            pagesize="{$map-docs('page-size')}"
            itemsfrom="{$map-docs('items-from')}"
            totalpages="{$map-docs('total-pages')}" 
            currentpage="{$map-docs('current-page')}"> 
            {
            $map-docs('data')
            }
        </gwd:exprAbstracts>
    </gwd:package>
};


declare
    %rest:GET
    %rest:path("/gw/search/keywords/summary")
     %rest:query-param("kw", "{$kw}", "Legislation")
     %rest:query-param("count", "{$count}", "10")
     %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/xml", "text/xml")
function services:search-keywords-summary($kw as xs:string*, $count as xs:string*, $from as xs:string*) {
    let $map-docs := data:search-keywords-summary(
            $kw, 
            xs:integer($count[1]), 
            xs:integer($from[1])
        )
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:exprAbstracts orderedby="dt-updated-desc" 
            records="{$map-docs('records')}"
            pagesize="{$map-docs('page-size')}"
            itemsfrom="{$map-docs('items-from')}"            
            totalpages="{$map-docs('total-pages')}" 
            currentpage="{$map-docs('current-page')}"> 
            {
            $map-docs('data')
            }
        </gwd:exprAbstracts>
    </gwd:package>
};


declare
    %rest:GET
    %rest:path("/gw/search/years/summary")
     %rest:query-param("year", "{$year}", "eng")
     %rest:query-param("count", "{$count}", "10")
     %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/xml", "text/xml")
function services:search-years-summary($year as xs:string*, $count as xs:string*, $from as xs:string*) {
    let $map-docs := data:search-years-summary($year, xs:integer($count[1]), xs:integer($from[1]))
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:exprAbstracts orderedby="dt-updated-desc" 
            records="{$map-docs('records')}"
            pagesize="{$map-docs('page-size')}"
            itemsfrom="{$map-docs('items-from')}"            
            totalpages="{$map-docs('total-pages')}" 
            currentpage="{$map-docs('current-page')}"> 
            {
            $map-docs('data')
            }
        </gwd:exprAbstracts>
    </gwd:package>
};

declare
    %rest:GET
    %rest:path("/gw/searchAC")
    %rest:query-param("query", "{$query}", "Legal")
    %rest:produces("application/xml", "text/xml")
function services:searchAC($query as xs:string*) {
    let $result-docs := search:search($query)
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        {$result-docs}
    </gwd:package>
};


declare
    %rest:GET
    %rest:path("/gw/themes/expressions/summary")
     %rest:query-param("themes", "{$themes}", "unknown")
     %rest:query-param("count", "{$count}", "10")
     %rest:query-param("from", "{$from}", "1")
    %rest:produces("application/xml", "text/xml")
function services:themes-expressions-summary($themes as xs:string*, $count as xs:string*, $from as xs:string*) {
    let $map-docs := data:theme-docs-summary($themes, xs:integer($count[1]), xs:integer($from[1]))
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:exprAbstracts orderedby="dt-updated-desc" 
            records="{$map-docs('records')}"
            pagesize="{$map-docs('page-size')}"
            itemsfrom="{$map-docs('items-from')}"            
            totalpages="{$map-docs('total-pages')}" 
            currentpage="{$map-docs('current-page')}"> 
            {
            $map-docs('data')
            }
        </gwd:exprAbstracts>
    </gwd:package>
};


(:~
 : This Service provides returns the summary of the 10 most recent Works in the system. 
 : Recency is established based on the Work date
 :
 : @params none 
 : @returns Works and their Expression documents
 :)
declare
    %rest:GET
    %rest:path("/gw/recent/works/summary")
    %rest:produces("application/xml", "text/xml")
function services:recent-works-summary() {
    let $docs := data:recent-works(10)
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:works orderedby="dt-work-date-desc"> {
            $docs
        }</gwd:works>
    </gwd:package>
};


(:~
 : Retrieves an AKoma Ntoso XML document based on its IRI
 : The expression IRI from the FRBRthis element is used to retrieve the document
 : @params $iri the expression-this iri of the document 
 : @returns REST response with the document as text/xml
 :)
declare
    %rest:GET
    %rest:path("/gw/doc")
    %rest:query-param("iri", "{$iri}", "")
    %rest:produces("application/xml", "text/xml")
function services:doc-iri($iri) {
    let $doc := data:doc($iri)
    return
       if (empty($doc)) then
            <rest:response>
                <http:response status="404">
                    <http:header name="Content-Type" value="application/xml"/>
                </http:response>
            </rest:response>
       else
            (
            <rest:response>
                <http:response status="200">
                    <http:header name="Content-Type" value="application/xml"/>
                </http:response>
            </rest:response>,
            document {$doc}
            )
};

declare
    %rest:GET
    %rest:path("/gw/doc/xml")
    %rest:query-param("iri", "{$iri}", "")
    %rest:produces("application/xml", "text/xml")
function services:doc-iri-xml($iri) {
    let $doc := data:doc($iri)
    
    return
       if (empty($doc)) then
            <gwd:package timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
                <gwd:status code="404" message="Document for IRI not found" />
            </gwd:package>
       else
            <gwd:package timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
                {document {$doc} }
            </gwd:package>
};

(:~
 : Retrieves an AKoma Ntoso XML document based on its IRI
 : The expression IRI from the FRBRthis element is used to retrieve the document
 : @params $iri the expression-this iri of the document 
 : @returns REST response with the document as text/xml
 :)
declare
    %rest:GET
    %rest:path("/gw/doc/summary")
    %rest:query-param("iri", "{$iri}", "")
    %rest:produces("application/xml", "text/xml")
function services:doc-summary-iri($iri) {
    let $doc := data:doc($iri)
    return
        <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
            { data:summary-doc($doc) }
        </gwd:package>
};



declare
    %rest:GET
    %rest:path("/gw/doc/expr-chain")
    %rest:query-param("iri", "{$iri}", "")
    %rest:produces("application/xml", "text/xml")
function services:doc-expression-chain($iri) {
    let $docs := data:get-expression-document-chain($iri)
    return
       if (empty($docs)) then
            <rest:response>
                <http:response status="404">
                    <http:header name="Content-Type" value="application/xml"/>
                </http:response>
            </rest:response>
       else
            (
            <rest:response>
                <http:response status="200">
                    <http:header name="Content-Type" value="application/xml"/>
                </http:response>
            </rest:response>,
            $docs
            )    
};

declare
    %rest:GET
    %rest:path("/gw/filter-cache")
    %rest:produces("application/xml", "text/xml")
function services:filter-cache() {
    let $doc := caching:filter-cache()
    return
       if (empty($doc)) then
            <rest:response>
                <http:response status="404">
                    <http:header name="Content-Type" value="application/xml"/>
                </http:response>
            </rest:response>
       else
            (
            <rest:response>
                <http:response status="200">
                    <http:header name="Content-Type" value="application/xml"/>
                </http:response>
            </rest:response>,
            $doc
            )    
};

(:~
 : Retrieves a thumbnail of a document as a PNG file.
 : The expression IRI from the FRBRthis element is used to retrieve 
 : the document's thumbnail ; which is named according to a particular o
 : naming convention based on the IRI.
 : @params $iri the expression-this iri of the document 
 : @returns REST response with the document as image/png
 :)
declare
    %rest:GET
    %rest:path("/gw/doc/thumbnail")
    %rest:query-param("iri", "{$iri}", "")
    %rest:produces("image/png")
    %output:media-type("image/png")
    %output:method("binary")
function services:thumbnail($iri) {
    let $doc := data:get-thumbnail($iri) 
    return
    if (not(empty($doc))) then
        ( 
        <rest:response>
          <http:response status="200" message="ok">
            <http:header name="Content-Type" value="image/png"/>
          </http:response>
        </rest:response>,
        $doc
        )
    else
        <rest:response>
            <http:response status="404">
                <http:header name="Content-Type" value="application/xml"/>
            </http:response>
        </rest:response>
};    

(:~
 : Retrieves the PDF form of a document as a pdf file.
 : The expression IRI from the FRBRthis element is used to retrieve 
 : the document's pdf ; which is named according to a particular o
 : naming convention based on the IRI.
 : @params $iri the expression-this iri of the document 
 : @returns REST response with the document as application/pdf
 :)
declare
    %rest:GET
    %rest:path("/gw/doc/pdf")
    %rest:query-param("iri", "{$iri}", "")
    %rest:produces("application/pdf")
    %output:media-type("application/pdf")
    %output:method("binary")
function services:pdf($iri) {
    let $doc := data:get-component-pdf($iri) 
    return
    if (not(empty($doc))) then
        ( 
        <rest:response>
          <http:response status="200" message="ok">
            <http:header name="Content-Type" value="application/pdf"/>
          </http:response>
        </rest:response>,
        $doc
        ) 
    else
        <rest:response>
            <http:response status="404">
                <http:header name="Content-Type" value="application/xml"/>
            </http:response>
        </rest:response>
};    

(:~
 : Searches the full text of the given IRI and returns the page number(s)
 : of the matches
 : @params $iri the expression-this iri of the document
 : @params $term search term to look for in the document
 : @returns REST response with the page numbers(s) of the matches
 :)
declare
    %rest:GET
    %rest:path("/gw/doc/search")
    %rest:query-param("iri", "{$iri}", "")
    %rest:query-param("term", "{$term}", "")
    %rest:produces("application/xml", "text/xml")
function services:search-doc($iri, $term) {
    let $doc := data:doc($iri)
    let $pages := data:doc-fulltext-search($iri, $term)
    return
    if (not(empty($pages('pages')))) then
        (
        <gwd:empty>
            <gwd:message lang="eng">
            Search term '{$term}' found in the following pages: {$pages('pages')}
            </gwd:message>
        </gwd:empty>
        )
    else
        <gwd:empty>
            <gwd:message lang="eng">
            Search term '{$term}' was not found.
            </gwd:message>
        </gwd:empty>
};

(:~
 : This is provided just to check if the RestXQ services are functioning
 : @returns XHTML document index.xml from the database
 :)
declare
    %rest:GET
    %rest:path("/gw/index.xml")
    %rest:produces("application/xml", "text/xml")
function services:home() {
    let $doc := doc($config:app-root || "/index.xml")
    return
        <xh:html>{$doc/xh:html/child::*}</xh:html>
};

(:~
 : This is provided just to check if the RestXQ services are functioning
 : @returns XHTML document index.xml from the database
 :)
declare
    %rest:GET
    %rest:path("/gw/about")
    %rest:produces("text/plain")
function services:about() {
    let $doc := doc($config:app-root || "/expath-pkg.xml")
    return
        serialize(
            "package=" || data($doc/pkg:package/@abbrev) || ";" || "version=" ||  data($doc/pkg:package/@version) || ";date=" || data($doc/pkg:package/@date) ,
            <output:serialization-parameters>
                <output:method>text</output:method>
            </output:serialization-parameters>
        )
};
