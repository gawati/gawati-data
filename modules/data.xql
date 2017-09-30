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
declare function data:recent-docs-full($count as xs:integer, $from as xs:integer) {
    (: call the HOF :)
    let $func := local:full-doc#1
    return
        local:recent-docs($func, $count, $from)
};

(:~
 : Returns the summary of 'n' most recent documents in the Systme as per updated date
 : @param $count integer value indicating max number of documents to return
 : @returns gwd envelope with upto 'n' AKN document summaries
 :)
declare function data:recent-docs-summary($count as xs:integer, $from as xs:integer) {
    (: call the HOF :)
    let $func := data:summary-doc#1
    return
        local:recent-docs($func, $count, $from)
};

declare function data:search-country-summary($country as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $func := data:summary-doc#1
    return
        local:search-country-docs($func, $country, $count, $from)
};

declare function data:search-language-summary($doclang as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $func := data:summary-doc#1
    return
        local:search-language-docs($func, $doclang, $count, $from)
};


(:~
 : Returns the summary of 'n' most recent documents in the Systme as per updated date
 : @param $count integer value indicating max number of documents to return
 : @returns gwd envelope with upto 'n' AKN document summaries
 :)
declare function data:theme-docs-summary($themes as xs:string*, $count as xs:integer, $from as xs:integer) {
    (: call the HOF :)
    let $func := data:summary-doc#1
    return
        local:theme-docs(
            $func, 
            $themes, 
            $count, 
            $from
        )
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
               <gwd:work iri="{$work-this}" ordered-by="dt-expr-date-desc" xmlns:gwd="http://gawati.org/ns/1.0/data"> {
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

declare
function data:get-expression-document-chain($iri as xs:string) {
    let $sc := config:storage-config("legaldocs")
    let $coll := collection($sc("collection"))
    let $doc := data:doc($iri)
    let $work-iri := andoc:work-FRBRthis-value($doc)
    let $doc-chain := $coll//an:akomaNtoso[
            ./an:*/an:meta/
                    an:identification[
                        an:FRBRWork/
                            an:FRBRthis/@value eq $work-iri
                       ]
            ]/parent::node()
    return
         <gwd:work iri="{$work-iri}" ordered-by="dt-expr-date-ascending" xmlns:gwd="http://gawati.org/ns/1.0/data"> {
                for $item in $doc-chain
                    order by $item//an:FRBRExpression/an:FRBRdate/@date ascending
                    return data:summary-doc($item)
            }
         </gwd:work>
            
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
 : not visible to external libraries. We need this because the 
 : because the point of use is within a higher order construct
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
    let $frbrcountry := andoc:FRBRcountry($doc)
    let $th-available := 
        if (data:thumbnail-available($doc)) then
            "true"
        else
            "false"
    return
    <gwd:exprAbstract expr-iri="{andoc:expression-FRBRthis-value($doc)}"
        work-iri="{andoc:work-FRBRthis-value($doc)}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:date name="work" value="{andoc:work-FRBRdate-date($doc)}" />
        <gwd:date name="expression" value="{andoc:expression-FRBRdate-date($doc)}" />
        <gwd:country value="{andoc:FRBRcountry($doc)/@value}" >{$frbrcountry/@showAs}</gwd:country>
        <gwd:language value="{andoc:FRBRlanguage-language($doc)}" />
        <gwd:publishedAs>{andoc:publication-showas($doc)}</gwd:publishedAs>
        <gwd:number value="{$frbrnumber/@value}">{$frbrnumber/@showAs}</gwd:number>
        <gwd:componentLink value="{$doc//an:book[@refersTo='#mainDocument']/an:componentRef/@alt}" />
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
 (:
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
:)
(:~
 : Private function that retrieves AKN documents. How these documents are returned
 : is upto the higher order function passed in as parameter 1. 
 : @param $func higher order function that accepts an AKN document as a parameter
 : @param $count max number of documents to return
 : @returns processed output as defined by the higher order function
 :)
declare function local:recent-docs($func, $count as xs:integer, $from as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll := collection($sc("collection"))
    let $docs := $coll//an:akomaNtoso/parent::node()
    let $docs-in-order := 
        for $doc in $docs
            order by $doc//an:proprietary/gw:gawati/gw:dateTime[
                @refersTo = '#dtUpdated'
                ]/@datetime 
            descending
        return $doc
    let $total-docs := count($docs-in-order)
    return
        if (count($docs-in-order) lt $from) then
            (: $from is greater than the number of available docs :)
            ()
        else
            map {
            "total-pages" := ($total-docs div $count) + 1,
            "current-page" := xs:integer($from div $count) + 1,
            "data" :=
                for $s-d in subsequence($docs-in-order, $from, $count)
                    return $func($s-d)
            }            

};

declare function local:search-language-docs($func, $languages as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll := collection($sc("collection"))
    let $languages-count := count($languages)
    let $docs-str := 
        "$coll//an:akomaNtoso[.//an:FRBRlanguage[" ||           
             string-join(
                for $language at $p in $languages
                    return
                      if ($p eq $languages-count) then
                        "@language = '" ||  $language  || "' " 
                      else
                         "@language = '" ||  $language  || "' or " 
             )  ||
        "]]/parent::node()"
    let $docs := util:eval($docs-str)
    let $total-docs := count($docs)
    let $docs-in-order := 
        for $doc in $docs
            order by $doc//an:proprietary/gw:gawati/gw:dateTime[
                @refersTo = '#dtModified'
                ]/@datetime 
            descending
        return $doc
    return
        if (count($docs-in-order) lt $from) then
            (: $from is greater than the number of available docs :)
            ()
        else
            map {
            "records" := $total-docs,
            "total-pages" := xs:integer($total-docs div $count) + 1,
            "current-page" := xs:integer($from div $count) + 1,
            "data" :=
                for $s-d in subsequence($docs-in-order, $from, $count )
                    return $func($s-d)
            }    
};

declare function local:search-country-docs($func, $countries as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll := collection($sc("collection"))
    let $countries-count := count($countries)
    let $docs-str := 
        "$coll//an:akomaNtoso[.//an:FRBRcountry[" ||           
             string-join(
                for $country at $p in $countries
                    return
                      if ($p eq $countries-count) then
                        "@value = '" ||  $country  || "' " 
                      else
                         "@value = '" ||  $country  || "' or " 
             )  ||
        "]]/parent::node()"
    let $docs := util:eval($docs-str)
    let $total-docs := count($docs)
    let $docs-in-order := 
        for $doc in $docs
            order by $doc//an:proprietary/gw:gawati/gw:dateTime[
                @refersTo = '#dtModified'
                ]/@datetime 
            descending
        return $doc
    return
        if (count($docs-in-order) lt $from) then
            (: $from is greater than the number of available docs :)
            ()
        else
            map {
            "records" := $total-docs,
            "total-pages" := xs:integer($total-docs div $count) + 1,
            "current-page" := xs:integer($from div $count) + 1,
            "data" :=
                for $s-d in subsequence($docs-in-order, $from, $count )
                    return $func($s-d)
            }    
};


declare function local:theme-docs($func, $themes as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll := collection($sc("collection"))
    let $themes-count := count($themes)
    let $docs-str := 
        "$coll//an:akomaNtoso[.//an:classification[./an:keyword[" ||           
             string-join(
                for $theme at $p in $themes
                    return
                      if ($p eq $themes-count) then
                        "@value = '" ||  $theme  || "' " 
                      else
                         "@value = '" ||  $theme  || "' or " 
             )  ||
        "]]]/parent::node()"
    let $docs := util:eval($docs-str)
    let $total-docs := count($docs)
    let $docs-in-order := 
        for $doc in $docs
            order by $doc//an:proprietary/gw:gawati/gw:dateTime[
                @refersTo = '#dtModified'
                ]/@datetime 
            descending
        return $doc
    return
        if (count($docs-in-order) lt $from) then
            (: $from is greater than the number of available docs :)
            ()
        else
            map {
            "records" := $total-docs,
            "total-pages" := xs:integer($total-docs div $count) + 1,
            "current-page" := xs:integer($from div $count) + 1,
            "data" :=
                for $s-d in subsequence($docs-in-order, $from, $count )
                    return $func($s-d)
            }    
};



declare function local:doc-collection() {
    let $sc := config:storage-config("legaldocs")
    return collection($sc("collection"))
};

