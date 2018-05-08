xquery version "3.1";

module namespace mkc="http://exist-db.org/xquery/mkcol";

import module namespace xdb="http://exist-db.org/xquery/xmldb";


declare function mkc:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            mkc:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function mkc:mkcol($collection, $path) {
    mkc:mkcol-recursive($collection, tokenize($path, "/"))
};
