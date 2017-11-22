xquery version "3.1";
(:
 Copyright 2012-present FAO / Ashok Hariharan

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
:)
(:~
:
: XQuery API to access Akoma Ntoso documents
: This library provides "API" shorthands to access
: parts of Akoma Ntoso documents. Prevents repetition
: of long XPaths, and provides a little bit of abstraction
:
: Written for AkomaNtoso 3.0 / NS:http://docs.oasis-open.org/legaldocml/ns/akn/3.0
: @author Ashok Hariharan
: @version 1.3
: Updated: 2017-11-19 - fixes to support all an doctypes correctly
:)
module namespace andoc="http://exist-db.org/xquery/apps/akomantoso30";
declare namespace an="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";

declare function andoc:root($doc as document-node()) {
    let $root := $doc/an:akomaNtoso
    return $root
};

(:
: Returns the structureal document type of the document
:) 
declare function andoc:combined-doctype-name($doc as document-node()){
    let $doctype := $doc/an:akomaNtoso/*/name()
    let $docname := $doc/an:akomaNtoso/*/@name
    return
        if ($docname)
        then $doctype || "~" || $docname
        else $doctype
};

(:
: Returns the doctype name of the structural type in a map. 
: Returns the element name and the value in the @name attribute on that
: element
:)
declare function andoc:doctype-name($doc as document-node()) {
    map {
        "doctype-element" := $doc/an:akomaNtoso/*/local-name(),
        "doctype-name" := data($doc/an:akomaNtoso/*/@name)
    }
};

declare function andoc:document-doctype-generic($doc as document-node()){
     let $root-generic := 
            $doc/an:akomaNtoso/
                (
                an:act|
                an:amendment|
                an:amendmentList|
                an:bill|
                an:debate|
                an:debateReport|
                an:doc|
                an:documentCollection|
                an:judgment|
                an:officialGazette|
                an:portion|
                an:statement
                )
      return $root-generic
};


declare function andoc:work-FRBRdate($doc as document-node()){
    let $work := andoc:FRBRWork($doc)
    return $work/an:FRBRdate
};

declare function andoc:work-FRBRdate-date($doc as document-node()){
    let $date := andoc:work-FRBRdate($doc)/@date
    return $date
};


declare function andoc:work-FRBRuri($doc as document-node()){
    let $work := andoc:FRBRWork($doc)
    let $work-uri := 
        $work/an:FRBRuri
    return $work-uri
};


declare function andoc:work-FRBRthis-value($doc as document-node()){
    let $this := andoc:work-FRBRthis($doc)
    return data($this/@value)
};

declare function andoc:work-FRBRthis($doc as document-node()){
    let $this := andoc:FRBRWork($doc)
    let $this-uri := 
        $this/an:FRBRthis
    return $this-uri
};

declare function andoc:work-FRBRthis-value($doc as document-node()){
    let $this := andoc:work-FRBRthis($doc)
    return data($this/@value)
};


declare function andoc:FRBRWork($doc as document-node()){
    let $work := andoc:identification($doc)/an:FRBRWork
    return $work
};


declare function andoc:FRBRcountry($doc as document-node()){
    let $country := andoc:FRBRWork($doc)/an:FRBRcountry
    return $country
};

declare function andoc:FRBRcountry-value($doc as document-node()){
    data(andoc:FRBRcountry($doc)/@value)
};


declare function andoc:FRBRcountry-showas($doc as document-node()){
    data(andoc:FRBRcountry($doc)/@showAs)
};


declare function andoc:expression-FRBRuri($doc as document-node()){
    let $expr := andoc:FRBRExpression($doc)
    let $expr-uri := 
        $expr/an:FRBRuri
    return $expr-uri
};

declare function andoc:expression-FRBRthis($doc as document-node()){
    let $expr := andoc:FRBRExpression($doc)
    let $expr-this := 
        $expr/an:FRBRthis
    return $expr-this
};


declare function andoc:expression-FRBRthis-value($doc as document-node()){
    andoc:expression-FRBRthis($doc)/@value
};


declare function andoc:expression-FRBRdate($doc as document-node()){
    let $expr := andoc:FRBRExpression($doc)
    return $expr/an:FRBRdate
};

declare function andoc:expression-FRBRdate-date($doc as document-node()){
    andoc:expression-FRBRdate($doc)/@date
};


declare function andoc:FRBRnumber($doc as document-node()){
    andoc:FRBRWork($doc)/an:FRBRnumber
};


declare function andoc:FRBRnumber-value($doc as document-node()){
    data(andoc:FRBRWork($doc)/an:FRBRnumber/@value)
};


declare function andoc:FRBRnumber-showas($doc as document-node()){
    data(andoc:FRBRWork($doc)/an:FRBRnumber/@showAs)
};

declare function andoc:FRBRlanguage($doc as document-node()){
    let $expr := andoc:FRBRExpression($doc)
    return $expr/an:FRBRlanguage
};

declare function andoc:FRBRlanguage-language($doc as document-node()){
    let $expr := andoc:FRBRlanguage($doc)
    return $expr/@language
};

declare function andoc:FRBRExpression($doc as document-node()){
    let $expr := andoc:identification($doc)/an:FRBRExpression 
    return $expr
};

declare function andoc:identification($doc as document-node()){
    let $ident := andoc:document-meta($doc)/an:identification 
    return $ident
};

declare function andoc:mainBody($doc as document-node()){
    let $mainbody := andoc:document-doctype-generic($doc)/(an:mainBody|an:debateBody|an:judgmentBody|an:body)
    return $mainBody
};

declare function andoc:document-meta($doc as document-node()){
    let $doc-type :=
        andoc:document-doctype-generic($doc)
    return $doc-type/an:meta        
};

(:             <references source="#nclr">
                <original eId="original" href="/akn/ke/act/1989-12-15/CAP16/eng@/main" showAs="CAP 16"/>
   :)
   
declare function andoc:references-original($doc as document-node()) {
    $doc//an:references[1]/an:original[1]
};

declare function andoc:publication($doc as document-node()) {
    let $publication := andoc:document-meta($doc)/an:publication
    return $publication
};

declare function andoc:publication-date($doc as document-node()) {
    let $publication := andoc:publication($doc)
    return data($publication/@date)
};

declare function andoc:publication-showas($doc as document-node()) {
    let $publication := andoc:publication($doc)
    return data($publication/@showAs)
};

declare function andoc:publication-name($doc as document-node()) {
    let $publication := andoc:publication($doc)
    return data($publication/@name)
};

declare function andoc:publication-number($doc as document-node()) {
    let $publication := andoc:publication($doc)
    return data($publication/@number)
};



declare function andoc:proprietary($doc as document-node()){
    let $meta := andoc:document-meta($doc)
    return $meta/an:proprietary
};


declare function andoc:docketNumber($doc as document-node()){
    let $docket-number := andoc:root($doc)//an:docketNumber[1]/text()
    return $docket-number
};

declare function andoc:docNumber($doc as document-node()){
    let $doc-number := andoc:root($doc)//an:docNumber[1]/text()
    return $doc-number
};


declare function andoc:keywords($doc as document-node()) {
    $doc//an:classification/an:keyword
};
(:
    Returns first matching docType element
:)
declare function andoc:docType($doc as document-node()) {
    let $docType := andoc:root($doc)//an:docType
    return $docType[1]
};

(:
    Returns first matching docType element with an expression filter
:)
declare function andoc:docType($doc as document-node(), $exp-filter as xs:string) {
    let $docType := andoc:root($doc)//an:docType[@eId eq $exp-filter]
    return $docType[1]
};



(:
:  GENERIC DOCUMENT FINDER FUNCTIONS
:
:)


declare function andoc:find-document(
    $coll as document-node()*, 
    $this-iri as xs:string
    ) as document-node() {
    let $doc := 
            $coll/an:akomaNtoso[
                ./an:*/an:meta/
                    an:identification[
                        ./an:FRBRExpression/
                            an:FRBRthis/@value eq $this-iri
                ]
            ]/parent::node()
     return $doc
};



(:~
    Finds a document expression matching a particular criteria
    Takes an input as sequence of document-node objects
    in eXist a collection is a sequence of document nodes. This function
    filters the collection on Expression URI and Language
    
    @coll collection of document nodes to search within
    @uri uri as string to look for in FRBRthis/@this
    @lang language code as string to look for in FRBRlanguage/@language
:)
declare function andoc:find-document(
    $coll as document-node()*, 
    $uri as xs:string, 
    $lang as xs:string
    ) as document-node() {
    let $doc := 
            $coll/an:akomaNtoso[
                ./an:*/an:meta/
                    an:identification[
                        ./an:FRBRWork/
                            an:FRBRthis/@value eq $uri
                        and
                        ./an:FRBRExpression/
                            an:FRBRlanguage/@language eq $lang
                ]
            ]/parent::node()
     return $doc
};

(:~
    Finds a document expression matching a particular criteria
    Takes an input as sequence of document-node objects
    in eXist a collection is a sequence of document nodes. This function
    filters the document on Expression URI, Language, Doc Type and Doc Name
    
    @coll collection of document nodes to search within
    @uri uri as string to look for in FRBRthis/@this
    @lang language code as string to look for in FRBRlanguage/@language
    @doctype is the Akoma Ntoso document type name
    @docname is the value of the @name attribute set in the Akoma Ntoso docType element
:)
declare function andoc:find-document(
    $coll as document-node()*, 
    $uri as xs:string, 
    $lang as xs:string,
    $doctype as xs:string,
    $docname as xs:string
    ) as document-node() {
    let $doc := 
            $coll/an:akomaNtoso[
                ./an:*[name() eq $doctype][@name eq $docname]/an:meta/
                    an:identification[
                        ./an:FRBRWork/
                            an:FRBRthis/@value eq $uri
                        and
                        ./an:FRBRExpression/
                            an:FRBRlanguage/@language eq $lang
                ]
            ]/parent::node()
     return $doc
};
