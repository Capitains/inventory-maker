xquery version "3.0";

module namespace ctsh="http://github.com/Capitains/InventoryMaker/cts-helper";
import module namespace functx="http://www.functx.com";

declare namespace ti="http://chs.harvard.edu/xmlns/cts";
declare namespace tei="http://www.tei-c.org/ns/1.0";

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
declare function ctsh:generateInventory($invFile, $tgs, $wks, $txts) {
    let $texts := for $txt in $txts return ctsh:generateText($txt)
    let $works := ctsh:generateWork($wks, $texts)
    let $textgroups := ctsh:generateTextgroup($tgs, $works)
    return 
        element ti:TextInventory {
            attribute tiid { fn:tokenize($invFile, ".xml")[1] },
            $textgroups
        }
};

declare %private function ctsh:generateTextgroup($input as xs:string*, $texts as node()*) {
    let $urns := ($input, distinct-values($texts//@groupUrn))
    return 
        for $urn in $urns
        let $textgroup := $ctsh:collections//ti:textgroup[@urn = $urn]
        return
        element ti:textgroup {
            $textgroup/@urn,
            $textgroup/ti:groupname,
            $texts[./@groupUrn = $urn]
        }
};

declare %private function ctsh:generateWork($input as xs:string*, $texts as node()*) {
    let $urns := ($input, distinct-values($texts//@workUrn))
    return 
        for $urn in $urns
        let $work := $ctsh:collections//ti:work[@urn = $urn]
        return
        element ti:work {
            $work/@xml:lang,
            $work/@groupUrn,
            $work/@urn,
            $work/child::node()[not(local-name(.) = ("translation", "edition"))],
            $texts[./@workUrn = $urn]
        }
};

declare %private function ctsh:generateText($urn as xs:string) {
    let $texts := $ctsh:collections//(ti:edition | ti:translation)[@urn eq $urn]
    return
    for $text in $texts 
        return
        if (local-name($text) = "edition")
        then
            element ti:edition {
                $text/@workUrn,
                $text/@urn,
                $text/child::node(),
                ctsh:generateOnline(fn:string($text/@urn))
            }
        else
            element ti:translation {
                $text/@workUrn,
                $text/@urn,
                $text/child::node(),
                ctsh:generateOnline(fn:string($text/@urn))
            }
};

declare %private function ctsh:generateOnline($urn) {
    let $text := $ctsh:collections//node()[@n eq $urn][1]
    let $doc := fn:base-uri($text)
    return 
        element ti:online {
            attribute docname {
                $doc
            },
            element ti:validate {
                attribute schema { "tei-epidoc.rng" }
            },
            element ti:namespaceMapping {
                attribute abbreviation { "tei" },
                attribute nsURI { "http://www.tei-c.org/ns/1.0" }
            },
            element ti:citationMapping {
                ctsh:generateCitationMapping(fn:root($text))
            }
        }
};
declare %private function ctsh:generateCitationMapping($doc) {
    let $refs := $doc//(refsDecl | tei:refsDecl)[@id="CTS" or @n="CTS"]
    let $citations := ctsh:generateXpathScope(ctsh:sortRefPattern($refs//(cRefPattern | tei:cRefPattern)))
    return $citations
};

declare %private function ctsh:generateXpathScope($refPattern as node()*) as node()* {
    if(count($refPattern) = 0)
    then
        ()
    else
        let $node := $refPattern[1]/@replacementPattern
        let $regexp := "/+[a-zA-Z0-9:\[\]@=\\\{\$'\.]+"
        let $matches := functx:get-matches($node, $regexp)[. != ""]
        let $count := count($matches)
        let $scope := fn:subsequence($matches, 1, $count - 1)
        let $xpath := fn:subsequence($matches, $count)
        let $label := if($refPattern[1]/@n) then $refPattern[1]/@n else "unknown"
        return 
            element ti:citation {
                attribute label { $label },
                attribute xpath { ctsh:replaceReplacementPattern(fn:string-join($xpath, ""))},
                attribute scope { ctsh:replaceReplacementPattern(fn:string-join($scope, ""))},
                ctsh:generateXpathScope(fn:subsequence($refPattern, 2))
            }
};

declare %private function ctsh:replaceReplacementPattern($str) {
   fn:replace(fn:replace($str, "\\'\$[0-9]+\\'", "'?'"), "\\'", "'")
};

declare function ctsh:sortRefPattern($seq) {
    for $elem in $seq
        order by string-length(fn:string($elem/@replacementPattern))
        return $elem
};