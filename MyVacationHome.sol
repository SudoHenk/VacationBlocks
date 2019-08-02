pragma solidity ^0.5.10;

import "./ReservationAble.sol";
import "./DateLibrary.sol";

contract MyVacationHome is ReservationAble {
    using DateLibrary for uint;
    
    address owner;

    uint public reservationLength = 0;
    
    struct Reservation {
        bytes32 next;
        uint startDate;
        StayType duration;
        address sender;
        uint payed;
    }
    
    bytes32 public head;
    mapping (bytes32 => Reservation) public reservations;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public { 
        owner = msg.sender; 
    }
    
    function calculateEndOfStay(uint startDate, StayType duration) private pure returns (uint) {
        return startDate + mapStayTypeToDays(duration).getEpochTimeMsFromDays();
    }
    
    function mapStayTypeToDays(StayType duration) private pure returns (uint) {
        if(duration == StayType.WEEK) {
            return 7;
        } else if(duration == StayType.WEEKEND) {
            return 2;
        } else if(duration == StayType.LONG_WEEKEND) {
            return 3;
        } else if(duration == StayType.MIDWEEK) {
            return 5;
        } else if(duration == StayType.TWO_WEEKS) {
            return 14;
        } else if(duration == StayType.THREE_WEEKS) {
            return 21;
        } else if(duration == StayType.FOUR_WEEKS) {
            return 28;
        } else {
            return 0;
        }
    }
    
    function isReserveable(uint startDate, StayType duration) external view returns (bool) {
        validateReservationDateRules(startDate, duration);
        return isReserveableInternal(startDate, duration);
    }
    
    function isReserveableInternal(uint startDate, StayType duration) private view returns (bool) {
        bytes32 iter = head;
        bool available = true;
        uint endDate = calculateEndOfStay(startDate, duration);
        while(iter != 0) {
            uint iterStartDate = reservations[iter].startDate;
            uint iterEndDate = calculateEndOfStay(iterStartDate, reservations[iter].duration);
            available = (endDate <= iterStartDate) || (startDate >= iterEndDate);
            if(available == false) {
                break;
            }
            iter = reservations[iter].next;
        }
        return available;
    }
    
    function addReservation(uint startDate, StayType duration, bool isManual) private {
        Reservation memory reservation;
        if(isManual) {
            reservation = Reservation(head, startDate, duration, msg.sender, 0);
        } else {
            reservation = Reservation(head, startDate, duration, msg.sender, msg.value);
        }
        bytes32 id = keccak256(abi.encode(reservation.sender,reservation.payed,now,reservationLength));
        reservations[id] = reservation;
        head = id;
        reservationLength = reservationLength+1;
    }
    
    function reserve(uint startDate, StayType duration) external payable returns (bool) {
        validateReservationDateRules(startDate, duration);
        require(isReserveableInternal(startDate, duration) == true, "This reservation date is not available.");
        require(msg.value >= getReservationPriceInternal(startDate, duration), "This transaction does not contain enough ether to reserve this date.");
        addReservation(startDate, duration, false);
        return true;
    }
    
    /**
     * Checks if the given startDate does fit in our business rules.
     */
    function validateReservationDateRules(uint startDate, StayType duration) private view {
        // Can only reserve in the future
        require(startDate > now);
        uint startDateDayOfWeek = startDate.getDayOfWeek();
        if(duration == StayType.WEEKEND || duration == StayType.LONG_WEEKEND) {
             // (long) weekends can only be from Friday.
             require(startDateDayOfWeek == 5, "A long weekend can only be reserved from Friday-Monday.");
        } else if(duration == StayType.MIDWEEK) {
            // A midweek can only be reserved from monday.
            require(startDateDayOfWeek == 1, "A midweek can only be reserved from Monday-Friday.");
        } else {
            // Weeks can be only reserved on Monday or Friday
            require(startDateDayOfWeek == 1 || startDateDayOfWeek == 5, "Reservations can only start from Monday or Friday.");
        }
    }
    
    function blockDate(uint startDate, StayType duration) external onlyOwner returns (bool) {
        validateReservationDateRules(startDate, duration);
        require(isReserveableInternal(startDate, duration) == true, "This reservation date already blocked.");
        addReservation(startDate, duration, true);
        return true;
    }
    
    
    function getReservationPrice(uint startDate, StayType duration) external view returns (uint) {
        return getReservationPriceInternal(startDate, duration);
    }
    
    function getReservationPriceInternal(uint startDate, StayType duration) private view returns (uint) {
        return 50;
    }
    
    function getSMEBaseUrl() external view returns (string memory) {
        return "https://somemediadomain.com/solApi/v1/";
    }

    
    
}