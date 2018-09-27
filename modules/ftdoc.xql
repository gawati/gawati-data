xquery version "3.1";

module namespace ftdoc="http://gawati.org/xq/db/ftdoc";

declare namespace aknft="http://gawati.org/ns/1.0/content/pdf";

import module namespace common="http://gawati.org/xq/db/common" at "common.xql";

declare function ftdoc:doc(
        $this-iri as xs:string
    ) {
    let $coll := common:doc-fulltext-collection()
    let $doc := 
            $coll//aknft:pages[@connectorID eq $this-iri ]/parent::node()
     return $doc
};