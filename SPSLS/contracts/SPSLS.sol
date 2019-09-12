pragma solidity >=0.4.21 <0.6.0;

contract SPSLS{
    // mapping (int => mapping(int => int)) payoffMatrix;
    uint8[5][5] payoffMatrix;
    address player1;
    address player2;
    
    uint256 public p1_choice;
    uint256 public p2_choice;
    
    constructor() public {
        player1 = 0;
        player2 = 0;
        p2_choice = 0;
        p1_choice = 0;
    }
    
    // winner deciding matrix
    function paymatrix() public{
        payoffMatrix = [[0, 2, 1, 1, 2],[1, 0, 2, 2, 1],[2, 1, 0, 1, 2],[2, 1, 2, 0, 1],[1, 2, 1, 2, 0]];        
    }
    
    //player register
    function register() public payable playerNotRegistered() PaidEnoughCash(5 wei) {
        if (player1 == 0)
            player1 == msg.sender;
        else if (player2 == 0)
            player2 == msg.sender;
    }
    
    modifier playerNotRegistered(){
        if(msg.sender == player1 || msg.sender == player2)
            revert();
        else
            _;
    }
    
    modifier PaidEnoughCash(uint amount){
        if(msg.value < amount)
            revert();
        else
            _;
    }
    
    //game play
    function game(uint choice) private returns (int win){
        if (msg.sender == player1)
            p1_choice = choice;
        else if (msg.sender == player2)
            p2_choice = choice;
        if (p1_choice!= 0 && p2_choice!= 0){
            int winner = payoffMatrix[p1_choice][p2_choice];
            if(winner ==1)
                player1.transfer(address(this).balance);
            else if (winner == 2)
                player2.transfer(address(this).balance);
            else{
                player1.transfer(address(this).balance/2);
                player2.transfer(address(this).balance/2);
            }
            
            //reset choices and addresses
            p1_choice = 0;
            p2_choice = 0;
            player1 = 0;
            player2 = 0;
            
            return winner;
        }
        
        else
            return -1;
    }
    
    function getContractBalance() private constant returns(uint amount){
        return address(this).balance;
    }
    
    function checkIfPlayer1() private constant returns(bool x){
        return msg.sender == player1;
    }
    function checkIfPlayer2() private constant returns(bool x){
        return msg.sender == player2;
    }
}