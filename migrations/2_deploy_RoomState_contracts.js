var RoomState = artifacts.require("./RoomState/RoomState.sol");
var LEDFactory  = artifacts.require("./LEDState/LEDFactory.sol");
var GridMix = artifacts.require("./GridMix/GridMix.sol");
var LEDLibrary = artifacts.require("./LEDState/LEDLibrary.sol");

module.exports = function(deployer,accounts) {
    //Deploy a tester Room with 5 LEDS
	
	deployer.deploy(GridMix);
    deployer.deploy(LEDLibrary);
	deployer.link(LEDLibrary,LEDFactory);
	deployer.deploy(LEDFactory).then(function() {
		return deployer.deploy(RoomState,LEDFactory.address).then(function() {
			
		});
		//"TesterCoap","0x44515119087cb5A19DdCA3e909ff6537C23f9Ca8",3,1 );
	});
		
};