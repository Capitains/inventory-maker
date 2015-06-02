xquery version "3.0";

module namespace app="http://github.com/Capitains/InventoryMaker/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://github.com/Capitains/InventoryMaker/config" at "config.xqm";
import module namespace ctsh="http://github.com/Capitains/InventoryMaker/cts-helper" at "./cts.xql";

declare namespace ti="http://chs.harvard.edu/xmlns/cts";
declare namespace ti3="http://chs.harvard.edu/xmlns/cts3/ti";

declare variable $app:conf := doc("../conf/conf.xml");
declare variable $app:inventories := collection(fn:string($app:conf//repositories/@inventoryCollection));
declare variable $app:POST := request:get-data();
(:~
 : This is a sample templating function. It will be called by the templating module if
 : it encounters an HTML element with an attribute data-template="app:test" 
 : or class="app:test" (deprecated). The function has to take at least 2 default
 : parameters. Additional parameters will be mapped to matching request or session parameters.
 : 
 : @param $node the HTML node with the attribute which triggered this call
 : @param $model a map containing arbitrary data - used to pass information between template calls
 :)
declare function app:test($node as node(), $model as map(*)) {
    <p>Dummy template output generated by function app:test at {current-dateTime()}. The templating
        function was triggered by the data-template attribute <code>data-template="app:test"</code>.</p>
};

declare function app:listInventories($node as node(), $model as map(*)) {
    <select name="inventory">
        {
            for $inventory in xmldb:get-child-resources(fn:string($app:conf//repositories/@inventoryCollection))
                return element option {
                    attribute value { $inventory },
                    $inventory
                }
        }
    </select>
};

declare function app:getEnv() {
    let $status := request:get-parameter("status", "create")
    let $name := 
        if ($status = "create")
        then
            request:get-parameter("inventoryname", "new")
        else
            request:get-parameter("inventory", "")
    return 
        element conf {
            element mode {
                $status
            },
            element target {
                $name
            }
        }
};

declare function app:listResources($node as node(), $model as map(*)) {
    <ol class="cts vertical">
        {
            app:formatResources(
                app:getResources(), 
                app:getCapabilities(app:getEnv()//target/text())
            )
        }
    </ol>
};

declare function app:InventoryTitle($node as node(), $model as map(*)) {
    let $title := app:getEnv()//target/text()
    return
    element h3 {
        app:getInventoryPath($title),
        element input {
            attribute type { "hidden" },
            attribute name { "inventory" },
            attribute value { $title }
        }
    }
};

declare function app:getInventory($node as node(), $model as map(*)) {
    <ol class="cts vertical" style="min-height:10px; border:1px dashed black;">
        {
            let $conf := app:getEnv()
            return
                if ($conf//mode/text() = "create")
                then
                    ()
                else
                    app:formatResources(app:getCapabilities($conf//target/text()), ())
        
        }
    </ol>
};

declare function app:generateInventory($node as node(), $model as map(*)) {
    element div {
        element textarea {
            attribute name { "inventory" },
            ctsh:generateInventory(
                request:get-parameter("textgroup[]", ()),
                request:get-parameter("work[]", ()),
                request:get-parameter("text[]", ())
            )
        },
        element input {
            attribute type { "hidden" },
            attribute name { "inventory" },
            attribute value { request:get-parameter("inventory", "") }
        }
        
    }
    
};

declare function app:confirmInventory($node as node(), $model as map(*)) {
    <input type="submit" name="submit" class="btn btn-primary" value="Confirm edition of {request:get-parameter("inventory", "") } ?" />
};

declare function app:getInventoryPath($inventory as xs:string) {
    fn:string-join((fn:string($app:conf//repositories/@inventoryCollection), "/", $inventory))
};

declare function app:getCapabilities($inventory as xs:string) {
    let $inventory := doc(app:getInventoryPath($inventory))
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
                    for $tr in $wk/(ti:translation or ti3:translation)
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
declare function app:getResources() {
    element resources {
    for $repo in $app:conf//collection
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
declare function app:formatResources($inventory as node()*, $filter as node()*) {
    for $tg in $inventory//textgroup[count($filter[@urn = ./@urn]) = 0]
        return 
        element li {
            $tg/@urn,
            fn:string($tg/text()),
            element input {
                attribute type { "hidden" },
                attribute name { "textgroup[]" },
                attribute value { fn:string($tg/@urn) }
            },
            element ol {
                for $wk in $tg/work[count($filter[@urn = ./@urn]) = 0]
                    return 
                    element li {
                        $wk/@urn,
                        fn:string($wk/text()),
                        element input {
                            attribute type { "hidden" },
                            attribute name { "work[]" },
                            attribute value { fn:string($wk/@urn) }
                        },
                        element ol {
                            for $ed in $wk/edition[count($filter[@urn = ./@urn]) = 0]
                                return 
                                element li {
                                    $ed/@urn,
                                    fn:string-join(("Edition : ", fn:string($ed/text()))),
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
            }
        }
};