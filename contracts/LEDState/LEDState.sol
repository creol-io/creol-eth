pragma solidity ^0.5.0;


/**
 *
 *   @title LEDState v0.0.1
 ________  ________  _______   ________  ___
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|


  _      ______ _____   _____ _        _
 | |    |  ____|  __ \ / ____| |      | |
 | |    | |__  | |  | | (___ | |_ __ _| |_ ___
 | |    |  __| | |  | |\___ \| __/ _` | __/ _ \
 | |____| |____| |__| |____) | || (_| | ||  __/
 |______|______|_____/|_____/ \__\__,_|\__\___|


*
* Author: Joshua Bijak
* Description: Smart contract for monitoring and controlling states of a LED DAlI enabled Creol Luminaire
* TODO: Check and validate all inputs coming into functions
*/

/**
 *   ___                            _
    |_ _|_ __ ___  _ __   ___  _ __| |_ ___
     | || '_ ` _ \| '_ \ / _ \| '__| __/ __|
     | || | | | | | |_) | (_) | |  | |_\__ \
    |___|_| |_| |_| .__/ \___/|_|   \__|___/
                  |_|

 *
 */
import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/GSNRecipient.sol";


import  './LEDLibrary.sol';
import  './LEDStateInterface.sol';

import  '../AccessHub/AccessHubInterface.sol';
/**
 * @author Joshua Bijak
 * @dev LEDState contract that uses LEDLibrary
 * @notice LEDState Contract
 *
 */
contract LEDState is LEDStateInterface, Initializable, Ownable, GSNRecipient {

       /**
     *
           _____ _       _           _
          / ____| |     | |         | |
         | |  __| | ___ | |__   __ _| |___
         | | |_ | |/ _ \| '_ \ / _` | / __|
         | |__| | | (_) | |_) | (_| | \__ \
          \_____|_|\___/|_.__/ \__,_|_|___/


    */

    using LEDLibrary for LEDLibrary.LEDStorage;

    LEDLibrary.LEDStorage public luminaire;

    address private allowedGSNAddress;

    AccessHubInterface public credentials;


    /**
     *
          ______               _
         |  ____|             | |
         | |____   _____ _ __ | |_ ___
         |  __\ \ / / _ \ '_ \| __/ __|
         | |___\ V /  __/ | | | |_\__ \
         |______\_/ \___|_| |_|\__|___/

     *
     *
     */

    event daliShortAddressUpdated(uint256 daliShortAddress);
    event dateStarted(uint256 startDate);
    event stateUpdated(bool updatedState);
    event roomChanged(address roomContract);
    event dimUpdated(uint256 LEDDim);
    event wattageUpdated(uint256 LEDWattage);
    event runtimeClocksUpdated(bool updatedState);
    event lastOffsetUpdated(uint256 lastOffsetTime);

    modifier onlyAccessHub(){
        require(credentials.checkHasAccess(_msgSender(), AccessHubInterface.ContractTypes.LEDState) || _msgSender() == owner(), "Caller, not registered in access hub");
        _;
    }

     /**
      *   ______                _   _
         |  ____|              | | (_)
         | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
         |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
         | |  | |_| | | | | (__| |_| | (_) | | | \__ \
         |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
     */

    constructor() public {

    }
        /**
     *  /**
      * @dev creates a new LEDState contract
      * @notice create new LEDState contract
      * @param defaultState first state of the LED , on or off
      * @param _roomContract Address of the room this LED belongs to
      * @param _accessHub AccessHub deployed
      * @param _daliShortAddress DALI short address from 0-63
      * @param _LEDDim Dim rate assigned to LED 0-254
      * @param _LEDWattage Wattage associated with this LED
      *
      */

    function initialize (bool defaultState, address _roomContract,address _accessHub, address _GSNAddress, uint256 _daliShortAddress, uint256 _LEDDim, uint256 _LEDWattage) public initializer {
        require(_daliShortAddress >= 0, "DALI short address must be between 0-63");
        require(_daliShortAddress <= 63, "DALI short address must be between 0-63");
        require(_LEDDim >= 0, "DALI short address must be between 0-255");
        require(_LEDDim <= 255, "DALI short address must be between 0-255");

        Ownable.initialize(_accessHub);
        GSNRecipient.initialize();
        credentials = AccessHubInterface(_accessHub);

        allowedGSNAddress = _GSNAddress;

        luminaire.newLED(defaultState,_roomContract,_daliShortAddress,_LEDDim, _LEDWattage);

    }
        /**
    * @dev Updates state and Dim in one function, is abstraction of two lower functions
    * @param newState New LED state
    * @param _LEDDim New LED Dim value
    * @notice Turn on/off and dim at the same time.
    */
    function onDim(bool newState, uint256 _LEDDim) public onlyAccessHub{
        luminaire.onDim(newState,_LEDDim);
    }
        /**
     * @dev update the current state of the LEDStorage object
     * @notice Turn LED on/off
     * @param newState New LED state
     */
    function updateState(bool newState) public onlyAccessHub{

        luminaire.updateState(newState);
    }

        /**
     * @dev update the dim setting of the LEDStorage object
     * @notice Change LED Dim settings
     * @param _LEDDim New LED dim rate
     */
    function updateDim(uint256 _LEDDim) public onlyAccessHub{
        require(_LEDDim >= 0, "DALI short address must be between 0-255");
        require(_LEDDim <= 255, "DALI short address must be between 0-255");
        luminaire.updateDim(_LEDDim);
    }
        /**
     * @dev update wattage of the LEDStorage
     * @notice update wattage of the LED
     * @param _LEDWattage New LED wattage
     */
    function updateWattage(uint256 _LEDWattage) public onlyAccessHub{
        luminaire.updateWattage(_LEDWattage);
    }
        /**
     * @dev update DALI short address
     * @notice Change the DALI short address
     * @param newdaliShortAddr New DALI address
     */
    function updatedaliShortAddr(uint256 newdaliShortAddr) public onlyAccessHub{
        require(newdaliShortAddr >= 0, "DALI short address must be between 0-63");
        require(newdaliShortAddr <= 63, "DALI short address must be between 0-63");
        luminaire.updatedaliShortAddr(newdaliShortAddr);
    }
        /**
     * @dev update contract room address
     * @notice update the address for the room this LED is Int
     * @param newRoomAddr new Room address
     */
    function updateRoomContract(address newRoomAddr) public onlyAccessHub{
        luminaire.updateRoomContract(newRoomAddr);
    }
        /**
     * @dev update the runtime CLocks
     * @notice Update the clocks with the new state
     * @param newState new LED State
     */
    function updateRuntimeClocks(bool newState) public onlyAccessHub {
        luminaire.updateRuntimeClocks(newState);
    }
    /**
     * @dev update the Offset Time
     * @notice Update the clocks with the Offset Time
     */
    function updateLastOffsetTime() public onlyAccessHub {

        luminaire.updateLastOffsetTime();

    }
        /**
     * @dev calculate the daily runtime
     * @notice Get the Daily runtime
     */
    function getDailyRuntime() public view returns (uint256 dailyRun) {
        return luminaire.getDailyRuntime();

    }
         /**
     * @dev calculate the weekly runtime
     * @notice Get the weekly runtime
     */
    function getWeeklyRuntime() public view returns (uint256 weeklyRun) {
       return luminaire.getDailyRuntime();
    }
         /**
     * @dev calculate the monthly runtime
     * @notice Get the monthly runtime
     */
    function getMonthlyRuntime() public view returns (uint256 monthlyRun) {
        return luminaire.getMonthlyRuntime();
    }
         /**
     * @dev calculate the yearly runtime
     * @notice Get the yearly runtime
     */
    function getYearlyRuntime() public view returns (uint256 yearlyRun) {
        return luminaire.getYearlyRuntime();

    }
     /**
     * @dev calculate the complete runtime
     * @notice Get the all runtime
     */
    function getAllRuntime() public view returns (uint256 alltimeRun) {
        return luminaire.getAllRuntime();
    }
    /**
     * @dev Get the current Dim value
     * @notice Get the LED Dim level (DALI)
     */
     function getDim () public view returns (uint256 currentDim){
         return luminaire.LEDDim;
     }
     /**
     * @dev Get the current State value
     * @notice Get the state (on / off)
     */
     function getState () public view returns (bool currentState){
         return luminaire.currentState;
     }
     /**
     * @dev Get the current wattage
     * @notice Get the LED Wattage in W
     *
     */
     function getWattage () public view returns (uint256 currentWattage){
         return luminaire.LEDWattage;
     }
    /**
     * @dev Get the current DALI short address (0-64)
     * @notice Get the DALI Short address
     */
     function getDALIShortAddress () public view returns (uint256 currentDALIShort){
         return luminaire.daliShortAddress;
     }
    /**
     * @dev Get the current room address
     * @notice Get the current room address
     */
     function getRoomContract () public view returns (address currentRoom){
         return luminaire.roomContract;
     }
     /**
     * @dev Get the start date
     * @notice Get the start date of this LED
     */
     function getStartDate () public view returns (uint256 startDate) {
         return luminaire.startDate;
     }
     /**
     * @dev Get the last time this LED was offset
     * @notice Get the last offset date of this LED
     */
     function getLastOffsetDate () public view returns (uint256 lastOffsetTime) {
         return luminaire.lastOffsetTime;
     }
    function setGSNAllowed(address _newGSNAddress) public onlyAccessHub {
        allowedGSNAddress = _newGSNAddress;
    }
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    ) external view returns (uint256, bytes memory)  {

        //emit emittedMsgSender(_msgSender());
        //emit emittedAllowedAddress(allowedAddress);
        if(from == allowedGSNAddress){
            return _approveRelayedCall();

        }
        else {
            return _rejectRelayedCall(uint256(0));
        }
    }

    function _preRelayedCall(bytes memory context) internal returns (bytes32) {

    }

    function _postRelayedCall(bytes memory context, bool, uint256 actualCharge, bytes32) internal {

    }

    function setRelayHubAddress() public {
        if(getHubAddr() == address(0)) {
            _upgradeRelayHub(0xD216153c06E857cD7f72665E0aF1d7D82172F494);
        }
    }

    function getRecipientBalance() public view returns (uint) {
        return IRelayHub(getHubAddr()).balanceOf(address(this));
    }
}
