xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="http://gawati.org/xq/db/config";
declare namespace cfgx="http://gawati.org/db/config";

declare namespace templates="http://exist-db.org/xquery/templates";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

(: Folder with main configuration file :)
declare variable $config:config-root := concat($config:app-root, "/_configs");
(: Actual configuration file :)
declare variable $config:cfg-doc := doc(concat($config:config-root, "/cfgs.xml"));
(: Langs Config :)
declare variable $config:langs-doc := doc(concat($config:config-root, "/langs.xml"));
(: Langs Config :)
declare variable $config:countries-doc := doc(concat($config:config-root, "/countries.xml"));

(: Folder with XSLT scripts :)
declare variable $config:app-xslt := $config:app-root || '/xslt';


declare function config:doc() {
    $config:cfg-doc/cfgx:config
};

declare function config:xslt($filename as xs:string) {
    (: was doc() :)
    doc(concat($config:app-xslt, "/", $filename))
};


(:~
 :
 :     <storageConfigs>
 :       <storage name="legaldocs" collection="data/akn">
 :           <read id="gawatidata" p="gdata" />
 :           <write id="gawatidata" p="gdata" />
 :       </storage>
 :   </storageConfigs>
 :
 :
 :
:) 
declare function config:storage-config($name as xs:string) {
    let $sc := config:doc()//cfgx:storageConfigs/cfgx:storage[@name = $name]
    return
        map{
            "db-path" := concat("xmldb:exist://", $sc/@path),
            "collection" := concat($config:app-root, '/', $sc/@collection),
            "read-id" := data($sc/cfgx:read/@id),
            "read-p" := data($sc/cfgx:read/@p),
            "write-id" := data($sc/cfgx:write/@id),
            "write-p" := data($sc/cfgx:write/@p)
        }
};


(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
    if (starts-with($config:app-root, "/db")) then
        doc(concat($config:app-root, "/", $relPath))
    else
        doc(concat("file://", $config:app-root, "/", $relPath))
};
