xquery version "3.0";

module namespace resource="http://github.com/Capitains/InventoryMaker/resource";

import module namespace config="http://github.com/Capitains/InventoryMaker/config" at "config.xqm";
import module namespace ctsh="http://github.com/Capitains/InventoryMaker/cts-helper" at "./cts.xql";

declare namespace ti="http://chs.harvard.edu/xmlns/cts";
declare namespace ti3="http://chs.harvard.edu/xmlns/cts3/ti";

declare variable $resource:conf := doc("../conf/conf.xml");

declare function resource:getInventoryPath($inventory as xs:string) {
    fn:string-join((fn:string($resource:conf//repositories/@inventoryCollection), "/", $inventory))
};

declare function resource:getCapabilities($inventory as xs:string) {
    let $inventory := doc(resource:getInventoryPath($inventory))
    return
    element resources {
    for $tg in $inventory//(ti:textgroup | ti3:textgroup) (: Backward compatibility :)
        return 
        element textgroup {
            attribute urn { ctsh:makeUrn($tg) },
            fn:string($tg/(ti:groupname | ti3:groupname)[1]/text()),
            for $wk in $tg/(ti:work | ti3:work)
                return 
                element work {
                    attribute urn { ctsh:makeUrn($wk) },
                    fn:string($wk/(ti:title | ti3:title)[1]/text()),
                    for $ed in $wk/(ti:edition | ti3:edition)
                        return 
                        element edition {
                            attribute urn { ctsh:makeUrn($ed) },
                            $ed/(ti:label | ti3:label)[1]/text()
                        }, 
                    for $tr in $wk/(ti:translation | ti3:translation)
                        return 
                        element translation {
                            attribute urn { ctsh:makeUrn($tr) },
                            $tr/@xml:lang,
                            $tr/(ti:label | ti3:label)[1]/text()
                        }   
                }
        }
    }
};
declare function resource:getResources() {
    element resources {
    for $repo in $resource:conf//collection
        let $collection := collection($repo/text())
        return
        for $tg in $collection//ti:textgroup
            return 
            element textgroup {
                $tg/@urn,
                fn:string($tg/ti:groupname[1]/text()),
                for $wk in $collection//ti:work[@groupUrn=$tg/@urn]
                    return 
                    element work {
                        $wk/@urn,
                        fn:string($wk/ti:title[1]/text()),
                        for $ed in $collection//ti:edition[starts-with(@urn, $wk/@urn)]
                            return 
                            element edition {
                                $ed/@urn,
                                $ed/ti:label[1]/text()
                            }, 
                        for $tr in $collection//ti:translation[starts-with(@urn, $wk/@urn)]
                            return 
                            element translation {
                                $tr/@urn,
                                $tr/@xml:lang,
                                $tr/ti:label[1]/text()
                            }   
                    }
            }
    }
};

declare function resource:formatResources($inventory as node()*, $filter as node()*) {
    for $tg in $inventory//textgroup[count($filter[@urn = ./@urn]) = 0]
        return 
        element ol {
            for $wk in $tg/work[count($filter[@urn = ./@urn]) = 0]
                return 
                element ol {
                    for $ed in $wk/edition[count($filter[@urn = ./@urn]) = 0]
                        return 
                        element li {
                            $ed/@urn,
                            fn:string-join(("Edition : ", $tg/text(), ",", $wk/text(), ",", fn:string($ed/text()))),
                            element input {
                                attribute type { "hidden" },
                                attribute name { "text[]" },
                                attribute value { fn:string($ed/@urn) }
                            }
                        }, 
                    for $tr in $wk/translation[count($filter[@urn = ./@urn]) = 0]
                        return 
                        element li {
                            $tr/@urn,
                            fn:string-join(("Translation (", fn:string($tr/@xml:lang) , "): ", fn:string($tr/text()))),
                            element input {
                                attribute type { "hidden" },
                                attribute name { "text[]" },
                                attribute value { fn:string($tr/@urn) }
                            }
                        }   
                }
            }
};