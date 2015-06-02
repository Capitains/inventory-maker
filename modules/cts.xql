xquery version "3.0";

module namespace ctsh="http://github.com/Capitains/InventoryMaker/cts-helper";

declare namespace ti="http://chs.harvard.edu/xmlns/cts";

declare variable $ctsh:conf := doc("../conf/conf.xml");
declare variable $ctsh:collections := for $path in $ctsh:conf//collection/text() return collection($path);

declare function ctsh:makeUrn($element as node()) {
    if ($element/@urn)
    then
        fn:string($element/@urn)
    else (: CTS 3 :)
        "urn:cts:" || fn:string-join(ctsh:makeUrnCTS3($element), ".")
};
declare %private function ctsh:makeUrnCTS3($element as node()) as xs:string* {
    let $current := $element/name()
    return 
    if ($current = "textgroup")
    then 
        (fn:string($element/@projid))
    else
        if ($current = "work")
        then
            ($element/ancestor::node()[name(.) = "textgroup"], ctsh:splitProjid($element/@projid))
        else
            ($element/ancestor::node()[name(.) = "work"], ctsh:splitProjid($element/@projid))
};

declare %private function ctsh:splitProjid($projid) as xs:string {
   fn:tokenize(fn:string($projid), "/")[fn:last()]
};

(: Collate textgroups first
 : Then works
 : Then edition so we can filter out as we go
 :  :)
declare function ctsh:generateInventory($tgs, $wks, $txts) {
    let $tgsnodes := for $tg in $tgs return ctsh:generateTextgroup($tg)
    return $tgsnodes
};

declare %private function ctsh:generateTextgroup($urn as xs:string) {
    let $textgroup := $ctsh:collections//ti:textgroup[@urn = $urn]
    return 
    element ti:textgroup {
        $textgroup/@*[not(name(.) = ("projid"))],
        $textgroup/child::node(),
        ctsh:generateWork($urn, ())
    }
};

declare %private function ctsh:generateWork($urn as xs:string, $filter as node()*) {
    let $works := $ctsh:collections//ti:work[starts-with(@urn, $urn)]
    return 
        for $work in $works
        return
        element ti:work {
            $work/@*[not(name(.) = ("projid"))],
            $work/child::node()[not(local-name(.) = ("translation", "edition"))],
            ctsh:generateText(fn:string($work/@urn), ())
        }
};

declare %private function ctsh:generateText($urn as xs:string, $filter as node()*) {
    let $texts := $ctsh:collections//(ti:edition | ti:translation)[starts-with(@urn, $urn)]
    return
    for $text in $texts 
        return
        if (name($text) = "edition")
        then
            element ti:edition {
                $text/@*[not(name(.) = ("workUrn", "projid"))],
                attribute workUrn { $urn },
                $text/child::node()
            }
        else
            element ti:translation {
                $text/@*[not(name(.) = ("workUrn", "projid"))],
                attribute workUrn { $urn },
                $text/child::node(),
                ctsh:generateOnline(fn:string($text/@urn))
            }
};

declare %private function ctsh:generateOnline($urn) {
    let $texts := $ctsh:collections//node()[@n = $urn]
    (:let $doc := fn:document-uri($text):)
    return 
        element ti:online {
            (:attribute docname {
                $doc
            },:)
            for $text in $texts return element docname { fn:base-uri($text) }
        }
};