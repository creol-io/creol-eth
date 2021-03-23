pragma solidity ^0.5.0;

/*
  @title LEDLibrary v0.0.1
 ________  ________  _______   ________  ___
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|



  _      ______ _____  _      _ _
 | |    |  ____|  __ \| |    (_) |
 | |    | |__  | |  | | |     _| |__  _ __ __ _ _ __ _   _
 | |    |  __| | |  | | |    | | '_ \| '__/ _` | '__| | | |
 | |____| |____| |__| | |____| | |_) | | | (_| | |  | |_| |
 |______|______|_____/|______|_|_.__/|_|  \__,_|_|   \__, |
                                                      __/ |
                                                     |___/



*/
/**
 * @author Joshua Bijak
 * @notice library to control and deploy LEDState contracts
 * @dev Library is in need of Gas Optimizations
 */

library LEDLibrary {


   /**
     *
           _____ _       _           _
          / ____| |     | |         | |
         | |  __| | ___ | |__   __ _| |___
         | | |_ | |/ _ \| '_ \ / _` | / __|
         | |__| | | (_) | |_) | (_| | \__ \
          \_____|_|\___/|_.__/ \__,_|_|___/


    */


     //On off switch
     struct LEDStorage {
        bool currentState;

        uint256 daliShortAddress;
        //On how much, if off. Remember this dim rate
        uint256 LEDDim;

        uint256 LEDWattage;

        address roomContract;

        uint256 startDate;

        //Burntimes in seconds at 100% equivalence
        uint256 fullWattEquivBurnTime;
        uint256 dailyEquivBurnTime;
        uint256 dailyEquivBurnClock;

        uint256 lastStateChangeTime;
        uint256[] burnHourTracker;

        uint256 lastOffsetTime;
     }
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

     /**
      *   ______                _   _
         |  ____|              | | (_)
         | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
         |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
         | |  | |_| | | | | (__| |_| | (_) | | | \__ \
         |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
     */
     /**
      * @dev creates a new LEDStorage object
      * @notice create new LEDStorage object
      * @param self LEDStorage object for all LEDss
      * @param defaultState first state of the LED , on or off
      * @param _roomContract Address of the room this LED belongs to
      * @param _daliShortAddress DALI short address from 0-63
      * @param _LEDDim Dim rate assigned to LED 0-254
      * @param _LEDWattage Wattage associated with this LED
      */
    function newLED(LEDStorage storage self, bool defaultState, address _roomContract, uint256 _daliShortAddress, uint256 _LEDDim, uint256 _LEDWattage) public{

        // TODO: Check inputs and validate, errors here come from Instantiation Abuse
        self.roomContract = _roomContract;
        self.daliShortAddress = _daliShortAddress;
        emit daliShortAddressUpdated(self.daliShortAddress);

        self.startDate = now;
        self.lastStateChangeTime = self.startDate;
        self.lastOffsetTime = self.startDate;
        //Set CLocks to Midnight
        uint256 midnightTime = (self.startDate/86400) * 86400;
        self.dailyEquivBurnClock = midnightTime;


        // TODO: Optimize this so its less gas costly to deploy
        //for (int i = 0; i<365; i++){
        self.burnHourTracker.push(0);
        //}

        updateState(self,defaultState);
        //TODO: Check that LEDDim is between range of 0 -253
        updateDim(self,_LEDDim);

        updateWattage(self, _LEDWattage);

        emit dateStarted(self.startDate);


    }
    /**
    * @dev Updates state and Dim in one function, is abstraction of two lower functions
    * @param self LEDStorage object
    * @param newState New LED state
    * @param _LEDDim New LED Dim value
    * @notice Turn on/off and dim at the same time.
    */
    //TODO: Convert to Piped Contract
    function onDim(LEDStorage storage self,bool newState, uint256 _LEDDim) public {
        updateState(self,newState);
        updateDim(self,_LEDDim);
    }
    /**
     * @dev update the current state of the LEDStorage object
     * @notice Turn LED on/off
     * @param self LEDStorage object
     * @param newState New LED state
     */
    function updateState(LEDStorage storage self, bool newState) public {

        updateRuntimeClocks(self,newState);
        self.currentState = newState;
        emit stateUpdated(self.currentState);
    }
    /**
     * @dev update the dim setting of the LEDStorage object
     * @notice Change LED Dim settings
     * @param self LEDStorage object
     * @param _LEDDim New LED dim rate
     */
    function updateDim(LEDStorage storage self,uint256 _LEDDim) public {
        require(_LEDDim >= 0, "DALI short address must be between 0-255");
        require(_LEDDim <= 255, "DALI short address must be between 0-255");
        self.LEDDim = _LEDDim;
        emit dimUpdated(self.LEDDim);
    }
    /**
     * @dev update wattage of the LEDStorage
     * @notice update wattage of the LED
     * @param self LEDStorage object
     * @param _LEDWattage New LED wattage
     */
    function updateWattage(LEDStorage storage self,uint256 _LEDWattage) public {
        self.LEDWattage = _LEDWattage;
        emit wattageUpdated(self.LEDWattage);
    }
    /**
     * @dev update DALI short address
     * @notice Change the DALI short address
     * @param self LEDStorage object
     * @param newdaliShortAddr New DALI address
     */
    function updatedaliShortAddr(LEDStorage storage self,uint256 newdaliShortAddr) public {
        require(newdaliShortAddr >= 0, "DALI short address must be between 0-63");
        require(newdaliShortAddr <= 63, "DALI short address must be between 0-63");
        self.daliShortAddress = newdaliShortAddr;
        emit daliShortAddressUpdated(self.daliShortAddress);
    }
    /**
     * @dev update contract room address
     * @notice update the address for the room this LED is Int
     * @param self LEDStorage object
     * @param newRoomAddr new Room address
     */
    function updateRoomContract(LEDStorage storage self,address newRoomAddr) public {
        self.roomContract = newRoomAddr;
        emit roomChanged(self.roomContract);
    }
    /**
     * @dev update the runtime CLocks
     * @notice Update the clocks with the new state
     * @param self LEDStorage object
     * @param newState new LED State
     */
    function updateRuntimeClocks(LEDStorage storage self,bool newState) public  {
        // Verify that this transaction isnt a reupdate of the same state

        if (newState == true && self.currentState == false){
            self.lastStateChangeTime = now;
            emit runtimeClocksUpdated(newState);
        }
        else if (newState == false && self.currentState == true){
            uint256 curTime = now;
            uint256 midnightTime = (curTime/86400) * 86400;
            // Fancy Int Workarounds
            uint256 burnTimeEquiv = ((curTime-self.lastStateChangeTime)*((self.LEDDim*100)/256))/100;

            self.fullWattEquivBurnTime = self.fullWattEquivBurnTime + burnTimeEquiv;
            // Last state change was today
            if(curTime >=  midnightTime && self.lastStateChangeTime >= midnightTime){
                self.dailyEquivBurnTime = self.dailyEquivBurnTime += burnTimeEquiv;

                self.burnHourTracker[0] = self.dailyEquivBurnTime;

            }
            // Last state change was yesterday, so split the days
            else if (curTime >= midnightTime && self.lastStateChangeTime <= midnightTime){

                //yesterdays equiv burn time gets added to yesterday total time
                uint256 prevDayBurnTime = self.dailyEquivBurnTime+(((midnightTime-self.lastStateChangeTime)*((self.LEDDim*100)/256))/100);

                //Todays Equiv Burn from Midnight
                self.dailyEquivBurnTime = ((curTime-midnightTime)*((self.LEDDim*100)/256))/100;

                self.burnHourTracker[0] = prevDayBurnTime;
                //Move entire array down one by copying
                // TODO: Make sure this array is capped at 365 days
                self.burnHourTracker.pop();

                self.burnHourTracker.push(self.dailyEquivBurnTime);

            }


        }
    }
    /**
     * @dev update the Offset Time
     * @notice Update the clocks with the Offset Time
     * @param self LEDStorage object
     */
    function updateLastOffsetTime(LEDStorage storage self) public  {

        self.lastOffsetTime = now;

    }
    /**
     * @dev calculate the daily runtime
     * @notice Get the Daily runtime
     * @param self LEDStorage object
     */
    function getDailyRuntime(LEDStorage storage self) public view  returns (uint256 dailyRun) {

        return self.burnHourTracker[0];



    }
     /**
     * @dev calculate the weekly runtime
     * @notice Get the weekly runtime
     * @param self LEDStorage object
     */
    function getWeeklyRuntime(LEDStorage storage self) public view  returns (uint256 weeklyRun) {
        weeklyRun = 0;
        uint256 idxcheck = self.burnHourTracker.length;
        uint256 idxlen = 7;
        if ( idxcheck < 7){
            idxlen  = idxcheck;

        }
        for (uint256 i =0 ; i<idxlen; i++){
            weeklyRun = weeklyRun+self.burnHourTracker[i];
        }
        return weeklyRun;
    }
     /**
     * @dev calculate the monthly runtime
     * @notice Get the monthly runtime
     * @param self LEDStorage object
     */
    function getMonthlyRuntime(LEDStorage storage self) public view  returns (uint256 monthlyRun) {
        monthlyRun = 0;
        uint256 idxcheck = self.burnHourTracker.length;
        uint256 idxlen = 30;
        if ( idxcheck < 30){
            idxlen  = idxcheck;

        }

        for (uint256 i =0 ; i<idxlen; i++){
            monthlyRun = monthlyRun+self.burnHourTracker[i];
        }
        return monthlyRun;

    }
     /**
     * @dev calculate the yearly runtime
     * @notice Get the yearly runtime
     * @param self LEDStorage object
     */
    function getYearlyRuntime(LEDStorage storage self) public view  returns (uint256 yearlyRun) {
        yearlyRun = 0;
        uint256 idxcheck = self.burnHourTracker.length;
        uint256 idxlen = 365;
        if ( idxcheck < 365){
            idxlen  = idxcheck;

        }
        for (uint256 i =0 ; i<idxlen; i++){
          yearlyRun = yearlyRun+self.burnHourTracker[i];
        }
        return yearlyRun;

    }
     /**
     * @dev calculate the complete runtime
     * @notice Get the all runtime
     * @param self LEDStorage object
     */
    function getAllRuntime(LEDStorage storage self) public view  returns (uint256 alltimeRun) {
        return self.fullWattEquivBurnTime;
    }
    /**
     * @dev Get the current Dim value
     * @notice Get the LED Dim level (DALI)
     * @param self LEDStorage object
     */
     function getDim (LEDStorage storage self) public view returns (uint256 currentDim){
         return self.LEDDim;
     }
     /**
     * @dev Get the current State value
     * @notice Get the state (on / off)
     * @param self LEDStorage object
     */
     function getState (LEDStorage storage self) public view returns (bool currentState){
         return self.currentState;
     }
     /**
     * @dev Get the current wattage
     * @notice Get the LED Wattage in W
     * @param self LEDStorage object
     */
     function getWattage (LEDStorage storage self) public view returns (uint256 currentWattage){
         return self.LEDWattage;
     }
/**
     * @dev Get the current DALI short address (0-64)
     * @notice Get the DALI Short address
     * @param self LEDStorage object
     */
     function getDALIShortAddress (LEDStorage storage self) public view returns (uint256 currentDALIShort){
         return self.daliShortAddress;
     }
/**
     * @dev Get the current room address
     * @notice Get the current room address
     * @param self LEDStorage object
     */
     function getRoomContract (LEDStorage storage self) public view returns (address currentRoom){
         return self.roomContract;
     }
     /**
     * @dev Get the start date
     * @notice Get the start date of this LED
     * @param self LEDStorage object
     */
     function getStartDate (LEDStorage storage self) public view returns (uint256 startDate) {
         return self.startDate;
     }
     /**
     * @dev Get the last time this LED was offset
     * @notice Get the last offset date of this LED
     * @param self LEDStorage object
     */
     function getLastOffsetDate (LEDStorage storage self) public view returns (uint256 lastOffsetTime) {
         return self.lastOffsetTime;
     }

}
