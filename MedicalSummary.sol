pragma solidity 0.6.0;

// ------------------------------------------------------------------------------------
// This contract allows for the storage of a brief medical summary consisting of a list
// of conditions, medications and allergies. Patients and providers (i.e. doctors and
// other health professionals) can register themselves, and patients are able to link
// providers in order to control who can modify and view their data. There are no
// restrictions on who can register as a provider and patients can nominate themselves
// as their own providers if they so wish. All the items are entered as free text. The 
// contract as it stands will not work in Remix, as each free text string needs to be
// converted into a bytes32 value by a front-end app for storage, and then back to a
// string for viewing.
// ------------------------------------------------------------------------------------

contract MedicalSummary {
    
    struct summary {
        bytes32[] conditions;
        bytes32[] medications;
        bytes32[] allergies;
    }
    
    mapping(address=>uint) patientMembership;
    mapping(address=>uint) providerMembership;
    mapping(address=>address[]) linkedProviders;
    mapping(address=>summary) patientSummary;
    uint memberCount;
    uint providerCount;
    uint entryCount;
    
    modifier onlyPatient {
        require(patientMembership[msg.sender]==1);
        _;
    }
    
    function checkLinkedProvider (address _pt, address _prov) internal view returns (bool) {
        bool answer = false;
        for (uint i=0; i<linkedProviders[_pt].length; i++) {
            if (linkedProviders[_pt][i] == _prov) {
                answer = true;
            }
        }
    }
    
    modifier onlyLinkedProvider (address _pt) {
        require(checkLinkedProvider(_pt, msg.sender) == true);
        _;
    }
    
    function registerPatient () public {
        require (patientMembership[msg.sender] == 0);
        patientMembership[msg.sender] = 1;
        memberCount++;
    }
    
    function registerProvider () public {
        require (providerMembership[msg.sender] == 0);
        providerMembership[msg.sender] = 1;
        providerCount++;
    }
    
    function linkProvider (address _prov) public onlyPatient {
        require(checkLinkedProvider(msg.sender, _prov) == false);
        require(providerMembership[_prov] == 1);
        linkedProviders[msg.sender].push(_prov);
    }
    
    function resetProviders () public onlyPatient {
        linkedProviders[msg.sender] = new address[] (0);
    }
    
    function viewLinkedProviders () public view onlyPatient returns (address[] memory) {
        return linkedProviders[msg.sender];
    }
    
    function addCondition (address _pt, bytes32 _condition) public onlyLinkedProvider (_pt) {
        patientSummary[_pt].conditions.push(_condition);
        entryCount++;
    }
    
    function addMedication (address _pt, bytes32 _medication) public onlyLinkedProvider (_pt) {
        patientSummary[_pt].medications.push(_medication);
        entryCount++;
    }
    
    function addAllergy (address _pt, bytes32 _allergy) public onlyLinkedProvider (_pt) {
        patientSummary[_pt].allergies.push(_allergy);
        entryCount++;
    }
    
    function deleteCondition (address _pt, uint _index) public onlyLinkedProvider (_pt) {
        require(_index < patientSummary[_pt].conditions.length);
        patientSummary[_pt].conditions[_index] = patientSummary[_pt].conditions[patientSummary[_pt].conditions.length - 1];
        patientSummary[_pt].conditions.pop();
        entryCount++;
    }
    
    function deleteMedication (address _pt, uint _index) public onlyLinkedProvider (_pt) {
        require(_index < patientSummary[_pt].medications.length);
        patientSummary[_pt].medications[_index] = patientSummary[_pt].medications[patientSummary[_pt].medications.length - 1];
        patientSummary[_pt].medications.pop();
        entryCount++;
    }
    
    function deleteAllergy (address _pt, uint _index) public onlyLinkedProvider (_pt) {
        require(_index < patientSummary[_pt].allergies.length);
        patientSummary[_pt].allergies[_index] = patientSummary[_pt].allergies[patientSummary[_pt].allergies.length - 1];
        patientSummary[_pt].allergies.pop();
        entryCount++;
    }
    
    function viewOwnSummary () public view onlyPatient returns (bytes32[] memory, bytes32[] memory, bytes32[] memory) {
        return (patientSummary[msg.sender].conditions, patientSummary[msg.sender].medications, patientSummary[msg.sender].allergies);
    }
    
    function viewPatientSummary (address _pt) public view onlyLinkedProvider (_pt) returns (bytes32[] memory, bytes32[] memory, bytes32[] memory) {
        return (patientSummary[_pt].conditions, patientSummary[_pt].medications, patientSummary[_pt].allergies);
    }
    
    function viewMemberCount () public view returns (uint) {
        return memberCount;
    }
    
    function viewProviderCount () public view returns (uint) {
        return providerCount;
    }
    
    function viewEntryCount () public view returns (uint) {
        return entryCount;
    }
    
}
