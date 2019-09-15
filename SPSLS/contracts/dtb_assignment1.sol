pragma solidity ^0.4.25;

contract rpsls
{
    uint fee;
    int[5][5] matrix;
    uint number_of_games;
    uint public current_number_of_players;
    uint[2] reg_time;
    uint lastchanceat;
    address admin;
    address [2] public players;
    uint public current_turn;
    uint public current_game;
    uint public choice1;
    uint public choice2;
    bytes32 hash1;
    bytes32 hash2;
    uint public winner;
    uint[3] public scoreboard;
    uint[5][5] public game_matrix;
    
    function rpsls() public
    {
        admin=msg.sender;
        fee=5 ether;
        current_number_of_players=0;
        number_of_games=3;
        players[0]=0;
        players[1]=0;
        reg_time[0]=0;
        reg_time[1]=0;
        current_turn=0;
        current_game=1;
        game_matrix=[[0, 2, 1, 1, 2],[1, 0, 2, 2, 1],[2, 1, 0, 1, 2],[2, 1, 2, 0, 1],[1, 2, 1, 2, 0]];
        scoreboard=[0,0,0];
        choice1=10;
        choice2=10;
        winner=3;
    }
    
    function reset_to_defaults() public
    {
        current_number_of_players=0;
        number_of_games=6;
        players[0]=0;
        players[1]=0;
        reg_time[0]=0;
        reg_time[1]=0;
        current_turn=0;
        current_game=1;
        choice1=10;
        choice2=10;
        winner=3;
    }
    
    function register_as_player() public payable
    {
        require(msg.sender!=admin,"Admin Not Allowed");
        require(current_number_of_players<2,"Room Already full.");
        require(msg.value==fee,"Send exact fee only Ethers");
        if(current_number_of_players==1)
            require(msg.sender!=players[0],"You are already registered");
        
        players[current_number_of_players]=msg.sender;
        reg_time[current_number_of_players]=now;
        current_number_of_players++;
        if(current_number_of_players==2)
        {
            current_turn=0;
            current_game=1;
            lastchanceat=now;
        }
    }
    
    function p2_not_present_refund() public
    {
        require(msg.sender==players[0],"Only the player that came first can invoke this.");
        require(current_number_of_players==1,"To invoke this function, there should be only 1 player registered.");
        require(msg.sender!=admin,"Admin Cannot use this function.");
        require(reg_time[0] + 30 seconds < now,"Please wait for some more time.");
        players[0].transfer(this.balance);
        reg_time[0]=0;
        reg_time[1]=0;
        reset_to_defaults();
    }
    
    function play(uint ch,string key) public
    {
        
        require(current_number_of_players==2,"Awaiting Other Player !");
        require(msg.sender==players[0] || msg.sender==players[1],"You are not registered to play.");
        
        if(current_game%2==1 && current_turn==0)
        {
            require(msg.sender==players[0],"It is Player 1's Turn !!");
            hash1=sha256(ch,key);
            current_turn=1;
            lastchanceat=now;
        }
        else if(current_game%2==1 && current_turn==1)
        {
            require(msg.sender==players[1],"It is Player 2's Turn !!");
            hash2=sha256(ch,key);
            current_turn=2;
            lastchanceat=now;
        }
        else if(current_game%2==0 && current_turn==0)
        {
            require(msg.sender==players[1],"It is Player 2's Turn !!");
            hash2=sha256(ch,key);
            current_turn=1;
            lastchanceat=now;
        }
        else if(current_game%2==0 && current_turn==1)
        {
            require(msg.sender==players[0],"It is Player 1's Turn !!");
            hash1=sha256(ch,key);
            current_turn=2;
            lastchanceat=now;
        }
    }
    
    function reveal(uint ch,string key) public
    {
        bytes32 testhash;
        require(msg.sender==players[0] || msg.sender==players[1],"You are not registered to play.");
        require(current_turn==2,"Please wait for others to complete their turn");
        if(msg.sender==players[0])
        {
            testhash=sha256(ch,key);
            if(testhash!=hash1)
            {
                players[1].transfer(this.balance);
                reset_to_defaults();
            }
            choice1=ch;
        }
        if(msg.sender==players[1])
        {
            testhash=sha256(ch,key);
            if(testhash!=hash2)
            {
                players[0].transfer(this.balance);
                reset_to_defaults();
            }
            choice2=ch;
        }
    }
    
    function getWinner() public
    {
        require(choice1!=10 && choice2!=10,"Someone is still yet to reveal their choices");
        winner=game_matrix[choice1][choice2];
        scoreboard[winner]++;
        
        if(current_game==number_of_games)
        {
            if(scoreboard[0]==scoreboard[1])
            {
                players[0].transfer(this.balance/2);
                players[1].transfer(this.balance/2);
            }
            else if(scoreboard[0]>scoreboard[1])
            {
                players[0].transfer(this.balance);
            }
            else
            {
                players[1].transfer(this.balance);
            }
            reg_time[0]=0;
            reg_time[1]=0;
            reset_to_defaults();
        }
        current_game++;
        current_turn=0;
        choice1=10;
        choice2=10;
        winner=3;
    }
    
}
