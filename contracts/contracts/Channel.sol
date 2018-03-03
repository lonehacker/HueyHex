pragma solidity ^0.4.11;

contract ERC20Interface {

    function totalSupply() constant returns (uint256 totalSup);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract HueyToken is ERC20Interface {

    string public constant symbol = "HUEY";

    string public constant name = "HueyHex";

    uint8 public constant decimals = 18;

    uint256 _totalSupply = 65000000;

    address public owner;

    address public hueyContract;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier onlyHueyContract() {
        if (msg.sender != hueyContract) {
            revert();
        }
        _;
    }

    // Constructor
    function HueyToken() {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    function changeOwner(address _newOwner) onlyOwner() returns (bool success) {
        owner = _newOwner;
        return true;
    }

    function updateHueyAddress(address _contractAddress) onlyOwner() returns (bool success) {
        hueyContract = _contractAddress;
        return true;
    }
 
    function totalSupply() constant returns (uint256 totalSup) {
        totalSup = _totalSupply;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function donate(address _to, uint256 _amount) onlyHueyContract() returns (bool success) {
        if (balances[tx.origin] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[tx.origin] -= _amount;
            balances[_to] += _amount;
            Transfer(tx.origin, _to, _amount);
            Donate(tx.origin, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _amount) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Donate(address indexed _from, address indexed _to, uint256 _value);

}

contract Subscriptions {
    
    address public owner;

    address public hueyTokenAddress;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Channel {
        address contractAddress;
        uint256 subCount;
        uint256 totalDonations;
        uint256 donationCount;
    }
    
    //mapping of address to their channel
    mapping (address => Channel) public channels;
    //mapping of address to their subs
    mapping (address => address[]) public subs;

    //mapping (address => uint256) public subscriberCount;

    //initalize contract
    function Subscriptions() {  
        owner = msg.sender;
    }

    function changeOwner(address _newOwner) onlyOwner() returns (bool success) {
        owner = _newOwner;
        return true;
    }

    function changeTokenAddress(address _newTokenAddress) onlyOwner() returns (bool success) {
        hueyTokenAddress = _newTokenAddress;
        return true;
    }

    function registerChannelFromContract() returns (bool success) {
        success = false;
        if (channels[tx.origin].contractAddress != address(0x0)) {
            revert();
        }
        channels[tx.origin] = Channel({
            contractAddress:msg.sender,
            subCount:0,
            totalDonations:0,
            donationCount:0
        });
        success = true;
    }
    
    function registerChannelManually(address channelAdd) returns (bool success) {
        success = false;
        if (channelAdd == address(0x0)) {
            revert();
        }
        if (channels[msg.sender].contractAddress != address(0x0)) {
            revert();
        }
        channels[msg.sender] = Channel({
            contractAddress:channelAdd,
            subCount:0,
            totalDonations:0,
            donationCount:0
        });
        success = true;
    }

    function unregisterChannel() returns (bool success) {
        channels[msg.sender].contractAddress = address(0x0);
        return true;
    }

    function channelExist(address addr) constant returns (bool exist) {
        exist = false;
        if (channels[addr].contractAddress != address(0x0)) {
            exist = true;
        }
    }

    function subscribeToChannel(address addr) returns (bool success) {
        success = false;
        if (!channelExist(addr)) {
            revert();
        }
        if (alreadySubscribed(msg.sender, addr)) {
            revert();
        }
        subs[msg.sender].push(addr);
        channels[addr].subCount = channels[addr].subCount + 1;
    }

    function returnChannels() constant returns (address[] _subs) {
        _subs = subs[msg.sender];
    }
    
    function totalSubscribers(address addr) constant returns (uint total) {
        total = channels[addr].subCount;
    }

    function donateTo(address _channel, uint256 _amount) returns (bool success) {
        success = false;
        if (!channelExist(_channel)) {
            revert();
        }
        if (_amount <= 0) {
            revert();
        }
        HueyToken hueyTokenInstance = HueyToken(hueyTokenAddress);
        var ret = hueyTokenInstance.donate(_channel, _amount);
        if (ret) {
            channels[_channel].totalDonations = channels[_channel].totalDonations + _amount;
            channels[_channel].donationCount = channels[_channel].donationCount + 1;
            success = true;
        }
        return success;
    }

    function alreadySubscribed(address sender, address channel) internal constant returns (bool subscribed) {
        subscribed = false;
        for (uint256 i = 0; i < subs[sender].length; i++) {
            if (subs[sender][i] == channel) {
                subscribed = true;
            }
        }
    }

    function returnContractAddress(address channel) constant returns (address conAddr) {
        conAddr = channels[channel].contractAddress;
    }
    function returnSubCount(address channel) constant returns (uint256 subCount) {
        subCount = channels[channel].subCount;
    }
    function returnTotalDonations(address channel) constant returns (uint256 totalDonations) {
        totalDonations = channels[channel].totalDonations;
    }
    function returnDonationCount(address channel) constant returns (uint256 donationCount) {
        donationCount = channels[channel].donationCount;
    }
}

contract Channel {
    
    mapping(uint8 => bytes32[]) Items;
    
    uint256 createdOn;
    string public title;
    string public description;
    //bytes32[] public keyWords;
    address public owner;
    string public channelVersion;
    address public subAddress;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event ItemData(uint8 indexed itemEnum, bytes32 indexed itemHash, string itemJson, uint256 addedOn);

    function Channel(string _title, string _description, address _registerAddress) {  
        owner = msg.sender;
        createdOn = now;
        subAddress = _registerAddress;
        channelVersion = "0.3.0";
        description = _description;
        title = _title;
    }

    function updateRegisterLocation(address _registerAddress) onlyOwner() returns (bool success) {
        subAddress = _registerAddress;
        success = true;
    }

    function registerChannel() onlyOwner() {
        Subscriptions subContract = Subscriptions(subAddress);
        subContract.registerChannelFromContract();
    }

    function kill() onlyOwner() {
        selfdestruct(owner);
    }

    function addItemToChannel(bytes32 itemHash, string itemInfo, uint8 itemEnum) onlyOwner() returns (bytes32 _itemHash) {
        ItemData(itemEnum, itemHash, itemInfo, now);
        Items[itemEnum].push(itemHash);
        _itemHash = itemHash;
    }

    function removeItem(bytes32 itemHash, uint8 itemEnum) onlyOwner() returns (bool success) {
        success = false;
        uint256 index = itemIndex(itemHash,itemEnum);
        if (index < 0) {
            revert();
        } else {
            delete(Items[itemEnum][index]);
            success = true;
        }
    }


    function itemIndex(bytes32 itemHash, uint8 itemEnum) constant returns (uint256 index) {
        index = uint256(-1);
        for (uint256 i = 0; i < Items[itemEnum].length; i++) {
            if (itemHash == Items[itemEnum][i]) {
                    index = i;
                    break;
            }
        }
    }

    function returnItems(uint8 itemEnum) constant returns (bytes32[] items) {
        items = Items[itemEnum];
    }
    
    function itemCount(uint8 itemEnum) constant returns (uint256 total) {
        total = Items[itemEnum].length;
    }
    
}