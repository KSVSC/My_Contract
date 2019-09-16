var SPSLS = artifacts.require("SPSLS");

contract('SPSLS', function (accounts) {
    const ERROR = 'VM Exception while processing transaction: revert'

    it("Should deploy the contract in admin's account", function(){
        return SPSLS.deployed().then(function(instance){
            return instance.balance.call(accounts[0]);
        }).then(function (balance) {
            assert.equal(balance.valueOf(), 1000, "balance is not 1000");             
        });
    });

    it("Players should be able to register", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await instance.register_as_player({ from: accounts[1], value: web3.utils.toWei("5", "ether") });
                await instance.register_as_player({ from: accounts[2], value: web3.utils.toWei("5", "ether") });
                return instance.current_number_of_players.call();
            }).then(function (current_number_of_players) {
                assert.equal(current_number_of_players.valueOf(), 2, "Players registered");
            });
    }); 

    it("Game count", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                return instance.current_game.call();
            }).then(function (current_game) {
                assert.equal(current_game.valueOf(), 1, "Current game is 1st");
            });
    })

    it("Test update in turns", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await instance.play("1", "abc",{ from: accounts[1]});                
                return instance.current_turn.call();
            }).then(function (current_turn) {
                assert.equal(current_turn.valueOf(), 1, "Player1's chance completed");
            });
    })

    it("Verify choices after reveal ", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await instance.play("5", "xyz", { from: accounts[2] });
                await instance.reveal("5", "xyz", { from: accounts[2] });
                return instance.choice2.call();
            }).then(function (choice2) {
                assert.equal(choice2.valueOf(), 5, "Player2's choice revealed");
            });
    })
});