xquery version "3.1";

(:~
 : Provides access to language codes in the  iso639-2 and 639-1 standard
 : @author Ashok Hariharan
 : @see https://www.loc.gov/standards/iso639-2/php/code_list.php
 :)

module namespace langs="http://gawati.org/xq/portal/langs";

declare namespace lc="http://gawati.org/portal/langs";

import module namespace config="http://gawati.org/xq/db/config" at "config.xqm";


(:~
 : Returns the name of the language, if the language code is provided in 
 : ISO 639-2 Alpha 3b format. 
 : @param $lang3 code in alpha 3b format
 : @returns the name of the language
 :)
declare
function langs:lang3-name($lang3 as xs:string) as xs:string? {
    let $lang-doc := $config:langs-doc
    let $lang := $lang-doc//lc:lang[@alpha3b eq $lang3]
    return
        if (not(empty($lang))) then 
            if (empty($lang/lc:desc[@lang eq $lang3])) then
              data($lang/lc:desc[@lang eq 'eng'])
            else
              data($lang/lc:desc[@lang eq $lang3])
        else
            ()
};

(:~
 : Returns the name of the language, if the language code is provided in 
 : ISO 639-2 Alpha 2 format. 
 : @param $lang2 code in alpha 2 format
 : @returns the name of the language
 :)
declare
function langs:lang2-name($lang2 as xs:string) as xs:string? {
    let $lang-doc := $config:langs-doc
    let $lang := $lang-doc//lc:lang[@alpha2 = $lang2]
    let $lang3 := $lang/@alpha3b
    return
        if (empty($lang/lc:desc[@lang = $lang3])) then
            data($lang/lc:desc[@lang = $lang3])
        else
            data($lang/lc:desc[@lang = "eng"])
};



