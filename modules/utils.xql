xquery version "3.1";
module namespace utils="http://gawati.org/xq/portal/utils";
import module namespace functx="http://www.functx.com" at "./functx.xql";

declare function utils:is-date($date) {
    try{
        let $d := xs:date($date)    
        return true()
    } catch * {
         false()
    }

};


declare function utils:iri-upto-date-part($iri as xs:string) {
    let $arr := tokenize($iri, "/")[position() ne 1]
    let $which-is-date :=
        for $a at $pos in $arr
            return utils:is-date($a)
    return
        "/" ||
        string-join(
            $arr[
                position() le 
                    index-of($which-is-date, true())
            ],
            "/"
        )
};

declare function utils:get-filename-from-iri($iri as xs:string, $ext as xs:string) {
    let $arr := tokenize($iri, "/")[position() ne 1]
    let $filename := string-join($arr, "_")
    let $from :=	('@', '!')
    let $to :=	('', '')
    let $filename := functx:replace-multi($filename, $from, $to)
    return concat($filename, ".", $ext)
};

declare function utils:file-exists($path as xs:string) {
    if (count(util:document-name($path)) > 0) then
        true()
    else
        false()
};