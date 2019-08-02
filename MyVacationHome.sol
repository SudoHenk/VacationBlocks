pragma solidity ^0.5.10;

import "./ReservationAble.sol";
import "./DateTimeLibrary.sol";

contract MyVacationHome is ReservationAble {
    // using the DateTimeLibrary on epoch timestamps.
    using DateTimeLibrary for uint;
    
    // The deployer of this contract.
    address owner;

    // Linkedlist length + salt
    uint public reservationLength = 0;
    
    // Struct for our linkedlist that stores the reservations.
    struct Reservation {
        bytes32 next;
        uint startDate;
        StayType duration;
        address sender;
        uint payed;
    }
    
    // Head of the linkedlist
    bytes32 public head;
    // Mapping of the linkedlist
    mapping (bytes32 => Reservation) public reservations;
    
    // Modifier for privileged contract owner methods.
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    // constructor of contract
    constructor() public { 
        owner = msg.sender; 
    }
    
    // ---------------------------------
    //      EXTERNAL METHODS
    // ---------------------------------
    
    /**
     * Checks if the given timespan (startDate + duration) can be reserved.
     */
    function isReserveable(uint startDate, StayType duration) external view returns (bool) {
        validateReservationDateRules(startDate, duration);
        return isReserveableInternal(startDate, duration);
    }
    
    /**
     * Get the price (in wei) for the period that needs to be paid for an reservation.
     */
    function getReservationPrice(uint startDate, StayType duration) external view returns (uint) {
        return getReservationPriceInternal(startDate, duration);
    }
    
    /**
     * Make a reservation for the timespan from startDate till startDate + duration.
     * Note that this method is payable, and needs at least the price given by "getReservationPrice", in wei.
     */
    function reserve(uint startDate, StayType duration) external payable returns (bool) {
        validateReservationDateRules(startDate, duration);
        require(isReserveableInternal(startDate, duration) == true, "This reservation date is not available.");
        require(msg.value >= getReservationPriceInternal(startDate, duration), "This transaction does not contain enough ether to reserve this date.");
        addReservation(startDate, duration, false);
        return true;
    }
    
    // ---------------------------------
    //      INTERNAL METHODS
    // ---------------------------------
    
    /**
     *  Get the enddate (in ms. epoch) of a stay.
     */
    function calculateEndOfStay(uint startDate, StayType duration) private pure returns (uint) {
        return startDate + mapStayTypeToDays(duration).getEpochTimeMsFromDays();
    }
    
    /**
     * Map the enumeration "StayType" to an uint days.
     */
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
    
    /**
     * Method that validates if the given startDate and duration can be reserved:
     * - Does not conflict with existing reservations
     * - Does not conflict with blocked dates
     */
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
    
    /**
     * Store a reservation in our internal contract.
     */
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
    
    /**
     * Remove a reservation from our internal contract.
     */
    function removeReservation(uint startDate, StayType duration, address sender) private {
        bytes32 iter = head;
        Reservation prevReservation = null;
        while(iter != 0) {
            if(reservations[iter].startDate == startDate && reservations[iter].duration == duration && reservations[iter].sender == sender) {
                if(prevReservation == null) {
                    head = reservations[iter].next;
                } else {
                    prevReservation.next = reservations[iter].next;
                }
                delete reservations[iter];
                reservationLength = reservationLength - 1;
                break;
            }
            prevReservation = reservations[iter];
            iter = reservations[iter].next;
        }
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
    
    /**
     * Determine the price for the given startDate and duration.
     * in wei.
     */
    function getReservationPriceInternal(uint startDate, StayType duration) private view returns (uint) {
        return 50;
    }
    
    // ---------------------------------
    //       OWNER CONTRACT METHODS
    // ---------------------------------
    
    /**
     * Make sure a certain timespan cannot be reserved by storing this "blocked date".
     */
    function blockDate(uint startDate, StayType duration) external onlyOwner {
        validateReservationDateRules(startDate, duration);
        require(isReserveableInternal(startDate, duration) == true, "This reservation is date already blocked.");
        addReservation(startDate, duration, true);
    }
    
    /**
     * Remove a blocked timespan.
     * Note that this only removes "blocked dates" or reservations made by the contract owner, not any arbitrary reservation.
     */
    function unblockDate(uint startDate, StayType duration) external onlyOwner {
        removeReservation(startDate, duration, self.sender);
    }
    
    /**
     * Withdraw earnings from the contract.
     */
    function withdraw(uint amount) external onlyOwner {
        msg.sender.transfer(amount);
    }
    
    // ---------------------------------
    //       METADATA CONTRACT METHODS
    // ---------------------------------
    
    /**
     * Get the SME Base Url, from where rich media will be retrieved.
     */
    function getSMEBaseUrl() external view returns (string memory) {
        return "https://somemediadomain.com/solApi/v1/";
    }

    
    
}