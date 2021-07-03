// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//utility
import "@openzeppelin/contracts/utils/Context.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

//interface for ERC20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Timelock is Context, Ownable {
    using Address for address;
    
    //fees in percent times 1000 to allow lower than one percent
    uint256 public fees = 500;
    uint256 constant internal DIVISOR = 100000;
    address public feecollector;


    struct lockdata {
        uint256 amount;
        uint256 releasetime;
    }
    
    event TokenLocked(address sender, address tokenAddress, uint256 amount, uint256 locktime);
    event TokenReleased(address sender, address tokenAddress, uint256 amount);
    
    event FeesChanged(uint256 from, uint256 to);
    event CollectorChanged(address from, address to);    
    
    mapping (address => mapping (address => lockdata)) private locks;    
    
    constructor() {
        feecollector = _msgSender();        
    }
    
    function lockTokens (address _tokenAddress, uint256 _amount, uint256 _lockTime) external {
        //checks, mostly for proper error messages
        require(locks [_msgSender()][_tokenAddress].releasetime == 0, "you already locked tokens, use add");
        require(_tokenAddress.isContract(),"tokenAddress isn't a contract");
        require(IERC20 (_tokenAddress).allowance(_msgSender(),address(this)) >= _amount,"not enough allowance given to this contract");
        
        //get current balance of the token in the contract
        uint256 initialamount = IERC20 (_tokenAddress).balanceOf(address(this));
        
        uint256 feesTaken = _amount * fees / DIVISOR;
        uint256 amountToReceive = _amount - feesTaken;
        
        IERC20 (_tokenAddress).transferFrom(_msgSender(),address(this), amountToReceive);
        
        if (fees != 0){
            IERC20 (_tokenAddress).transferFrom(_msgSender(), feecollector, feesTaken);
        }
        
        //add locktime to current time
        locks [_msgSender()][_tokenAddress].releasetime = block.timestamp + _lockTime;
        
        //get new balance
        uint256 new_amount = IERC20 (_tokenAddress).balanceOf(address(this));
        
        //sets the amount based on the change in balance
        locks [_msgSender()][_tokenAddress].amount = new_amount - initialamount;        
        
        emit TokenLocked(_msgSender(),_tokenAddress, new_amount - initialamount, _lockTime);
    }
    
    function addLock (address _tokenAddress, uint256 _amount) external{
        //checks
        require(locks [_msgSender()][_tokenAddress].releasetime != 0 , "no initial lock");
        require(IERC20(_tokenAddress).allowance(_msgSender(),address(this)) >= _amount, "not enough allowance given to this contract");
        
        //get current balance of the token in the contract
        uint256 initialamount = IERC20 (_tokenAddress).balanceOf(address(this));
        
        uint256 feesTaken = _amount * fees / DIVISOR;
        uint256 amountToReceive = _amount - feesTaken;
        
        IERC20 (_tokenAddress).transferFrom(_msgSender(),address(this), amountToReceive);
        if (fees != 0){
            IERC20 (_tokenAddress).transferFrom(_msgSender(),feecollector, feesTaken);
        }        
        
        //get new balance
        uint256 new_amount = IERC20 (_tokenAddress).balanceOf(address(this));
        
        //adds the amount based on the change in balance
        locks [_msgSender()][_tokenAddress].amount += new_amount - initialamount;
        
        emit TokenLocked(_msgSender(), _tokenAddress, new_amount - initialamount, locks [_msgSender()][_tokenAddress].releasetime);
    }
    
    
    
    
    function releaseTokens(address _tokenAddress) external {
        require(locks [_msgSender()][_tokenAddress].releasetime != 0, "no lock found");
        require(block.timestamp > locks [_msgSender()][_tokenAddress].releasetime , "release time not yet over, wait for a bit longer");
        
        //gets amount and transfers it
        uint256 amount = locks [_msgSender()][_tokenAddress].amount;        
        IERC20 (_tokenAddress).transfer(_msgSender(), amount);

        //reset so contract can be used again        
        locks [_msgSender()][_tokenAddress].amount = 0;
        locks [_msgSender()][_tokenAddress].releasetime = 0;
        
        emit TokenReleased(_msgSender(), _tokenAddress, amount);
    }
    


    function getLock(address _owner, address _tokenAddress) external view returns (uint256 amount, uint256 releasetime){
        return (locks [_owner][_tokenAddress].amount, locks [_owner][_tokenAddress].releasetime);
    }   

    function changeFees(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "can't be set higher than 1%");
        uint256 oldFee = fees;
        fees = _newFee;
        emit FeesChanged(oldFee,_newFee);
    }

    
    function changeCollector(address _newCollector) external onlyOwner {
        address old_collector = feecollector;
        feecollector = _newCollector;
        emit CollectorChanged(old_collector, _newCollector);
    }
}