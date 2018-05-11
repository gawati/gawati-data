xquery version "3.1";

(:~
 : This module has data functions for retrieving AKN documents from the XML database.
 : THere is no higher processing or transformation of the documents done in this module
 : @author Ashok Hariharan
 : @version 1.0
 :)
module namespace caching="http://gawati.org/xq/db/caching";
declare namespace gw="http://gawati.org/ns/1.0";
declare namespace gwd="http://gawati.org/ns/1.0/data";
declare namespace an="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";

import module namespace config="http://gawati.org/xq/db/config" at "config.xqm";
import module namespace andoc="http://exist-db.org/xquery/apps/akomantoso30" at "akomantoso.xql";
import module namespace countries="http://gawati.org/xq/portal/countries" at "countries.xql";
import module namespace langs="http://gawati.org/xq/portal/langs" at "langs.xql";

declare function local:doc-collection() {
    let $sc := config:storage-config("legaldocs")
    return collection($sc("collection"))
};

declare function caching:filter-cache() {
    let $docs := local:doc-collection()//an:akomaNtoso
    return
        <filters timestamp="{string(current-dateTime())}">
            <filter name="countries" label="Countries"> {
              
            for $doc in $docs
              group by $country := data($doc//an:FRBRcountry/@value)
              order by $country ascending
              return <country code="{$country}" count="{count($doc)}" >
                       {countries:country-name-alpha2($country)}
                      </country>              
            } 
            </filter>
            <filter name="langs" label="Languages">
            {
            for $doc in $docs
              group by $lang := data($doc//an:FRBRlanguage/@language)
              order by $lang ascending
              return <lang code="{$lang}" count="{count($doc)}" >{langs:lang3-name($lang)}</lang>
            }                
            </filter>
            <filter name="years" label="Years">
                {
                for $doc in $docs
                  group by $year := year-from-date($doc//an:FRBRExpression/an:FRBRdate/@date)
                  order by $year descending
                  return <year year="{$year}" count="{count($doc)}" ></year>
                }
            </filter>
            <filter name="keywords" label="Subjects">
                {
                for $kw in $docs//an:classification/an:keyword
                let $kw-shows := $kw/@showAs
                  group by $kwv := data($kw/@value)
                  order by $kwv ascending
                  return <keyword value="{$kwv}" count="{count($kw)}" >{$kw-shows[1]}</keyword>
                }                
                            
            </filter>  
             <filter name="types" label="Document Types"> {
              
            for $doc in $docs
              group by $type := data($doc//
              (
                an:act|
                an:amendment|
                an:amendmentList|
                an:bill|
                an:debate|
                an:debateReport|
                an:doc|
                an:documentCollection|
                an:judgment|
                an:officialGazette|
                an:portion|
                an:statement
                )
                /@name)
              order by $type ascending
              return <type type="{$type}" count="{count($doc)}" />             
            }</filter>
        </filters>

};