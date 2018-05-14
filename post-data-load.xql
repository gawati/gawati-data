(: Call this Script as admin :)
declare namespace gw="http://gawati.org/ns/1.0";
declare namespace an="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";

import module namespace sort="http://exist-db.org/xquery/sort";
import module namespace config="http://gawati.org/xq/db/config" at "modules/config.xqm";


(:~
 : Build a sort index for documents in the descending order of last modification
 : @returns create-index-callback always returns an empty sequence
 :)
declare function local:build-sort-index() {
    let $sc := config:storage-config("legaldocs")
    let $coll := collection($sc("collection"))
    let $node-set as document-node()+ := $coll//an:akomaNtoso/parent::node()
    let $index-id as xs:string := 'SIRecent'
    let $options := <options order="descending" empty='least'/>
    let $sort-index := sort:create-index-callback($index-id, $node-set, local:sort-callback#1, $options)
    return $sort-index
};


(:~
 : Convert the doc to sort into an atomic value of last modified time.
 : !+(FIX_THIS) dtModified has been changed to docModified in client-data
 : we need to update the data to this format. 
 : @param $node The document to be sorted
 :)
declare function local:sort-callback($node as node()) {
    $node//an:proprietary/gw:gawati/gw:dateTime[
                @refersTo = '#dtModified'
                ]/@datetime 
};

try {
    let $si := local:build-sort-index()
    return
        <success>Build Sort index</success>
} catch * {
    <error>Caught error {$err:code}: {$err:description}</error>
}


