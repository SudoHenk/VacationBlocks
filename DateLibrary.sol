pragma solidity ^0.5.10;


library DateLibrary {
    
    uint constant MILLI_SECONDS_IN_DAY = (24 * 60 * 60 * 1000);
    
    /**
     * Retrieve the day of the week for any given EPOCH time.
     * 1 = Monday
     * 2 = Tuesday
     * 3 = Wednesday
     * 4 = Thursday
     * 5 = Friday
     * 6 = Saturday
     * 7 = Sunday 
     */
    function getDayOfWeek(uint epochTimeMs) internal pure returns (uint) {
        uint epochDays = epochTimeMs / MILLI_SECONDS_IN_DAY;
        return (epochDays+3) % 7 + 1;
    }
    
    /**
     * Returns the ms based on the amount of days.
     */
    function getEpochTimeMsFromDays(uint epochDays) internal pure returns (uint) {
        return epochDays * MILLI_SECONDS_IN_DAY;
    }
}