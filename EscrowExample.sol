pragma solidity ^0.4.11;

//Escrow with deposit

contract EscrowExample {
    address owner;
    address buyer;
    uint public buyerDeposit;
    uint public itemValue;
    uint quintillion = 1000000000000000000;
    uint withdrawalAmount;
    uint startTime;
    
    enum State { Created, Paid, Delivered, Finished, Disabled }
    State state;
    
    modifier atState(State s) {
        if (state != s) throw;
        _;
    }
    
    //0. Opening Constructor
    function EscrowExample(uint specifiedValue) payable { 
        owner = msg.sender;
        buyerDeposit = msg.value;
        itemValue = specifiedValue * quintillion;
        startTime = now;
    }
    
    //1a. buyer doesn't pay
    function Cancel() atState(State.Created) {
        if (msg.sender != owner) throw;
        owner.transfer(this.balance);
        state = State.Disabled;
    }
    
    //1b. Payment
    function BuyerPays() payable atState(State.Created) {
        if (msg.value != itemValue + buyerDeposit) throw;
        buyer = msg.sender;
        state = State.Paid;
    }
     
    //2a. Refund if buyer does not like item
    function Refund() atState(State.Paid) {
        if (msg.sender != owner) throw;
        buyer.transfer(itemValue + buyerDeposit);
        owner.transfer(this.balance);
        state = State.Disabled;
    }
    
    //2b. Buyer accepts delivery
    function DeliveryConfirmed() atState(State.Paid) {
        if (msg.sender != buyer) throw;
        withdrawalAmount = buyerDeposit;
        state = State.Delivered;
    }

    //3 Wrapping up payments
    function BuyerWithdraws() atState(State.Delivered) {
        if (msg.sender != buyer) throw;
        buyer.transfer(withdrawalAmount);
        withdrawalAmount = 0;
        state = State.Disabled;
    }
    
    function SellerWithdraws() atState(State.Disabled) {
        if (msg.sender != owner) throw;
        owner.transfer(this.balance);
    }
    
    //Buyer does not withdraw funds for whatever reason
    function TimeOut() atState(State.Delivered) {
        if (msg.sender != owner) throw;
        if (now > startTime + 14 days) throw;
        buyer.transfer(withdrawalAmount);
        withdrawalAmount = 0;
        owner.transfer(this.balance);
        state = State.Disabled;
    }
}
