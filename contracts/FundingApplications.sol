pragma solidity ^0.4.23;
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./Application.sol";


contract FundingApplications is AccessControl {
    using SafeMath for uint256;

    bool public applicationsOpen;
    bool public votingOpen;

    uint public applicationCost;

    uint public lastOpenApplicationsIndex;

    uint public votingStartIndex;
    uint public votingEndIndex;

    Proposal[] public proposals;

    address public opcTokenAddress;
    address public paymentPipeAddress;

    struct Proposal {
        address submissionAddress;
        address fundingApplicationAddress;
        string applicationName;
        string description; 
    }

    event ApplicationSubmitted(
        address submissionAddress,
        address fundingApplicationAddress,
        string applicationName,
        string description
    );

    event ApplicationCostUpdated(
        uint newCost
    );

    constructor(
        address pipeAddress, 
        address tokenAddress
    ) public {
        applicationsOpen = false;
        votingOpen = false;
        applicationCost = 4000000000000000 wei;
        lastOpenApplicationsIndex = 0;
        votingStartIndex = 0;
        votingEndIndex = 0;
        paymentPipeAddress = pipeAddress;
        opcTokenAddress = tokenAddress;
    }

    modifier applicationsAreOpen() {
        require(applicationsOpen == true);
        _;
    }

    modifier applicationsClosed() {
        require(applicationsOpen == false);
        _;
    }

    modifier votingIsOpen() {
        require(votingOpen == true);
        _;
    }

    modifier votingClosed() {
        require(votingOpen == false);
        _;
    }

    modifier meetsPaymentCriteria() {
        require(msg.value >= applicationCost);
        _;
    }

    function openApplications() external onlyCLevel applicationsClosed votingClosed {
        applicationsOpen = true;
        // this tracks the index to begin to interate over when opening contracts to votes
        votingStartIndex = proposals.length;
    }

    function closeApplications() external onlyCLevel applicationsAreOpen votingClosed {
        applicationsOpen = false;
        // this tracks the index to stop at when counting votes
        // TODO: should consider overflow and underflow here?!
        votingEndIndex = proposals.length;
    }

    function openVoting() external onlyCLevel votingClosed applicationsClosed {
        votingOpen = true;
        for (uint i = votingStartIndex; i < votingEndIndex; i++) {
            Application(proposals[i].fundingApplicationAddress).openApplicationToVoting();
        }
    }

    function closeVoting() external onlyCLevel applicationsClosed votingIsOpen {
        votingOpen = false;
        Proposal memory highestNumberOfVotes;
        uint proposalsArrayLength = proposals.length;
        for (uint i = lastOpenApplicationsIndex; i < proposalsArrayLength; i++) {
            Application(proposals[i].fundingApplicationAddress).closeApplicationToVoting();
            // funds should be allocated primarily to an application which has met targer *AND* has the highest number of votes
            // if none have met target, funds are allocated to the application with the highest number of votes

            // PSUEDO-CODE:

            // close each application to voting
            // check whether it is the highest votes
            // check whether is has met target
        }   
    }

    function setApplicationCostInWei(uint newCost) external onlyCLevel {
        applicationCost = newCost;
        emit ApplicationCostUpdated(newCost);
    }

    function submitApplication(
        string _applicationName, 
        string _description 
    ) 
    public
    payable
    whenNotPaused
    applicationsAreOpen
    meetsPaymentCriteria
    {
        Proposal memory proposal;
        proposal.submissionAddress = msg.sender;
        proposal.applicationName = _applicationName;
        proposal.description = _description;
        proposal.fundingApplicationAddress = new Application(
            this,
            msg.sender,
            _applicationName,
            _description,
            paymentPipeAddress,
            opcTokenAddress
        );
        proposals.push(proposal);

        emit ApplicationSubmitted(
            msg.sender,
            proposal.fundingApplicationAddress,
            _applicationName,
            _description
        );
    }
}