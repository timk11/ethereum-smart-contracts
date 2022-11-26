pragma solidity 0.5.2;

// ----------------------------------------------------------------------------------
// This is a rudimentary contract which allows users to keep a record of their weight
// and look up any past entries. A single function to return a user's full dataset
// would be ideal, but as Solidity does not yet allow an array of structs to be
// called from a function, the various functions below allow individual datapoints to
// be called. Time is recorded as a block timestamp, which a front-end app could
// potentially convert into a date and time in order to tabulate or graph a user's
// weight progression over time. Weight could be entered as multiples of 0.01kg, so
// a front-end app could multiply by 100 to store it as a uint16, giving a usable
// range of 0kg to 655.35kg. 
// ----------------------------------------------------------------------------------

contract WeightTracker {
    
    struct timeWeight {
        uint16 weight;
        uint256 time;
    }
    
    mapping(address=>uint) membership;
    mapping(address=>timeWeight[]) weightRecord;
    uint memberCount;
    
    modifier onlyMember {
        require(membership[msg.sender]==1);
        _;
    }
    
    function register() public {
        require (membership[msg.sender] == 0);
        membership[msg.sender] = 1;
        memberCount++;
    }
    
    function enterWeight(uint16 _wt) onlyMember public {
        weightRecord[msg.sender].push(timeWeight({
            weight:_wt,
            time:now
        }));
    }
    
    function viewLastWeight() onlyMember public view returns (uint16) {
        return weightRecord[msg.sender][weightRecord[msg.sender].length - 1].weight;
    }
    
    function viewLastTime() onlyMember public view returns (uint256) {
        return weightRecord[msg.sender][weightRecord[msg.sender].length - 1].time;
    }
    
    function numberOfEntries() onlyMember public view returns (uint) {
        return weightRecord[msg.sender].length;
    }
    
    function viewLastEntry() onlyMember public view returns (uint16, uint256) {
        uint16 lastWeight = weightRecord[msg.sender][weightRecord[msg.sender].length - 1].weight;
        uint256 lastTime = weightRecord[msg.sender][weightRecord[msg.sender].length - 1].time;
        return (lastWeight, lastTime);
    }
    
    function viewEntry(uint _index) onlyMember public view returns (uint16, uint256) {
        require (_index < weightRecord[msg.sender].length);
        uint16 Weight = weightRecord[msg.sender][_index].weight;
        uint256 Time = weightRecord[msg.sender][_index].time;
        return (Weight, Time);
    }
    
    function viewMemberCount() public view returns (uint) {
        return memberCount;
    }
    
}
