xquery version "3.1";

(:~
 : Provides access to ISO Country codes
 : @author Ashok Hariharan
 : @see https://www.loc.gov/standards/iso639-2/php/code_list.php
 :)

module namespace countries="http://gawati.org/xq/portal/countries";

declare namespace lc="http://gawati.org/portal/countries";

import module namespace config="http://gawati.org/xq/db/config" at "config.xqm";


(:~
 : Returns the name of the language, if the language code is provided in 
 : ISO 639-2 Alpha 3b format. 
 : @param $lang3 code in alpha 3b format
 : @returns the name of the language
 : alpha-2="AF" alpha-3=
 :)
declare
function countries:alpha3-to-alpha2($alpha3 as xs:string) as xs:string? {
    let $countries-doc := $config:countries-doc
    let $country := $countries-doc//lc:country[@alpha-3 eq $alpha3]
    return $country/@alpha-2
};

declare
function countries:country-name($alpha3 as xs:string) as xs:string? {
    let $countries-doc := $config:countries-doc
    let $country := $countries-doc//lc:country[@alpha-3 eq $alpha3]
    return $country/@name
};

declare
function countries:country-name-alpha2($alpha2 as xs:string) as xs:string? {
    let $countries-doc := $config:countries-doc
    let $country := $countries-doc//lc:country[@alpha-2 eq upper-case($alpha2)]
    return $country/@name
};
