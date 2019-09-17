var SPSLS = artifacts.require("SPSLS");

contract('SPSLS', function (accounts) {
    const ERROR = 'VM Exception while processing transaction: revert'

    function sleep(miliseconds) {
        var currentTime = new Date().getTime();
        while (currentTime + miliseconds >= new Date().getTime()) {
        }
    }

    it("Should deploy the contract in admin's account", function(){
        return SPSLS.deployed().then(function(instance){
            return instance.balance.call(accounts[0]);
        }).then(function (balance) {
            assert.equal(balance.valueOf(), 1000, "Initial balance of admin is 1000");             
        });
    });

    it("Admin shouldn't be allowed to register", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.register_as_player({ from: accounts[0], value: web3.utils.toWei("5", "ether") });
                }
                catch (err) {
                    assert(err, "Admin Cannot Register");
                }
            });
    })

    it("Player shouldn't be allowed to register if payment is incorrect ", () => {
        return SPSLS.deployed()
            .then(async function (instance){
                try {
                    await instance.register_as_player({ from: accounts[1], value: web3.utils.toWei("3", "ether") });                    
                }
                catch (err) {
                    assert(err, "revert Send Exact Fee (Only Ether)");                  
                }
            });
    })

    it("Player1 should be able to register", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await instance.register_as_player({ from: accounts[1], value: web3.utils.toWei("5", "ether") });
                return instance.current_number_of_players.call();
            }).then(function (current_number_of_players) {
                assert.equal(current_number_of_players.valueOf(), 1, "Player1 registered");
            });
    });

    it("Players shouldn't be allowed to register twice ", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.register_as_player({ from: accounts[1], value: web3.utils.toWei("5", "ether") });
                }
                catch (err) {
                    assert(err, "This address is already registered");
                }
            });
    })

    it("Player1 can't reveal choice before Player2 registers", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.play("1", "abc", { from: accounts[1] });
                }
                catch (err) {
                    assert(err, "Awaiting Other Player !");
                }
            });
    })

    it("Admin can't invoke p2_not_present_refund function", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.p2_not_present_refund({ from: accounts[0] });
                }
                catch (err) {
                    assert(err, "Admin Cannot use this function.");
                }
            });
    });

    it("Player1 can't invoke p2_not_present_refund function before 10 sec", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.p2_not_present_refund({ from: accounts[1] });
                }
                catch (err) {
                    assert(err, "Please wait for some more time.");
                }
            });
    });

    it("Player1 can invoke p2_not_present_refund function only after 10 sec", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await sleep(12000)
                await instance.p2_not_present_refund({ from: accounts[1] });
                return instance.current_number_of_players.call();
            }).then(function (current_number_of_players) {
                assert.equal(current_number_of_players.valueOf(), 0, "Game ends. player1 wins");
            });
    });

    it("Player2 should be able to register", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await instance.register_as_player({ from: accounts[1], value: web3.utils.toWei("5", "ether") });
                await instance.register_as_player({ from: accounts[2], value: web3.utils.toWei("5", "ether") });
                return instance.current_number_of_players.call();
            }).then(function (current_number_of_players) {
                assert.equal(current_number_of_players.valueOf(), 2, "Player2 registered");
            });
    });
    
    it("Not more than two players should be allowed to register", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.register_as_player({ from: accounts[3], value: web3.utils.toWei("5", "ether") });
                }
                catch (err) {
                    assert(err, "Room Already Full!!");
                }
            });
    });

    it("Player2 can't invoke p2_not_present_refund function", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.p2_not_present_refund({ from: accounts[2]});
                }
                catch (err) {
                    assert(err, "Only player1 can invoke this");
                }
            });
    });

    it("Game count", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                return instance.current_game.call();
            }).then(function (current_game) {
                assert.equal(current_game.valueOf(), 1, "It is first game");
            });
    })

    it("Player1 is first player 'odd' games ", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.play("1", "abc", { from: accounts[2] });
                }
                catch (err) {
                    assert(err, "It is Player1's Turn !!");
                }
            });
    })

    it("Unregistered Players can't play", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.play("1", "abc", { from: accounts[3] });
                }
                catch (err) {
                    assert(err, "You are not registered to play.");
                }
            });
    })

    it("Test update in turns", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await instance.play("1", "abc",{ from: accounts[1]});                
                return instance.current_turn.call();
            }).then(function (current_turn) {
                assert.equal(current_turn.valueOf(), 1, "Player1's chance completed and its Player2's chance now");
            });
    })

    it("Player1 can't play in Player2's turn", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.play("2", "asd", { from: accounts[1] });
                }
                catch (err) {
                    assert(err, "It is Player2's Turn !!");
                }
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

    it("Players can't play next game before revealing choices and getting winner of previous game", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.play("1", "abc", { from: accounts[1] });
                }
                catch (err) {
                    assert(err, "Moves stored, now both Reveal Choices and select getWinner");
                }
            });
    })

    it("Getwinner cannot reveal the winnner before players reveal their choices", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.getWinner({ from: accounts[2] });
                }
                catch (err) {
                    assert(err, "Someone is still yet to reveal their choices");
                }
            });
    })

    it("Getwinner cannot by unregistered players", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.getWinner({ from: accounts[3] });
                }
                catch (err) {
                    assert(err, "Only registered players allowed");
                }
            });
    })

    it("Getwinner reveals the winnner ", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await instance.reveal("1", "abc", { from: accounts[1] });
                await instance.getWinner({ from: accounts[1]});
                return instance.win.call();
            }).then(function (win) {
                assert.equal(win.valueOf(), 2, "Player2 win");
            });
    })

    it("Game count Update", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                return instance.current_game.call();
            }).then(function (current_game) {
                assert.equal(current_game.valueOf(), 2, "It is Second game");
            });
    })

    it("Player2 is first player 'even' games ", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.play("3", "asd", { from: accounts[1] });
                }
                catch (err) {
                    assert(err, "It is Player2's Turn !!");
                }
            });
    })

    it("Test update in turns", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await instance.play("3", "bnm", { from: accounts[2] });
                return instance.current_turn.call();
            }).then(function (current_turn) {
                assert.equal(current_turn.valueOf(), 1, "Player2's chance completed and its Player1's chance now");
            });
    })

    it("Player can't invoke inactivity_claim before 10 sec ", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                try {
                    await instance.inactivity_claim({ from: accounts[2] });
                }
                catch (err) {
                    assert(err, "Too Early to Claim, please wait");
                }
            });
    })

    it("Player can invoke inactivity_claim only after 10 sec ", () => {
        return SPSLS.deployed()
            .then(async function (instance) {
                await sleep(12000)
                await instance.inactivity_claim({ from: accounts[2] });
                return instance.current_number_of_players.call();
            }).then(function (current_number_of_players) {
                assert.equal(current_number_of_players.valueOf(), 0, "Game ends. player2 wins");
            });
        })

});