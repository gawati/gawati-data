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
                    $w-word
                ),
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
                    $w-word
                ),
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
                    $w-word
                ),
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
                    $w-word
                ),
                "theme",
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
                    $w-word
                ),
                "number",
                $word,
                $w-word
              )
            }
            </gwd:searchGroup>
        </gwd:searchGroups>
};


declare function search:process-group($docs as item()*, $group-name as xs:string, $search as xs:string, $w-search as xs:string) {
   for $doc at $pos in $docs[position() = 1 to 5]
    return
        search:process-result($doc, $group-name, $search, $w-search, $pos)
};


declare function search:process-result($doc as item()*, $group-name as xs:string, $search as xs:string, $w-search as xs:string, $pos as xs:integer) {
    <gwd:searchResult sid="{$group-name}-{$pos}" >
        {data:summary-doc($doc) }
    </gwd:searchResult>
};

declare function search:search-group-keyword($coll as item()*, $search as xs:string, $w-search as xs:string ) {
    $coll//an:akomaNtoso[
        .//an:classification/an:keyword[
            contains(@showAs, $w-search) or contains(@value, $search)
            ]
      ]/parent::node()
};


declare function search:search-group-title($coll as item()*, $search as xs:string, $w-search as xs:string ) {
    $coll//an:akomaNtoso[
        .//an:publication[contains(@showAs, $w-search)]
      ]/parent::node()
};


declare function search:search-group-country($coll as item()*, $search as xs:string, $w-search as xs:string) {
    $coll//an:akomaNtoso[
       .//an:FRBRcountry[contains(@showAs, $search)]
      ]/parent::node()
};

declare function search:search-group-theme($coll as item()*, $search as xs:string, $w-search as xs:string) {
    $coll//an:akomaNtoso[
       .//an:TLCConcept[contains(@showAs, $w-search)]   
      ]/parent::node()
};


declare function search:search-group-number($coll as item()*, $search as xs:string, $w-search as xs:string ) {
    $coll//an:akomaNtoso[
       .//an:FRBRnumber[ft:query(@showAs, $search)]
      ]/parent::node()
};