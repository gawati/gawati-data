xquery version "3.1";

(:~
 : This module has data functions for retrieving AKN documents from the XML database.
 : THere is no higher processing or transformation of the documents done in this module
 : @author Ashok Hariharan
 : @version 1.0
 :)
module namespace data="http://gawati.org/xq/db/data";
declare namespace gw="http://gawati.org/ns/1.0";
declare namespace gwd="http://gawati.org/ns/1.0/data";
declare namespace an="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";

import module namespace config="http://gawati.org/xq/db/config" at "config.xqm";
import module namespace andoc="http://exist-db.org/xquery/apps/akomantoso30" at "akomantoso.xql";



declare function data:doc($this-iri as xs:string) {
    let $coll := local:doc-collection()
    return andoc:find-document($coll, $this-iri)
};

(:~
 : Returns the 'n' most recent documents in the System as per updated date
 : @param $count integer value indicating max number of documents to return
 : @returns gwd envelop with upto 'n' AKN documents
 :)
declare function data:recent-docs-full($count as xs:integer) {
    (: call the HOF :)
    let $func := local:full-doc#1
    return
        local:recent-docs($func, $count)
};

(:~
 : Returns the summary of 'n' most recent documents in the Systme as per updated date
 : @param $count integer value indicating max number of documents to return
 : @returns gwd envelope with upto 'n' AKN document summaries
 :)
declare function data:recent-docs-summary($count as xs:integer) {
    (: call the HOF :)
    let $func := data:summary-doc#1
    return
        local:recent-docs($func, $count)
};

(:~
 : Returns documents grouped by Work, returns the 10 most recent works, 
 : and within that all the expressions ordered by date, newest first.
 : @param $count integer value indicating max number of works to return
 : @returns gwd envelope with upto 'n' AKN Works, and within each work its expressions
 :)
declare function data:recent-works($count as xs:integer) {
  let $sc := config:storage-config("legaldocs")
    let $coll := collection($sc("collection"))
    let $docs := $coll//an:akomaNtoso/parent::node()
    (:
     : Note: !+(AH, 2017-07-26) This may cause a performance problem in the future.
     : Eventually this can be adapted into a cached index of grouped works
     : built by a back-end trigger, which means we don't do the group by dynamically
     :)
    let $by-works :=
        for $works in $docs
            let $work-this := $works//an:FRBRWork/an:FRBRthis/@value
            group by $work-this
            order by $works//an:FRBRWork/an:FRBRdata/@date descending
            return
               <gwd:work iri="{$work-this}" ordered-by="dt-expr-date-desc"> {
                    for $expr in $works
                     order by $expr//an:FRBRExpression/an:FRBRdate/@date descending
                     return
                       data:summary-doc($expr)
               }</gwd:work>
     return
        for $work in subsequence($by-works,1, $count) 
            return
                $work
};

declare function local:get-thumbnail-name($doc) {
   "th_" || 
   replace(
    substring-before(util:document-name($doc), ".xml"),
    "@", 
    ""
    ) || 
   ".png"
};

(:~
 : 
 :
 :
 :)
declare 
function data:get-component-pdf($iri as xs:string) {
    let $doc := data:doc($iri)
    let $folder := util:collection-name($doc)
    let $doc-name :=  data:get-embedded-pdf-name($doc)
    return
        if (util:binary-doc-available($folder || "/" || $doc-name)) then
            util:binary-doc($folder || "/" || $doc-name)
        else
            ()
};

declare 
%private 
function 
data:get-embedded-pdf-name($doc) {
    let $component := $doc//an:body/an:book/an:componentRef[@alt]
    let $file := data($component/@alt)    
    return $file
};


declare function data:get-thumbnail($iri as xs:string) {
    let $doc := data:doc($iri)
    let $folder := util:collection-name($doc)
    let $th-name := local:get-thumbnail-name($doc)
    return
        if (util:binary-doc-available($folder || "/" || $th-name)) then
            util:binary-doc($folder || "/" || $th-name)
        else
            ()
};


declare function data:thumbnail-available($doc) {
    let $folder := util:collection-name($doc)
    let $th-name := local:get-thumbnail-name($doc)
    return
        util:binary-doc-available($folder || "/" || $th-name)
};

(:~
 : This function is simply a higher order function to 
 : return the document as is. This is in the local namespace
 : not visible to external libraries
 : @see http://exist-db.org/exist/apps/wiki/blogs/eXist/HoF
 : @param $doc AKN document
 : @returns the same input AKN document
 :)
declare function local:full-doc($doc) {
    $doc
};


(:~
 : This function is called as a higher order function 
 : from data:recent-docs(), and returns a summary of the AKN document
 : @param AKN document
 : @returns Summary of the document metadta in a gwd envelope
 :)
declare function data:summary-doc($doc) {
    let $frbrnumber := andoc:FRBRnumber($doc)
    let $th-available := 
        if (data:thumbnail-available($doc)) then
            "true"
        else
            "false"
    return
    <gwd:exprAbstract expr-iri="{andoc:expression-FRBRthis-value($doc)}"
        work-iri="{andoc:work-FRBRthis-value($doc)}" >
        <gwd:date name="work" value="{andoc:work-FRBRdate-date($doc)}" />
        <gwd:date name="expression" value="{andoc:expression-FRBRdate-date($doc)}" />
        <gwd:country value="{andoc:FRBRcountry($doc)/@value}" />
        <gwd:language value="{andoc:FRBRlanguage-language($doc)}" />
        <gwd:publishedAs>{andoc:publication-showas($doc)}</gwd:publishedAs>
        <gwd:number value="{$frbrnumber/@value}">{$frbrnumber/@showAs}</gwd:number>
        <gwd:componentLink value="{$doc//an:book[@refersTo='#mainDocument']/an:componentRef/@src}" />
        <gwd:thumbnailPresent value="{$th-available}" />
     </gwd:exprAbstract>
};


(:~
 : Private function that retrieves AKN documents. How these documents are returned
 : is upto the higher order function passed in as parameter 1. 
 : @param $func higher order function that accepts an AKN document as a parameter
 : @param $count max number of documents to return
 : @returns processed output as defined by the higher order function
 :)
declare function local:recent-docs($func, $count as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll := collection($sc("collection"))
    let $docs := $coll//an:akomaNtoso/parent::node()
    return
        for $doc in subsequence($docs, 1, $count)
            order by $doc//an:proprietary/gw:gawati/gw:dateTime[
                @refersTo = '#dtUpdated'
                ]/@datetime 
            descending
        return $func($doc) 
};


declare function local:doc-collection() {
    let $sc := config:storage-config("legaldocs")
    return collection($sc("collection"))
};

