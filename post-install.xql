xquery version "3.0";

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

let $pw := local:change-password()

let $ret := 
    <users>
        <user name="{$my-user}" pw="{$pw}" />
    </users>
let $r := xdb:store($target || "/_auth", "_pw.xml", $ret) 
return $r
