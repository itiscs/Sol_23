// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.22;
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function transfer(address to, uint tokens) public virtual returns (bool success);

    
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Cryptos is ERC20Interface{
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint public decimals = 0;
    
    uint public supply;
    address public founder;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) allowed;
    
    //allowed[0x1111....][0x22222...] = 100;
    
    
    constructor(){
        supply = 30000;
        founder = msg.sender;
        balances[founder] = supply;
    }
    
     function totalSupply() public override view returns (uint){
        return supply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint balance){
         return balances[tokenOwner];
     }
    function allowance(address tokenOwner, address spender) view public override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
    function transfer(address to, uint tokens) public override virtual  returns (bool success){
         require(balances[msg.sender] >= tokens && tokens > 0);
         
         balances[to] += tokens;
         balances[msg.sender] -= tokens;
         emit Transfer(msg.sender, to, tokens);
         return true;
     }

    function approve(address spender, uint tokens) public override returns(bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public override virtual  returns(bool){
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);
        
        balances[from] -= tokens;
        balances[to] += tokens;       
        
        allowed[from][to] -= tokens;
        
        emit Transfer(from, to, tokens);
        return true;
    }
}

contract CryptosICO is Cryptos{
    address public admin;
    
    
    //starting with solidity version 0.5.0 only a payable address has the transfer() member function
    //it's mandatory to declare the variable payable
    address payable public deposit;
    
    //token price in wei: 1CRPT = 0.01 ETHER, 1 ETHER = 100 CRPT
    uint tokenPrice = 10000000000000000;
    
    //300 Ether in wei
    uint public hardCap = 300000000000000000000;
    
    uint public raisedAmount;
    
    uint public saleStart = block.timestamp;
    uint public saleEnd = block.timestamp + 604800; //one week
    uint public coinTradeStart = saleEnd + 604800; //transferable in a week after salesEnd
    
    uint public maxInvestment = 5000000000000000000;
    uint public minInvestment = 10000000000000000;
    
    enum State { beforeStart, running, afterEnd, halted}
    State public icoState;
    
    
    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }

       
    event Invest(address investor, uint value, uint tokens);
    
    
    //in solidity version > 0.5.0 the deposit argument must be payable
    constructor(address payable _deposit){
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    //emergency stop
    function halt() public onlyAdmin {
        icoState = State.halted;
    }
    
    //restart 
    function unhalt() public onlyAdmin{
        icoState = State.running;
    }
    
    
    //only the admin can change the deposit address
    //in solidity version > 0.5.0 the deposit argument must be payable
    function changeDepositAddress(address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    
    //returns ico state
    function getCurrentState() public view returns(State){
        if(icoState == State.halted){
            return State.halted;
        }else if(block.timestamp < saleStart){
            return State.beforeStart;
        }else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        }else{
            return State.afterEnd;
        }
    }
    
    
    function invest() payable public returns(bool){
        //invest only in running
        icoState = getCurrentState();
        require(icoState == State.running);
        
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        
        uint tokens = msg.value / tokenPrice;
        
        //hardCap not reached
        require(raisedAmount + msg.value <= hardCap);
        
        raisedAmount += msg.value;
        
        //add tokens to investor balance from founder balance
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        
        deposit.transfer(msg.value);//transfer eth to the deposit address
        
        //emit event
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
        

    }
    
    //the payable function must be declared external in solidity versions > 0.5.0
    function recieve() payable external{
        invest();
    }
    
    
    
    function burn() public onlyAdmin returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return  true;
        
    }
    
    
    function transfer(address to, uint value) public override returns(bool){
        require(block.timestamp > coinTradeStart);
        return super.transfer(to, value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public override returns(bool){
        require(block.timestamp > coinTradeStart);
        return super.transferFrom(_from, _to, _value);
    }
    
}


