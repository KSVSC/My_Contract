pragma solidity >=0.5.2 <0.6.0;

contract SPSLS
{
    mapping(address=> uint256) public balance;
    uint fee;
    int[5][5] matrix;
    uint number_of_games;
    uint public current_number_of_players;
    uint[2] reg_time;
    uint lastchanceat;
    address payable admin;
    address adr;
    address payable [2] public players;
    uint public current_turn;
    uint public current_game;
    uint public choice1;
    uint public choice2;
    bytes32 hash1;
    bytes32 hash2;
    uint winner;
    uint public win;
    uint[3] public scoreboard;
    uint[5][5] public game_matrix;
    
    constructor() public
    {
        admin=msg.sender;
        balance[admin] = 1000;
        fee=5 ether;
        current_number_of_players=0;
        number_of_games=10;
        players[0]=0x0000000000000000000000000000000000000000;
        players[1]=0x0000000000000000000000000000000000000000;
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
        number_of_games=10;
        players[0]=0x0000000000000000000000000000000000000000;
        players[1]=0x0000000000000000000000000000000000000000;
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
        require(msg.sender!=admin,"Admin Cannot Register");
        require(current_number_of_players<2,"Room Already Full!!");
        require(msg.value==fee,"Send Exact Fee (Only Ether)");
        if(current_number_of_players==1)
            require(msg.sender!=players[0],"This address is already registered");
        
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
        require(msg.sender!=admin,"Admin Cannot use this function.");
        require(msg.sender==players[0],"Only player1 can invoke this.");
        require(current_number_of_players==1,"Cannot invoke this function.");
        require(reg_time[0] + 10 seconds < now,"Please wait for some more time.");
        players[0].transfer(fee);
        reg_time[0]=0;
        reg_time[1]=0;
        current_number_of_players=0;
        reset_to_defaults();
    }
    
    function inactivity_claim() public
    {
        require(current_number_of_players==2, "Room not full, Please wait");
        
        if(msg.sender==players[1])
        {
            if((current_game%2==1 && current_turn==0) || (current_game%2==0 && current_turn==1))
            {
                require(lastchanceat+10 seconds < now,"Too Early to Claim, please wait");
                players[1].transfer(2*fee);
                reset_to_defaults();
                reg_time[0]=0;
                reg_time[1]=0;
            current_number_of_players=0;
            }
        }
        else if(msg.sender==players[0])
        {
            if((current_game%2==1 && current_turn==1) || (current_game%2==0 && current_turn==0))
            {
                require(lastchanceat+10 seconds < now,"Too Early to Claim, please wait");
                players[0].transfer(2*fee);
                reset_to_defaults();
                reg_time[0]=0;
                reg_time[1]=0;
            current_number_of_players=0;
            }
        }
    }
    
    function play(uint ch,string memory key) public
    {
        require(current_turn==0 || current_turn==1,"Moves stored, now both Reveal Choices and select getWinner");
        require(current_number_of_players==2,"Awaiting Other Player !");
        require(msg.sender==players[0] || msg.sender==players[1],"You are not registered to play.");
        
        if(current_game%2==1 && current_turn==0)
        {
            require(msg.sender==players[0],"It is Player1's Turn !!");
            hash1=sha256(abi.encodePacked(ch,key));
            current_turn+=1;
            lastchanceat=now;
        }
        else if(current_game%2==1 && current_turn==1)
        {
            require(msg.sender==players[1],"It is Player2's Turn !!");
            hash2=sha256(abi.encodePacked(ch,key));
            current_turn+=1;
            lastchanceat=now;
        }
        else if(current_game%2==0 && current_turn==0)
        {
            require(msg.sender==players[1],"It is Player2's Turn !!");
            hash2=sha256(abi.encodePacked(ch,key));
            current_turn+=1;
            lastchanceat=now;
        }
        else if(current_game%2==0 && current_turn==1)
        {
            require(msg.sender==players[0],"It is Player1's Turn !!");
            hash1=sha256(abi.encodePacked(ch,key));
            current_turn+=1;
            lastchanceat=now;
        }

    }
    
    function reveal(uint ch,string memory key) public
    {
        bytes32 testhash;
        require(msg.sender==players[0] || msg.sender==players[1],"You are not registered to play.");
        require(current_turn==2,"Please wait for other player to commit");
        if(msg.sender==players[0])
        {
            testhash=sha256(abi.encodePacked(ch,key));
            if(testhash!=hash1)
            {
                players[1].transfer(2*fee);
                reset_to_defaults();
            }
            choice1=ch;
        }
        if(msg.sender==players[1])
        {
            testhash=sha256(abi.encodePacked(ch,key));
            if(testhash!=hash2)
            {
                players[0].transfer(2*fee);
                reset_to_defaults();
            }
            choice2=ch;
        }
    }
    
    function getWinner() public returns(uint256 w)
    {
        bool val=(msg.sender==players[0] || msg.sender==players[1]);
        require(val==true,"Only registered players allowed");
        require(choice1!=10 && choice2!=10,"Someone is still yet to reveal their choices");
        winner=game_matrix[choice1-1][choice2-1];
        win = winner;
        scoreboard[winner]++;
        
        if(current_game==number_of_games)
        {
            if(scoreboard[1]==scoreboard[2])
            {
                players[0].transfer(fee);
                players[1].transfer(fee);
            }
            else if(scoreboard[1]>scoreboard[2])
            {
                players[0].transfer(2*fee);
            }
            else
            {
                players[1].transfer(2*fee);
            }
            reg_time[0]=0;
            reg_time[1]=0;
            current_number_of_players=0;
            reset_to_defaults();
        }
        current_game++;
        current_turn=0;
        choice1=10;
        choice2=10;
        winner=3;
        
        return win;
    }
    
}