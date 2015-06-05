xquery version "3.0";

module namespace cud="http://github.com/Capitains/InventoryMaker/cud";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare variable $cud:conf := doc("../conf/conf.xml");

declare function cud:create() {
    let $data-collection := fn:string($cud:conf//repositories/@inventoryCollection)
    (: get the form data that has been "POSTed" to this XQuery :)
    let $item := request:get-parameter("inventory-doc", "")
    let $username := request:get-parameter("username", "")
    let $password := request:get-parameter("password", "")
    let $login := xmldb:login($data-collection, $username, $password)
    (: get the id out of the posted document :)
    let $file := request:get-parameter("inventory", "error.xml")
    
    let $store := 
        if ($item != "")
        then 
            let $s := xmldb:store($data-collection, $file, util:parse($item))
            return "Success"
        else "Failure"
    return $store
};