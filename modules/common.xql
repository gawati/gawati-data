xquery version "3.1";

(:~
 : This module has data functions for retrieving AKN documents from the XML database.
 : THere is no higher processing or transformation of the documents done in this module
 : @author Ashok Hariharan
 : @version 1.0
 :)
module namespace common="http://gawati.org/xq/db/common";
declare namespace gw="http://gawati.org/ns/1.0";
declare namespace gwd="http://gawati.org/ns/1.0/data";
declare namespace an="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";
import module namespace config="http://gawati.org/xq/db/config" at "config.xqm";

declare function common:doc-collection() {
    let $sc := config:storage-config("legaldocs")
    return collection($sc("collection"))
};
