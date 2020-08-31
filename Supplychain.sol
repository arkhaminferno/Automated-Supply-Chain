pragma solidity^0.6.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Item{

=============================================================================
// State Variables
//=============================================================================
    uint public priceInWei;
    uint public pricePaid;
    uint public index;
    ItemManager parentContract;

=============================================================================
// Constructor
//=============================================================================

    constructor(ItemManager _parentContract,uint _priceInWei,uint _index) public{
        priceInWei = _priceInWei;
        index=_index;
        parentContract = _parentContract;
    }

=============================================================================
// Fallbacks
//=============================================================================
    
    receive() external payable {
        require(pricePaid == 0,"item is paid already");
        require(priceInWei == msg.value,"Only full payments allowed");
        pricePaid +=msg.value;
        (bool success,)= address(parentContract).call.value(msg.value)(abi.encodeWithSignature("triggerPayment(uint256)",index));
        require(success,"The transaction wasn't successful,canceling");
    }
  
  fallback() external {}
}

contract ItemManager is Ownable {
=============================================================================
// State Variables
//=============================================================================

  struct item{
        Item _item;
        string identifer;
        uint itemPrice;
        ItemManager.SupplyChainState _state;
    }

 mapping(uint=>item) public items;
    uint itemIndex;

=============================================================================
// Event & State
//=============================================================================
   
    
    enum SupplyChainState{Created,Paid,Delivered}
    event SupplyChainStep(uint _itemIndex,uint _step,address _itemAddress);
    
=============================================================================
// Functions
//=============================================================================
    // Owner can add items into the contract for sale
    
    function ListItem(string memory _identifier,uint _itemprice) onlyOwner public{
        Item item = new Item(this,_itemprice,itemIndex);
        items[itemIndex]._item = item;
        items[itemIndex].identifer = _identifier;
        items[itemIndex].itemPrice = _itemprice;
        items[itemIndex]._state = SupplyChainState.Created;
        emit SupplyChainStep(itemIndex,uint(items[itemIndex]._state),address(item));
        itemIndex++;
        
    }

    
    // this function will trigger after the successful payment by the customer

    function triggerPayment(uint _itemIndex) public payable {
        require(items[itemIndex].itemPrice == msg.value,"Only full payments accepted");
        require(items[_itemIndex]._state == SupplyChainState.Created,"Item is further in the chain" );
        items[_itemIndex]._state = SupplyChainState.Paid;
         emit SupplyChainStep(_itemIndex,uint(items[itemIndex]._state),address(items[_itemIndex]._item));
    }

    
     //function for deleivery of the product from warehouse
    
    function triggerDelivery(uint _itemIndex) public onlyOwner {
          require(items[_itemIndex]._state == SupplyChainState.Paid,"Item is further in the chain" );
          items[_itemIndex]._state = SupplyChainState.Delivered;
          
          emit SupplyChainStep(_itemIndex,uint(items[_itemIndex]._state),address(items[_itemIndex]._item));
    }
}