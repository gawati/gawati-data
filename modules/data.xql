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
declare namespace gft="http://gawati.org/ns/1.0/content/pdf";
declare namespace an="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";

import module namespace config="http://gawati.org/xq/db/config" at "config.xqm";
import module namespace andoc="http://exist-db.org/xquery/apps/akomantoso30" at "akomantoso.xql";
import module namespace common="http://gawati.org/xq/db/common" at "common.xql";
import module namespace langs="http://gawati.org/xq/portal/langs" at "langs.xql";

declare function data:doc($this-iri as xs:string) {
    let $coll := common:doc-collection()
    return andoc:find-document($coll, $this-iri)
};


(:~
 : Returns the Page IDs of a given document containing the search term
 : @param $this-iri the expression-this iri of the document
 : @params $term search term to look for in the document
 : @returns Page IDs containing the search term
 :)
declare function data:doc-fulltext-search($this-iri as xs:string, $term as xs:string) {
    let $coll := common:doc-fulltext-collection()
    let $lucene_query :=
    <query>
        <phrase slop="3">{$term}</phrase>
    </query>
    let $lucene_pageIDs := $coll//gft:pages[@connectorID eq $this-iri]/gft:page[ft:query(., $lucene_query)]
    let $ngram_pageIDs := $coll//gft:pages[@connectorID eq $this-iri]/gft:page[ngram:contains(., $term)]
    
    let $pageIDs := (data($lucene_pageIDs/@id), data($ngram_pageIDs/@id))

    return fn:distinct-values($pageIDs)
};

(:~
 : Returns the akn documents containing the search term
 : @params $term search term to look for in the document
 : @returns akn docs containing the search term
 :)
declare function data:coll-fulltext-search($term as xs:string) {
    let $coll := common:doc-fulltext-collection()
    let $lucene_query :=
    <query>
        <phrase slop="3">{$term}</phrase>
    </query>
    let $search-result-docs :=
        for $doc in $coll//gft:pages
            let $connectorID := data($doc/@connectorID)
            let $lucene_pageIDs := $doc/gft:page[ft:query(., $lucene_query)]
            let $ngram_pageIDs := $doc/gft:page[ngram:contains(., $term)]
            let $pageIDs := (data($lucene_pageIDs/@id), data($ngram_pageIDs/@id))
            let $distinct := fn:distinct-values($pageIDs)
            return
                if (empty($distinct)) then
                    ()
                else
                    data:doc($connectorID)
     return subsequence($search-result-docs, 1, 5)
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

(:~
 : This API is used by a SERVER side api, not meant for client consumption. Allows 
 : sending constructed XQueries to the data server. The constructed query is executed within
 : a collection context XPath. 
 : @param $count integer value indicating max number of documents to return
 : @param $from from where to start returning the documents
 : @param $qry the constructed XQuery
 : @returns gwd envelop with upto 'n' AKN documents
 :)
declare function data:search-filter($count as xs:integer, $from as xs:integer, $qry as xs:string) {
    (: This is the higher order function to be passed to the search api, it generates the abstract :)
    let $func := data:summary-doc#1
    return
        local:search-filter-docs($func, $count, $from, $qry)
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

declare function data:search-years-summary($year as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $func := data:summary-doc#1
    return
        local:search-year-docs($func, $year, $count, $from)
};

declare function data:search-keywords-summary($kw as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $func := data:summary-doc#1
    return
        local:search-keyword-docs($func, $kw, $count, $from)
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
    let $component := $doc//(an:body|an:debateBody|an:mainBody|an:judgmentBody)/an:book/an:componentRef[@alt]
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
    let $pdfname := $doc//an:book[@refersTo='#mainDocument']/an:componentRef/@alt
    let $pdfname-tok := tokenize($pdfname, "\.")
    let $lang-code := andoc:FRBRlanguage-language($doc)
    let $lang-name := langs:lang3-name($lang-code)
    let $thref := "th_" || string-join($pdfname-tok[1 to count($pdfname-tok) - 1], "") || ".png"
    return
    <gwd:exprAbstract expr-iri="{andoc:expression-FRBRthis-value($doc)}"
        work-iri="{andoc:work-FRBRthis-value($doc)}" xmlns:gwd="http://gawati.org/ns/1.0/data">
        <gwd:date name="work" value="{andoc:work-FRBRdate-date($doc)}" />
        <gwd:date name="expression" value="{andoc:expression-FRBRdate-date($doc)}" />
        <gwd:type name="legislation" aknType="act" />
        <gwd:country value="{andoc:FRBRcountry($doc)/@value}" >{$frbrcountry/@showAs}</gwd:country>
        <gwd:language value="{andoc:FRBRlanguage-language($doc)}" showAs="{$lang-name}" />
        <gwd:publishedAs>{andoc:publication-showas($doc)}</gwd:publishedAs>
        <gwd:number value="{$frbrnumber/@value}">{$frbrnumber/@showAs}</gwd:number>
        <gwd:componentLink src="{$doc//an:book[@refersTo='#mainDocument']/an:componentRef/@src}" value="{$doc//an:book[@refersTo='#mainDocument']/an:componentRef/@alt}" />
        <gwd:thumbnail src="{$thref}" />
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
            order by sort:index("SIRecent", $doc)
        return $doc
    let $total-docs := count($docs-in-order)
    return
        if (count($docs-in-order) lt $from) then
            (: $from is greater than the number of available docs :)
            map {
                "records" := 0,
                "total-page" := 0,
                "current-page" := 0,
                "data" := 
                    <gwd:empty>
                        <gwd:message lang="eng">
                        No documents dound
                        </gwd:message>
                    </gwd:empty>
            }    
        else
            map {
                "records" := $total-docs,
                "page-size" := $count,
                "items-from" := $from,
                "total-pages" := ceiling($total-docs div $count) ,
                "current-page" := xs:integer($from div $count) + 1,
                "data" :=
                    for $s-d in subsequence($docs-in-order, $from, $count)
                        return $func($s-d)
            }            

};

(:
 : Returns a grouped summary output of a document query.
 : DOES NOT return documents.
 : Returns an XML summary of year, and number of documents in that year
 :
 :)
declare function data:search-filter-timeline(
    $qry as xs:string
    ) {
    let $sc := config:storage-config("legaldocs")
    let $all-docs := collection($sc("collection"))//an:akomaNtoso
    let $docs := util:eval( "$all-docs" || $qry || "/parent::node()" )
    let $total-docs := count($docs)
    return
     <timeline>
        <years timestamp="{current-dateTime()}" total="{$total-docs}">{
        for $doc in $docs
            let $year := year-from-date(xs:date(andoc:expression-FRBRdate-date($doc)))
            group by $year
            order by $year
        return <year year="{$year}" count="{count($doc)}" />}
        </years>
        <countries timestamp="{current-dateTime()}" total="{$total-docs}">{
        for $doc in $docs
            let $country := data(andoc:FRBRcountry($doc)/@value)
            group by $country
            order by $country
            return <country name="{$country}" count="{count($doc)}" />
       }</countries> 
       <langs timestamp="{current-dateTime()}" total="{$total-docs}">{
       for $doc in $docs
            let $lang := data(andoc:FRBRlanguage($doc)/@language)
            group by $lang
            order by $lang
            return <language lang="{$lang}" count="{count($doc)}" />
       }</langs>
       <keywords timestamp="{current-dateTime()}" total="{$total-docs}">{
       for $doc in $docs
          for $i in (1 to count(andoc:keywords($doc)))
            let $kw := data(andoc:keywords($doc)[$i]/@value)
            group by $kw
            order by $kw
            return <key key="{$kw}" count="{count($doc)}" />
       }</keywords>
       <docType timestamp="{current-dateTime()}" total="{$total-docs}">{
       for $doc in $docs
            let $doctype := data(andoc:document-doctype-generic($doc)/@name)
            group by $doctype
            order by $doctype
            return <type type="{$doctype}" count="{count($doc)}" />
       }</docType>
     </timeline>
};

declare function local:search-filter-docs(
    $func as function(item()) as item()*, 
    $count as xs:integer, 
    $from as xs:integer, 
    $qry as xs:string
    ) {
    let $sc := config:storage-config("legaldocs")
    let $all-docs := collection($sc("collection"))//an:akomaNtoso
    let $docs := util:eval( "$all-docs" || $qry || "/parent::node()" )
    let $total-docs := count($docs)
    return
        if ($total-docs gt 0) then
            map {
                "records" := $total-docs,
                "page-size" := $count,
                "items-from" := $from,                    
                "total-pages" := ceiling($total-docs div $count) ,
                "current-page" := xs:integer($from div $count) + 1,
                "data" :=
                    for $s-d in subsequence($docs, $from, $count )
                        return $func($s-d)
            }    
        else
            (: $from is greater than the number of available docs :)
            map {
                "records" := 0,
                "total-page" := 0,
                "current-page" := 0,
                "data" := 
                    <gwd:empty>
                        <gwd:message lang="eng">
                        No documents dound
                        </gwd:message>
                    </gwd:empty>
            
            }    
};

declare function local:process-search($func as function(item()) as item()*,  $coll-context, $from as xs:integer, $count as xs:integer, $docs-str as xs:string) {
    let $docs := util:eval($docs-str)
    let $total-docs := count($docs)
    return
        if ($total-docs gt 0) then
           let $docs-in-order := 
                for $doc in $docs
                    order by $doc//an:proprietary/gw:gawati/gw:dateTime[
                            @refersTo = '#dtModified'
                        ]/@datetime 
                    descending
                return $doc
            return
                map {
                    "records" := $total-docs,
                    "page-size" := $count,
                    "items-from" := $from,                    
                    "total-pages" := ceiling($total-docs div $count) ,
                    "current-page" := xs:integer($from div $count) + 1,
                    "data" :=
                        for $s-d in subsequence($docs-in-order, $from, $count )
                            return $func($s-d)
                }    
        else
            (: $from is greater than the number of available docs :)
            map {
                "records" := 0,
                "total-page" := 0,
                "current-page" := 0,
                "data" := 
                    <gwd:empty>
                        <gwd:message lang="eng">
                        No documents dound
                        </gwd:message>
                    </gwd:empty>
            
            }
};

declare function local:search-language-docs($func, $languages as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll-context := collection($sc("collection"))
    let $languages-count := count($languages)
    let $docs-str := 
        "$coll-context//an:akomaNtoso[.//an:FRBRlanguage[" ||           
             string-join(
                for $language at $p in $languages
                    return
                      if ($p eq $languages-count) then
                        "@language = '" ||  $language  || "' " 
                      else
                         "@language = '" ||  $language  || "' or " 
             )  ||
        "]]/parent::node()"
    return local:process-search(
        $func, 
        $coll-context,
        $from, 
        $count, 
        $docs-str
        )
};

declare function local:search-country-docs($func, $countries as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll-context := collection($sc("collection"))
    let $countries-count := count($countries)
    let $docs-str := 
        "$coll-context//an:akomaNtoso[.//an:FRBRcountry[" ||           
             string-join(
                for $country at $p in $countries
                    return
                      if ($p eq $countries-count) then
                        "@value = '" ||  $country  || "' " 
                      else
                         "@value = '" ||  $country  || "' or " 
             )  ||
        "]]/parent::node()"

    return
        local:process-search(
            $func, 
            $coll-context, 
            $from, 
            $count, 
            $docs-str
        )
            
};


declare function local:search-keyword-docs($func, $kws as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll-context := collection($sc("collection"))
    let $kws-count := count($kws)
    let $docs-str := 
        "$coll-context//an:akomaNtoso[./an:*/an:meta/an:classification/an:keyword[" ||          
             string-join(
                for $kw at $p in $kws
                    return
                      if ($p eq $kws-count) then
                        "@value = '" || $kw  || "'"   
                      else
                        "@value = '" ||  $kw || "' or " 
             )  ||
        "]]/parent::node()"

     return
        local:process-search(
            $func, 
            $coll-context,
            $from, 
            $count, 
            $docs-str
        )
};


declare function local:search-year-docs($func, $years as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll-context := collection($sc("collection"))
    let $years-count := count($years)
    let $docs-str := 
        "$coll-context//an:akomaNtoso[./an:*/an:meta/an:identification/an:FRBRExpression/an:FRBRdate/@date[" ||           
             string-join(
                for $year at $p in $years
                    return
                      if ($p eq $years-count) then
                        "year-from-date(.) = " ||  $year   
                      else
                         "year-from-date(.) = " ||  $year || " or " 
             )  ||
        "]]/parent::node()"
    return
        local:process-search($func, $coll-context, $from, $count, $docs-str)    
};

declare function local:theme-docs($func, $themes as xs:string*, $count as xs:integer, $from as xs:integer) {
    let $sc := config:storage-config("legaldocs")
    let $coll-context := collection($sc("collection"))
    let $themes-count := count($themes)
    let $docs-str := 
        "$coll-context//an:akomaNtoso[.//an:classification[./an:keyword[" ||           
             string-join(
                for $theme at $p in $themes
                    return
                      if ($p eq $themes-count) then
                        "@value = '" ||  $theme  || "' " 
                      else
                         "@value = '" ||  $theme  || "' or " 
             )  ||
        "]]]/parent::node()"
    return
        local:process-search(
            $func, 
            $coll-context, 
            $from, 
            $count, 
            $docs-str
        )    
};




