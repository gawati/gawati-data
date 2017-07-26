xquery version "3.1";

module namespace services="http://gawati.org/xq/db/services";

import module namespace config="http://gawati.org/xq/db/config" at "../modules/config.xqm";
import module namespace data="http://gawati.org/xq/db/data" at "../modules/data.xql";
declare namespace gw="http://gawati.org/ns/1.0";
declare namespace gwd="http://gawati.org/ns/1.0/data";

(: 
 : Defines all the RestXQ endpoints
 :)

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace xh="http://www.w3.org/1999/xhtml";

declare
    %rest:GET
    %rest:path("/gw/recent")
    %rest:produces("application/xml", "text/xml")
function services:recent() {
    let $docs := data:recent-docs()
    return
    <gwd:docs timestamp="{current-dateTime()}" orderedby="dt-updated-desc"> {
        data:recent-docs()
    }</gwd:docs>
};

declare
    %rest:GET
    %rest:path("/gw/index.xml")
    %rest:produces("application/xml", "text/xml")
function services:hello() {
    let $doc := doc($config:app-root || "/index.xml")
    return
        <xh:html>{$doc/xh:html/child::*}</xh:html>
};