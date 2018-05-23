xquery version "3.1";

(:~
 : This module functions for running full text and range searches
 : @author Ashok Hariharan
 : @version 1.0
 :)
module namespace search="http://gawati.org/xq/db/search";
declare namespace gw="http://gawati.org/ns/1.0";
declare namespace gwd="http://gawati.org/ns/1.0/data";
declare namespace an="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
import module namespace common="http://gawati.org/xq/db/common" at "common.xql";
import module namespace data="http://gawati.org/xq/db/data" at "data.xql";

(:~
 : 2017-28-10
 :      - performance tuning, used subsequence() at the individual query level instead of [position() = 1 to 5]
 :      - split [contains(@showAs, $x) or contains(@value, $x)] into 2 queries which are unioned since index 
 :         coverage is better
 :      - modified index configs after monex index profiling
 :)

(:~
 : Expanded Search for Category.
 :)
 
declare function search:search-category($word as xs:string, $category as xs:string, $count as xs:integer, $from as xs:integer) {
    let $coll := common:doc-collection()
    let $w-word := concat($word, "*")
    let $group-results := 
        switch ($category) 
          case "keyword" return search:search-group-keyword($coll, $word, $w-word, $from, $count)
          case "title" return search:search-group-title($coll, $word, $w-word, $from, $count)
          case "country" return search:search-group-country($coll, $word, $w-word, $from, $count)
          case "theme" return search:search-group-theme($coll, $word, $w-word, $from, $count)
          case "number" return search:search-group-number($coll, $word, $w-word, $from, $count)
          default return ""
          
    return
        <gwd:searchGroup name="{$category}" label="{$category}" 
                            records="{$group-results('records')}"
                            pagesize="{$group-results('page-size')}"
                            itemsfrom="{$group-results('items-from')}"
                            totalpages="{$group-results('total-pages')}" 
                            currentpage="{$group-results('current-page')}">
            { 
              search:process-group(
                $group-results('data'),
                $category,
                $word,
                $w-word
              )
            }
        </gwd:searchGroup>
};


(:~
 : Main Search entry point function
 :)
declare function search:search($word as xs:string) {
    let $coll := common:doc-collection()
    let $w-word := concat($word, "*")
    return
        <gwd:searchGroups>
            <gwd:searchGroup name="keyword" label="Keyword">
            { 
              search:process-group(
                search:search-group-keyword(
                    $coll, 
                    $word, 
                    $w-word,
                    1,
                    5
                )('data'),
                "keyword",
                $word,
                $w-word
              )
            }
            </gwd:searchGroup>
            <gwd:searchGroup name="title" label="Title">
            { 
              search:process-group(
                search:search-group-title(
                    $coll, 
                    $word, 
                    $w-word,
                    1,
                    5
                )('data'),
                "title",
                $word,
                $w-word
              )
            }
            </gwd:searchGroup>
            <gwd:searchGroup name="country" label="Country">
            { 
              search:process-group(
                search:search-group-country(
                    $coll, 
                    $word, 
                    $w-word,
                    1,
                    5
                )('data'),
                "country",
                $word,
                $w-word
              )
            }
            </gwd:searchGroup>
            <gwd:searchGroup name="theme" label="Theme">
            { 
              search:process-group(
                search:search-group-theme(
                    $coll, 
                    $word, 
                    $w-word,
                    1,
                    5
                )('data'),
                "theme",
                $word,
                $w-word
              )
            }
            </gwd:searchGroup>
            <gwd:searchGroup name="ftsearch" label="Full text search">
            { 
               search:process-group(
                data:coll-fulltext-search($word),
                "ftsearch",
                $word,
                $w-word
              )
              
            }
            </gwd:searchGroup>
            <gwd:searchGroup name="number" label="Number">
            { 
              search:process-group(
                search:search-group-number(
                    $coll, 
                    $word, 
                    $w-word,
                    1,
                    5
                )('data'),
                "number",
                $word,
                $w-word
              )
            }
            </gwd:searchGroup>
        </gwd:searchGroups>
};


declare function search:process-group($docs as item()*, $group-name as xs:string, $search as xs:string, $w-search as xs:string) {
   for $doc at $pos in $docs
    return
        search:process-result($doc, $group-name, $search, $w-search, $pos)
};


declare function search:process-result($doc as item()*, $group-name as xs:string, $search as xs:string, $w-search as xs:string, $pos as xs:integer) {
    <gwd:searchResult sid="{$group-name}-{$pos}" >
        {data:summary-doc($doc) }
    </gwd:searchResult>
};

declare function search:get-results-map($total-matches as xs:integer, $count as xs:integer, $from as xs:integer, $all-matches as item()*) {
    if ($total-matches gt 0) then 
        map {
            "records" := $total-matches,
            "page-size" := $count,
            "items-from" := $from,                    
            "total-pages" := ceiling($total-matches div $count) ,
            "current-page" := xs:integer($from div $count) + 1,
            "data" := subsequence($all-matches, $from, $count)
        }
    else
        map {
            "records" := 0,
            "page-size" := 0,
            "total-pages" := 0,
            "data" := ()
        }
};

declare function search:search-group-keyword($coll as item()*, $search as xs:string, $w-search as xs:string, $from as xs:integer, $count as xs:integer ) {
    let $all-matches := $coll//an:akomaNtoso[
                            .//an:classification/an:keyword[
                                contains(@showAs, $w-search)
                                ]
                          ]/parent::node()
                          union
                        $coll//an:akomaNtoso[
                            .//an:classification/an:keyword[
                                contains(@value, $search)
                                ]
                          ]/parent::node()
    
    let $total-matches := count($all-matches)
    return search:get-results-map($total-matches, $count, $from, $all-matches)
};


declare function search:search-group-title($coll as item()*, $search as xs:string, $w-search as xs:string, $from as xs:integer, $count as xs:integer ) {
    let $all-matches := $coll//an:akomaNtoso[
                            .//an:publication[contains(@showAs, $w-search)]
                          ]/parent::node()
    let $total-matches := count($all-matches)
    return search:get-results-map($total-matches, $count, $from, $all-matches)
};


declare function search:search-group-country($coll as item()*, $search as xs:string, $w-search as xs:string, $from as xs:integer, $count as xs:integer) {
    let $all-matches := $coll//an:akomaNtoso[
                           .//an:FRBRcountry[contains(@showAs, $search)]
                          ]/parent::node()
    let $total-matches := count($all-matches)
    return search:get-results-map($total-matches, $count, $from, $all-matches)
};

declare function search:search-group-theme($coll as item()*, $search as xs:string, $w-search as xs:string, $from as xs:integer, $count as xs:integer) {
    let $all-matches := $coll//an:akomaNtoso[
                           .//an:TLCConcept[contains(@showAs, $w-search)]   
                          ]/parent::node()
    let $total-matches := count($all-matches)
    return search:get-results-map($total-matches, $count, $from, $all-matches)
};


declare function search:search-group-number($coll as item()*, $search as xs:string, $w-search as xs:string, $from as xs:integer, $count as xs:integer ) {
    let $all-matches := $coll//an:akomaNtoso[
                           .//an:FRBRnumber[contains(@showAs, $search)]
                          ]/parent::node()
    let $total-matches := count($all-matches)
    return search:get-results-map($total-matches, $count, $from, $all-matches)
};