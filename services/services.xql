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
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xh="http://www.w3.org/1999/xhtml";
import module namespace http="http://expath.org/ns/http-client";
import module namespace config="http://gawati.org/xq/db/config" at "../modules/config.xqm";
import module namespace data="http://gawati.org/xq/db/data" at "../modules/data.xql";

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
    let $docs := data:recent-docs-full(10)
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
    %rest:produces("application/xml", "text/xml")
function services:recent-expressions-summary() {
    let $docs := data:recent-docs-summary(10)
    return
    <gwd:package  timestamp="{current-dateTime()}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:exprAbstracts orderedby="dt-updated-desc"> {
            $docs
        }</gwd:exprAbstracts>
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
    %rest:produces("application/df")
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