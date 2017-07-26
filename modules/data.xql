xquery version "3.1";

module namespace data="http://gawati.org/xq/db/data";
declare namespace akn="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
declare namespace gw="http://gawati.org/ns/1.0";

import module namespace config="http://gawati.org/xq/db/config" at "config.xqm";

declare function data:recent-docs() {
    let $sc := config:storage-config("legaldocs")
    let $coll := collection($sc("collection"))
    let $docs := $coll//akn:akomaNtoso
    return
        for $doc in $docs
            order by $doc//akn:proprietary/gw:gawati/gw:dateTime[
                @refersTo = '#dtUpdated'
                ]/@datetime 
            descending
        return $doc   
};

