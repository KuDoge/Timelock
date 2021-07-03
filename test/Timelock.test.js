const { expectRevert, time } = require('@openzeppelin/test-helpers');
const Timelock = artifacts.require('Timelock');
const MyToken = artifacts.require('MyToken');

contract('Timelock', ([owner, bob, carol, alice]) => {
    beforeEach(async () => {
        this.MyToken = await MyToken.new(); 
        this.Timelock = await Timelock.new();   
        await this.MyToken.transfer(bob, "20000000"); 
        await this.Timelock.changeCollector(carol);
        
    });
    it('lock tokens', async () => {
      await this.MyToken.approve(this.Timelock.address, "10000000", {from: bob}); 
      await this.Timelock.lockTokens(this.MyToken.address, "10000000","60", {from: bob});     

      assert.equal((await this.MyToken.balanceOf(this.Timelock.address)).toString(),"9950000");
      assert.equal((await this.MyToken.balanceOf(carol)).toString(),"50000");
    })  

    it('add lock', async () => {
      await this.MyToken.approve(this.Timelock.address, "10000000", {from: bob}); 
      await this.Timelock.lockTokens(this.MyToken.address, "10000000","60", {from: bob});     

      assert.equal((await this.MyToken.balanceOf(this.Timelock.address)).toString(),"9950000");
      assert.equal((await this.MyToken.balanceOf(carol)).toString(),"50000");

      //add more tokens to lock
      await this.MyToken.approve(this.Timelock.address, "10000000", {from: bob}); 
      await this.Timelock.addLock(this.MyToken.address, "10000000", {from: bob});     

      assert.equal((await this.MyToken.balanceOf(this.Timelock.address)).toString(),"19900000");
      assert.equal((await this.MyToken.balanceOf(carol)).toString(),"100000");
    })  

    it('lock tokens fail', async () => {
      await this.MyToken.approve(this.Timelock.address, "10000000", {from: bob}); 
      await this.Timelock.lockTokens(this.MyToken.address, "10000000","60", {from: bob});     

      assert.equal((await this.MyToken.balanceOf(this.Timelock.address)).toString(),"9950000");
      assert.equal((await this.MyToken.balanceOf(carol)).toString(),"50000");

      //add more tokens to lock
      await this.MyToken.approve(this.Timelock.address, "10000000", {from: bob}); 
      await expectRevert(this.Timelock.lockTokens(this.MyToken.address, "10000000","60", {from: bob}),"you already locked tokens, use add");     
    })  


    it('add tokens fail', async () => {
      await this.MyToken.approve(this.Timelock.address, "10000000", {from: bob}); 
      await expectRevert(this.Timelock.addLock(this.MyToken.address, "10000000", {from: bob}),"no initial lock");    
    })  


    it('lock tokens and release', async () => {
      await this.MyToken.approve(this.Timelock.address, "10000000", {from: bob}); 
      await this.Timelock.lockTokens(this.MyToken.address, "10000000","60", {from: bob});     

      assert.equal((await this.MyToken.balanceOf(this.Timelock.address)).toString(),"9950000");
      assert.equal((await this.MyToken.balanceOf(carol)).toString(),"50000");

      await time.increase('61');
      await time.advanceBlock();

      await this.Timelock.releaseTokens(this.MyToken.address, {from: bob}); 
      assert.equal((await this.MyToken.balanceOf(this.Timelock.address)).toString(),"0");
      assert.equal((await this.MyToken.balanceOf(bob)).toString(),"19950000");
    })  


    it('lock tokens and release, fail', async () => {
      await this.MyToken.approve(this.Timelock.address, "10000000", {from: bob}); 
      await this.Timelock.lockTokens(this.MyToken.address, "10000000","60", {from: bob});     

      assert.equal((await this.MyToken.balanceOf(this.Timelock.address)).toString(),"9950000");
      assert.equal((await this.MyToken.balanceOf(carol)).toString(),"50000");

      await time.increase('30');
      await time.advanceBlock();

      await expectRevert(this.Timelock.releaseTokens(this.MyToken.address, {from: bob}),"release time not yet over, wait for a bit longer"); 
    })  


    it('lock and release, check contract data', async () => {
      await this.MyToken.approve(this.Timelock.address, "10000000", {from: bob}); 
      await this.Timelock.lockTokens(this.MyToken.address, "10000000","60", {from: bob});     

      assert.equal((await this.MyToken.balanceOf(this.Timelock.address)).toString(),"9950000");
      assert.equal((await this.MyToken.balanceOf(carol)).toString(),"50000");

      await time.increase('61');
      await time.advanceBlock();

      await this.Timelock.releaseTokens(this.MyToken.address, {from: bob}); 
      assert.equal((await this.MyToken.balanceOf(this.Timelock.address)).toString(),"0");
      assert.equal((await this.MyToken.balanceOf(bob)).toString(),"19950000");
    })  
});

