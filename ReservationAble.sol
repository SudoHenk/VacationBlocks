pragma solidity ^0.5.10;

contract ReservationAble {
    
    enum StayType {
        WEEK,
        WEEKEND,
        LONG_WEEKEND,
        MIDWEEK,
        TWO_WEEKS,
        THREE_WEEKS,
        FOUR_WEEKS
    }
    
    function getReservationPrice(uint startDate, StayType duration) external view returns (uint);
    
    function isReserveable(uint startDate, StayType duration) external view returns (bool);
    
    function reserve(uint startDate, StayType duration) external payable returns (bool);
    
    /**
     * Simple Media Endpoint base URL.
     */
    function getSMEBaseUrl() external view returns (string memory);
    
}