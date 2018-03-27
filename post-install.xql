xquery version "3.0";

declare namespace gw="http://gawati.org/ns/1.0";
declare namespace an="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
import module namespace config="http://gawati.org/xq/db/config" at "modules/config.xqm";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

import module namespace util="http://exist-db.org/xquery/util";
import module namespace console="http://exist-db.org/xquery/console";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed :)
declare variable $target external;

declare variable $my-user := "gawatidata" ;

declare function local:change-password() {
    let $pw := replace(util:uuid(), "-", "")
    let $ret := xdb:change-user($my-user, $pw, ($my-user))
    return $pw
};

(:~
 : Convert the doc to sort into an atomic value of last modified time.
 : @param $node The document to be sorted
 :)
declare function local:sort-callback($node as node()) {
    $node//an:proprietary/gw:gawati/gw:dateTime[
                @refersTo = '#dtModified'
                ]/@datetime 
};

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

let $si := local:build-sort-index()

let $pw := local:change-password()

let $login := xdb:login($target, $my-user, $pw)

let $ret := 
    <users>
        <user name="{$my-user}" pw="{$pw}" />
    </users>
    
let $r := xdb:store($target || "/_auth", "_pw.xml", $ret) 
return $r
