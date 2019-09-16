var SPSLS = artifacts.require("SPSLS");

contract('SPSLS'), function(accounts){
    it("should deploy contract"), () =>{
        return SPSLS.deployed()
    }
}