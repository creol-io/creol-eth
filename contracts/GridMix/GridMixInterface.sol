
pragma solidity ^0.5.0;
/**
 * 
 * 
 * 
 *   @title GridMixInterface v0.0.1
 ________  ________  _______   ________  ___          
|\   ____\|\   __  \|\  ___ \ |\   __  \|\  \         
\ \  \___|\ \  \|\  \ \   __/|\ \  \|\  \ \  \        
 \ \  \    \ \   _  _\ \  \_|/_\ \  \\\  \ \  \       
  \ \  \____\ \  \\  \\ \  \_|\ \ \  \\\  \ \  \____  
   \ \_______\ \__\\ _\\ \_______\ \_______\ \_______\
    \|_______|\|__|\|__|\|_______|\|_______|\|_______|
                                             
 
 
 * 
 * 

   _____      _     _ __  __ _      _____       _             __               
  / ____|    (_)   | |  \/  (_)    |_   _|     | |           / _|              
 | |  __ _ __ _  __| | \  / |___  __ | |  _ __ | |_ ___ _ __| |_ __ _  ___ ___ 
 | | |_ | '__| |/ _` | |\/| | \ \/ / | | | '_ \| __/ _ \ '__|  _/ _` |/ __/ _ \
 | |__| | |  | | (_| | |  | | |>  < _| |_| | | | ||  __/ |  | || (_| | (_|  __/
  \_____|_|  |_|\__,_|_|  |_|_/_/\_\_____|_| |_|\__\___|_|  |_| \__,_|\___\___|
                                                                               
                                                                               

                                    
* @author Joshua Bijak 
* Date:       February 18,2020 
* @notice Grid Mix API Pulling Contract Interface
* @dev Oracle Contract that pulls grid mix data using Provable 
 
* 
* 
*           
* 
*/

interface GridMixInterface {
    
    event LogNewProvableQuery(string description);
    event newGridIntensity(string result);
    
    function __callback(bytes32 _myid, string calldata _result, bytes calldata _proof) external;
    function comp_request(string calldata _query, string calldata _method, string calldata _url, string calldata _kwargs) external payable;
    /**
     * @notice ASks Co2signal.com for a gridMix value of UK grid. Uses a default API Key
     * @dev This is hardcoded but subject to change
     * @param countryCode Country Code to Query GridMix
     */ 

    function requestCO2Signal(string calldata countryCode) external payable;
}