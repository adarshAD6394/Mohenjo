// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../node_modules/@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract storeData is ReentrancyGuard{

//Counter : Id of the car , when owner adds cars.
uint private counters = 0;

//Owner 
address private owner;

//total Payments : 
uint private totalPayments;


//user struct : datatype to define structure of user data.
struct user {
    
    address walletAddress;
    string name;
    string lastname;
    uint rentedCarId;
    uint balance;
    uint debt;
    uint start;

}

 //car struct : datatype to define structure of car data.
 struct Car {
   uint id;
    // string carNumber;
    string _name;
    string imgUrl;
    Status status;   //enum Status.
    uint rentFee;
    uint saleFee;
   }

 //enum :    a) to indicate the status of the car 
 enum Status { Available, Leased, Retired }
 

 
 
//events all events will be recorder on chain.
event CarAdded (uint indexed id,  string _name, string imgUrl, Status status, uint rentFee,  uint saleFee ) ;
event CarMetadataEdited (uint indexed id, string _name, string imgUrl, uint rentFee,  uint saleFee);
event CarStatusEdited (uint indexed id,  Status status);
event UserAdded (address indexed walletAddress, string name, string lastname );
event Deposit (address indexed walletAddress, uint amount);
event Withdraw (address indexed walletAddress, uint amount );
event CheckOut (address indexed walletAddress, uint indexed id);
event CheckIn (address indexed walletAddress, uint indexed id);
event PaymentMade (address indexed walletAddress, uint amount);
event BalanceWithdrawn (address indexed walletAddress, uint amount);


//user mapping : data about user in key value pairs.
mapping(address => user) private users;

//car mapping : data about car in key value pairs.
mapping(uint => Car) private cars;   

//constructor : what will be your initial status.
constructor(){
    owner = msg.sender; 
    totalPayments = 0;
}


//MODIFIERS : condition check required to execute functions like before check verify user debt to zero. //onlyOwner : 
modifier onlyOwner (){
    require(msg.sender == owner, "only the owner can call this function");
    _;
}


//-FUNCTIONS 
//- Execute Functions : changes status of the contract.

 //setOwner #onlyOwner  set owner data with the help of owner struct.
 function setOwner (address _newOwner) external onlyOwner {
    owner = _newOwner;
   
 }

 //addUser #nonExisting set user data with the help of user struct.
 function addUser (string calldata name, string calldata lastname ) external {
    require( !isUser(msg.sender), "user already exist");
    users[msg.sender] = user( msg.sender, name, lastname, 0, 0, 0, 0);

    emit UserAdded(msg.sender, users[msg.sender].name, users[msg.sender].lastname );
 }

 //addCar #onlyOwner #nonExistingCar set car data with the help of car struct. //Counter to verify #nonExisting of car. 
 function addCar( string calldata _name, string calldata url, uint rent, uint sale ) external onlyOwner { 
    counters += counters;
    uint counter = counters;
    cars[counter] = Car(counter, _name, url, Status.Available, rent, sale); // mapping 
    emit CarAdded(counter, cars[counter]._name,  cars[counter].imgUrl, cars[counter].status, cars[counter].rentFee,  cars[counter].saleFee); // an array of cars at index counter and struct Car data.
 }

 //editCarMetadata #onlyOwner #existingCar car maps 
 function editCarMetadata (uint id, string calldata name, string calldata imgUrl, uint rentFee, uint saleFee) external onlyOwner{
    require(cars[id].id != 0, "Car with given ID does not exist");
    Car storage car = cars[id];  // storage is used copy Struct Car into car. If memory is used, then change will be limited to functin call. 
 
   if (bytes(name).length != 0) {
      car._name = name;
   }
   if (bytes(imgUrl).length != 0 ) {
      car.imgUrl = imgUrl;
   }
   if (rentFee > 0) {
      car.rentFee = rentFee;
   }
   if (saleFee > 0) {
      car.saleFee = saleFee;
   }

   emit CarMetadataEdited (id, car._name, car.imgUrl, car.rentFee, car.saleFee );
 }

 //editCarStatus #onlyOwner #existingCar car enum
 function editCarStatus ( uint id, Status status) external onlyOwner {
   require( cars[id].id != 0, "car does not exist");
   cars[id].status = status;

   emit CarStatusEdited (id, status)  ;
 }

 //checkOut #existingUser #isCarAvailable #userHasNotRentedACar #userHasNoDebt 
 function checkOut (uint id) external {
   require( isUser(msg.sender), "user does not exist!");
   require( cars[id].status == Status.Available, " Car is not available");
   require( users[msg.sender].rentedCarId == 0, "Already Rented!");
   require( users[msg.sender].debt == 0, "Clear you previous debt!");

   users[msg.sender].start = block.timestamp;
   users[msg.sender].rentedCarId = id;
   cars[id].status = Status.Leased;
   
   
   emit CheckOut (msg.sender, id);
 }
   


 //checkIn #existingUser #userHasNotRentedACar 
 function checkIn () external {
   require( isUser(msg.sender), "user does not exist!");
   uint rentedCarId = users[msg.sender].rentedCarId;
   require( rentedCarId != 0, "No car rented");
   // require( users[msg.sender].debt == 0, "Clear you debt!");

   uint usedSeconds = block.timestamp - users[msg.sender].start;
   uint rentFee = cars[rentedCarId].rentFee;
   users[msg.sender].debt = calculateDebt(usedSeconds, rentFee);

   users[msg.sender].rentedCarId = 0;
   users[msg.sender].start = 0;
   cars[rentedCarId].status = Status.Available;

   emit CheckIn (msg.sender, rentedCarId);
 }

 //deposit #existingUser  user to deposit balance from their external wallet to app wallet.
 function deposit() external payable  {
   require(isUser(msg.sender), "user does not exist");
   users[msg.sender].balance += msg.value;

   emit Deposit (msg.sender, msg.value);
}

 //makePayment #existingUser #existingDebt #suffiecientBalance 
 function makePayment() external {
   require(isUser(msg.sender), "user does not exist");
   uint debt = users[msg.sender].debt;
   uint balance = users[msg.sender].balance;
   require(debt > 0 ,"user has no debt");
   require(balance >= debt, "Insufficient balance");

   unchecked {
      users[msg.sender].balance -= debt;
   }

   totalPayments += debt;
   users[msg.sender].debt = 0;

   emit PaymentMade (msg.sender, debt);
 }

 //withdrawBalance #existingUser  take out all the extra balance that has not been used.
 function withdrawBalance (uint amount) external nonReentrant {
   require(isUser(msg.sender), "user does not exist");
   uint balance = users[msg.sender].balance;
   require(balance > amount , "Insufficient balance");

   unchecked {
      balance -= amount;
   }

   (bool success, ) = msg.sender.call{value : amount}("");
   require (success, "Transfer Failed");

   emit BalanceWithdrawn(msg.sender, amount);
 }

 //withdrawOwnerBalance #onlyOwner owner can withdarw only contract amount from interface not user.
   function withdrawOwnerBalance (uint amount) external onlyOwner nonReentrant {
      require(totalPayments >= amount, "Insufficient Balance");

      (bool success, ) = owner.call{value : amount}("");
      require(success, "Transfer Failed");

      unchecked {
       totalPayments -= amount;
      }
   }

// Query Functions : gets data about different elements of project like :-

//getOwner : request to get owner data.
   function getOwner() external view returns (address) {
      return owner;
   }

 //isUser : get and check whether the user exist ?
   function isUser (address walletAddress) private view returns(bool) {
      return users[walletAddress].walletAddress != address(0);
   }

 //getUser : #existingUser  extract existing user data.
   function getuser (address walletAddress) external view returns(user memory) {
      require(isUser(walletAddress), "user does not exist");
      return users[walletAddress];
   }

 //getcar  : #existingCar  extract existing car data.
   function getcar (uint id) external view returns (Car memory) {
      require(cars[id].id != 0, "Car does not exist");
      return cars[id];
   }

 //getCarByStatus
 function getCarByStatus( Status _status) external view  returns (Car[] memory) {
 uint count = 0;
 uint length = counters;
 for ( uint i = 1; i<=length; i++){
   if(cars[i].status == _status ){
      count++;
   }
 }
 Car[] memory carsWithStatus = new Car[](count);
   count = 0;
 for ( uint i = 1; i<=length; i++){
   if(cars[i].status == _status ){
      carsWithStatus[count] = cars[i];
      count++;
   }
 }
   return carsWithStatus;  
 }

//calculateDebt : function calculate total user debt.
 function calculateDebt(uint usedSeconds, uint rentFee) private pure returns (uint) {
   uint usedMinutes = usedSeconds/60;
   return usedMinutes * rentFee ;
 }
//getCurrentCount
 function getCurrentCount() external view returns (uint) {
   return counters;
 }

//getContractBalance : #onlyOwner get monetary details of contract owner.
 function getContractBalance() external  view onlyOwner returns (uint) {
   return address(this).balance; 
 }

//getTotalPayment #onlyOwner 
 function getTotalPayment() external view onlyOwner returns (uint) {
   return totalPayments;
 }
}