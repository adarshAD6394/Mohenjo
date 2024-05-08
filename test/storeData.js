const storeData = artifacts.require("storeData");


contract("storeData", accounts => {
  let carRentalPlatform;
  const owner = accounts[0];
  const user1 = accounts[1];

  beforeEach(async () => {
    carRentalPlatform = await storeData.new();
});

  describe("Add user and car", () => {
    it("adds a new user", async () => {
      await carRentalPlatform.addUser("Alice Smith");
      console.log("test hit")
      const user = await carRentalPlatform.getuser(user1);
      assert.equal(user.Username, "Alice Smith", "Problem with user name");
     });

    it("adds a car", async () => {
      await carRentalPlatform. addCar("Tesla Model S", "example url", 10, 50000);
      const car = await carRentalPlatform.getcar(1);
      assert.equal(car.companyAndModel, "Tesla Model S", "Problem with car name");
      assert.equal(car.imageUrl, "example url", "Problem with car name");
      assert.equal(car.rentFee, 10, "Problem with rent fee");
      assert.equal(car.saleFee, 50000, "Problem with sale fee");
    });
});

  describe("Check out and check in car", () => {
    It("Check out car", async () => {
      await carRentalPlatform.addUser("Alice Smith", { from: user1 });
      await carRentalPlatform.addCar("Tesla Model S", "example ur1", 10, 50000);
      await carRentalPlatform.checkOut(1, { from: user1 });
                                                                                  
      const user = await carRentalplatform.getuser(user1);
      assert.equal(user.rentedcarld, 1, "User could not check out the car");
    });

    it("checks in a car", async () => {
      await carRentalPlatform.adduser("Alice Smith", { from: user1 });
      await carRentalPlatform.addCar("Tesla Model S", "example url", 10, 50000,  { from: user1 });
      await carRentalPlatforn.checkOut(1,  { from: user1 });
      await new Promise((resolve) => setTimeout (resolve, 60000)); //1 min



      /* 46 -    */
      await carRentalPlatform. checkIn({ from: user1 });

      const user = await carRentalPlatform.getuser(user1);
      assert.equal (user.rentedCarId, 0, "User could not check in the car");
      assert.equal (user.debt, 10, "User debt did not get created");
    });
  });


  describe ("Deposit token and make payment", () => {
      it("deposits token", async () => {
      await carRentalPlatform.addUser("Alice Smith", { from: user1 });
      await carRentalPlatform.deposit( { from: user1, value: 100 });
      const user = await carRentalPlatform.getuser(user1);
      assert.equal(user.balance, 100, "User could not deposit tokens");
    });

    it("makes a payment", async () => {
      await carRentalPlatform.adduser("Alice Smith", { from: user1 });
      await carRentalPlatform.addCar("Tesla Model S", "example url", 10, 50000);


  /*  65   -  86  */

  
      await carRentalPlatform. checkOut(1, { from: user1 });
      await new Promise((resolve) => setTimeout (resolve, 60000)); // 1 min
      await carRentalPlatform. checkIn({ from: user1 });


      await carRentalPlatform.deposit({ from: user1, value: 100 });
      await carRentalPlatform.makePayment( { from: user1 });
      const user = await carRentalPlatform.getuser (user1);
      assert.equal(user.debt, 0, "Somehting went wrong while trying to make the payment");
    });
  });

  describe("edit car", () => {
    it("should edit an existing car's metadata with valid parameters", async () => {
      await carRentalPlatform.addCar("Tesla Model S", "example img url", 10, 50000);
      const newName = "Honda";
      const newImgUrl = "new img url";
      const newRentFee = 20;
      const newSaleFee = 100000;


/*   86 -   105  */
      await carRentalPlatform.editCarMetadata(1, newName, newImgUrl, newRentFee, newSaleFee);



      const car = await carRentalPlatform.getcar(1);
     
      assert.equal(car.companyAndModel, newName, "Problem editing car name");
      assert.equal (car.imageUrl, newImgUrl, "Problem updating the image url");
      assert.equal (car.rentFee, newRentFee, "Problem editing rent fee");
      assert.equal(car.saleFee, newSaleFee, "Problem with editing sale fee");
    });

    it("should edit an existing car's status", async () => {
    await carRentalPlatform.addCar( "Tesla Model S", "example img url", 10, 50000);
    const newStatus = 0;
    await carRentalPlatform.editCarStatus(1, newStatus, { from: owner });
    const car = await carRentalPlatform.getcar(1);
    assert.equal(car.status, newStatus, "Problem with editing car status");
    });
  });


  describe( "Withdraw balance", () => {

/*  105 -    112   */
    it("should send the desired amount of tokens to the user", async () => {
      await carRentalPlatform.addUser("Alice Smith", { from: user1 });
      await carRentalPlatform.deposit({ from: user1, value: 100 });
      await carRentalPlatform.withdrawBalance(50, { from: user1 });

      const user = await carRentalPlatform.getuser(user1);
      assert.equal (user.balance, 50, "User could not get his/her tokens");
    });


 /*  113  -   121  */
    it("should send the desired amount of tokens to the owner", async () => {
      await carRentalPlatform. addUser("Alice Smith", { from: user1 });
      await carRentalPlatform. addCar("Tesla Model 5", "example img url", 10, 50000);
      await carRentalPlatform.checkOut(1, { from: user1 });   
      await new Promise((resolve) => setTimeout(resolve, 60000)); // 1 min
      await carRentalPlatform. checkIn({ from: user1 });
      await carRentalPlatform.deposit({ from: user1, value: 1000 });
      await carRentalPlatform.makePayment({ from: user1 });


      /*  122 -    */

      const totalPaymentAmount =  await carRentalPlatform.getTotalPayment({ from: user1 });
      const amountToWithdraw = totalPaymentAmount -10;
      await carRentalPlatform.withdrawOwnerBalance(amountToWithdraw, { from: owner });
      const totalPayment = await carRentalPlatform.getTotalPayment( {from: owner} );
      assert.equal(totalPayment, 10, "Owner could not withdraw tokens");
    });
  });
});
