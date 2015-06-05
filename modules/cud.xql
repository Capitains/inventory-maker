xquery version "3.0";

module namespace cud="http://github.com/Capitains/InventoryMaker/cud";

declare namespace request="http://exist-db.org/xquery/request";
declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare function cud:create() {
    let $data-collection := '/db/apps/inventory-maker/'
    (: get the form data that has been "POSTed" to this XQuery :)
    let $item := request:get-parameter("inventory-doc", "")
    let $login := xmldb:login($data-collection, 'admin', 'password')
    (: get the id out of the posted document :)
    let $id := "test.xml"
    let $file := 'test.xml'
    (: save the new file, overwriting the old one :)
    let $store := 
        if ($item != "")
        then 
            let $s := xmldb:store($data-collection, $file, util:parse($item))
            return "Success"
        else "Failure"
    return $store
};