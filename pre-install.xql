xquery version "3.1";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace mkc="http://exist-db.org/xquery/mkcol" at "./mkcol.xql";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

declare function local:setup-data-index($docs-collection) {
    (: create the collection for index setup :)
    mkc:mkcol(
        "/db/system/config", 
        $docs-collection
    ), 
    (: copy the data.xconf file :)
    xdb:store-files-from-pattern(
        concat("/db/system/config", $docs-collection), 
        $dir, 
        "data.xconf"
    ),
    (: rename data.xconf to collection.xconf :)
    if (count(doc(concat("/db/system/config", $docs-collection, "/data.xconf"))) gt 0) then
        xdb:rename(
            concat("/db/system/config", $docs-collection),
            "data.xconf",
            "collection.xconf"
        ) 
    else 
        ()
};

declare function local:setup-app-index() {
    mkc:mkcol(
        "/db/system/config", 
        $target
    ),
    xdb:store-files-from-pattern(
        concat("/db/system/config", $target), 
        $dir, 
        "collection.xconf"
    )
};

let $data-folder := "gawati-data"
let $f := mkc:mkcol("/db", "docs")
let $f2 := mkc:mkcol("/db/docs", $data-folder)

(: store the collection configuration :)
return local:setup-data-index(concat("/db/docs/", $data-folder)), 
       local:setup-app-index()
