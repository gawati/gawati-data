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

declare function search:search($word as xs:string) {
    let $coll := common:doc-collection()
    let $w-word := concat($word, "*")
    return
        <searchGroups>
            <searchGroup name="keyword" label="Keyword">
            { 
              search:process-group(
                search:search-group-keyword(
                    $coll, 
                    $word, 
                    $w-word
                ),
                $word,
                $w-word
              )
            }
            </searchGroup>
            <searchGroup name="title" label="Title">
            { 
              search:process-group(
                search:search-group-title(
                    $coll, 
                    $word, 
                    $w-word
                ),
                $word,
                $w-word
              )
            }
            </searchGroup>
            <searchGroup name="country" label="Country">
            { 
              search:process-group(
                search:search-group-country(
                    $coll, 
                    $word, 
                    $w-word
                ),
                $word,
                $w-word
              )
            }
            </searchGroup>
            <searchGroup name="theme" label="Theme">
            { 
              search:process-group(
                search:search-group-theme(
                    $coll, 
                    $word, 
                    $w-word
                ),
                $word,
                $w-word
              )
            }
            </searchGroup>
            <searchGroup name="number" label="Number">
            { 
              search:process-group(
                search:search-group-number(
                    $coll, 
                    $word, 
                    $w-word
                ),
                $word,
                $w-word
              )
            }
            </searchGroup>
        </searchGroups>
};


declare function search:process-group($docs as item()*, $search as xs:string, $w-search as xs:string) {
   for $doc in $docs 
    
};

declare function search:search-group-keyword($coll as item()*, $search as xs:string, $w-search as xs:string ) {
    $coll//an:akomaNtoso[
        .//an:classification/an:keyword[
            ft:query(@showAs, $w-search) or ft:query(@value, $search)
            ]
      ]
};


declare function search:search-group-title($coll as item()*, $search as xs:string, $w-search as xs:string ) {
    $coll//an:akomaNtoso[
        .//an:publication[ft:query(@showAs, $w-search)]
      ]
};


declare function search:search-group-country($coll as item()*, $search as xs:string, $w-search as xs:string) {
    $coll//an:akomaNtoso[
       .//an:FRBRcountry[ft:query(@showAs, $search)]
      ]
};

declare function search:search-group-theme($coll as item()*, $search as xs:string, $w-search as xs:string) {
    $coll//an:akomaNtoso[
       .//an:TLCConcept[ft:query(@showAs, $word)]   
      ]
};


declare function search:search-group-number($coll as item()*, $search as xs:string, $w-search as xs:string ) {
    $coll//an:akomaNtoso[
       .//an:FRBRnumber[ft:query(@showAs, $search)]
      ]
};