xquery version "3.1";

module namespace dbauth="http://gawati.org/xq/portal/dbauth";

declare namespace xmldb="http://exist-db.org/xquery/xmldb";
import module namespace config="http://gawati.org/xq/db/config" at "./config.xqm";

(:
:   This module provides 2 functions to enable writing to the database. Default
:   eXist-db execution context is "guest", cannot write to the db using "guest".
:   call dbauth:login() before calling a statement that writes a document to the db.
:   after that call dbauth:logout() to change execution context back to guest
:
:)



(:
 : Logs in to the writable collection as specified in config:storage-config("legaldocs")
 :
 :)
declare function dbauth:login() {
    let $s-map := config:storage-config("legaldocs")
    return dbauth:login($s-map)
};

(:
 : Logs in to the writable collection as specified in the passed storage map
 :
 :)
declare function dbauth:login($s-map) {
    let $log-in := xmldb:login($s-map("db-path"), "admin", "gawati")
    return $log-in
};


declare function dbauth:logout() {
    let $s-map := config:storage-config("legaldocs")
    let $logout := dbauth:logout($s-map)
    return $logout
};

declare function dbauth:logout($s-map) {
    let $log-in := xmldb:login($s-map("db-path"), "guest", "guest")
    let $logout:=session:invalidate()
    return $logout
};
