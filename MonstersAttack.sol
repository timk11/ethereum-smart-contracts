pragma solidity ^0.8.0;

/// @title RPG
/// @author Tim Kirchler
/// @notice A role playing game based on the challenge outlined
///         at https://github.com/LedgerHQ/solidity-exercise

import "@openzeppelin/contracts/utils/Strings.sol";

contract MonstersAttack {
    /// The contract owner is able to spawn new bosses.
    /// Players can generate one character per address.
    /// Characters gain XP and levels by defeating bosses.
    /// Once a character reaches level 2, they can heal another character
    ///  who has been defeated at a cost of 25 XP.
    /// Once a character has reached level 3 they can use the Fireball
    ///  spell to inflict 100 points of damage on a boss.
    
    struct Boss {
        string name;
        int32 hp;
        uint32 damage;
        uint32 reward;
    }

    struct Character {
        address charOwner;
        string name;
        int32 hp;
        uint32 damage;
        uint32 xp;
        uint32 level;
        uint lastFireball;
    }

    address owner;
    Boss[] public bosses;
    Character[] public characters;
    mapping(address => uint) public charId;
    mapping(address => uint) public charCount;

    event NewBoss(uint bossId, string bossName, int32 hp, uint32 damage, uint32 reward);
    event DefeatedBoss(uint bossId, string bossName, uint victorId, string victorName);
    event DefeatedCharacter(uint characterId, string characterName, uint bossId, string bossName);
    event RevivedCharacter(uint characterId, string characterName, uint healerId, string healerName);
    event levelUp(uint characterId, string characterName, uint32 newLevel);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function spawnBoss(string memory _name, int32 _hp, uint32 _damage, uint32 _reward) public onlyOwner {
        bosses.push(Boss(_name, _hp, _damage, _reward));
        emit NewBoss(bosses.length - 1, _name, _hp, _damage, _reward);
    }

    function setupCharacter(string memory _name) public {
        require(charCount[msg.sender] == 0, "You already have a character");
        uint32 pseudorand = uint32(uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))));
        pseudorand = pseudorand % 10;
        characters.push(Character(msg.sender, _name, 200-int32(pseudorand)*5, 20+pseudorand, 0, 1, block.timestamp - 1 days));
        charId[msg.sender] = characters.length - 1;
        charCount[msg.sender] = 1;
    }

    function changeCharName(string memory _newName) public {
        require(charCount[msg.sender] == 1, "You don't have a character");
        uint id = charId[msg.sender];
        characters[id].name = _newName;
    }

    function listLiveBosses() public view returns(string memory) {
        string memory liveBosses;
        for (uint i = 0; i < bosses.length; i++) {
            if (bosses[i].hp > 0) {
                liveBosses = string(abi.encodePacked(liveBosses, string(abi.encodePacked(Strings.toString(i), ": ",
                bosses[i].name, " (", Strings.toString(uint32(bosses[i].hp)), " HP) | "))));
            }
        }
        return liveBosses;
    }

    function checkBossHP(uint _bossID) public view returns(string memory) {
        require(_bossID < bosses.length, "No such boss exists");
        string memory message;
        if (bosses[_bossID].hp > 0) {
            message = string(abi.encodePacked(bosses[_bossID].name, " has ",
            Strings.toString(uint32(bosses[_bossID].hp)), " HP"));
        } else {
            message = string(abi.encodePacked(bosses[_bossID].name, " has been defeated"));
        }
        return message;
    }
    
    function attackBoss(uint _whichBossToAttack) public returns(string memory) {
        require(charCount[msg.sender] ==1, "You don't have a character");
        uint id = charId[msg.sender];
        require(characters[id].hp > 0, "Your character is out of HP");
        require(_whichBossToAttack < bosses.length, "No such boss exists");
        require(bosses[_whichBossToAttack].hp > 0, "This boss has already been defeated");
        string memory message;
        bosses[_whichBossToAttack].hp -= int32(characters[id].damage);
        characters[id].hp -= int32(bosses[_whichBossToAttack].damage);
        if (bosses[_whichBossToAttack].hp > 0 && characters[id].hp > 0) {
            message = string(abi.encodePacked(bosses[_whichBossToAttack].name, " has lost ",
            Strings.toString(characters[id].damage), " HP and now has ",
            Strings.toString(uint32(bosses[_whichBossToAttack].hp)), " HP left\nYour character has lost ",
            Strings.toString(uint32(bosses[_whichBossToAttack].damage)), " HP and now has ",
            Strings.toString(uint32(characters[id].hp)), " HP left"));
        } else if (bosses[_whichBossToAttack].hp <= 0 && characters[id].hp > 0) {
            message = string(abi.encodePacked("You have defeated ",
            bosses[_whichBossToAttack].name, "!\nYour character has lost ",
            Strings.toString(uint32(bosses[_whichBossToAttack].damage)), " HP and now has ",
            Strings.toString(uint32(characters[id].hp)), " HP left"));
            characters[id].xp += bosses[_whichBossToAttack].reward;
            emit DefeatedBoss(_whichBossToAttack, bosses[_whichBossToAttack].name, id, characters[id].name);
        } else if (bosses[_whichBossToAttack].hp > 0 && characters[id].hp <= 0) {
            message = string(abi.encodePacked("You have been defeated!\n",
            bosses[_whichBossToAttack].name, " has lost ", Strings.toString(characters[id].damage),
            " HP and now has ", Strings.toString(uint32(bosses[_whichBossToAttack].hp)), " HP left"));
            emit DefeatedCharacter(id, characters[id].name, _whichBossToAttack, bosses[_whichBossToAttack].name);
        } else {
            message = string(abi.encodePacked("You have defeated ",
            bosses[_whichBossToAttack].name, "!\nUnfortunately ",
            bosses[_whichBossToAttack].name, " has also defeated you"));
            emit DefeatedBoss(_whichBossToAttack, bosses[_whichBossToAttack].name, id, characters[id].name);
            emit DefeatedCharacter(id, characters[id].name, _whichBossToAttack, bosses[_whichBossToAttack].name);
        }
        if (characters[id].xp >= characters[id].level * 100) {
            characters[id].xp = characters[id].level *100;
            characters[id].level += 1;
            message = string(abi.encodePacked(message, "\nCongratulations! You have now reached level ",
            Strings.toString(characters[id].level)));
            emit levelUp(id, characters[id].name, characters[id].level);
        }
        return message;
    }

    function useFireball(uint _whichBossToAttack) public returns(string memory) {
        require(charCount[msg.sender] ==1, "You don't have a character");
        uint id = charId[msg.sender];
        require(characters[id].hp > 0, "Your character is out of HP");
        require(_whichBossToAttack < bosses.length, "No such boss exists");
        require(bosses[_whichBossToAttack].hp > 0, "This boss has already been defeated");
        require(characters[id].level >= 3, "You need to be at level 3 before using Fireball");
        require(characters[id].lastFireball + 1 days <= block.timestamp, "Your Fireball spell has not yet recharged");
        string memory message;
        bosses[_whichBossToAttack].hp -= 100;
        characters[id].hp -= int32(bosses[_whichBossToAttack].damage);
        characters[id].lastFireball = block.timestamp;
        if (bosses[_whichBossToAttack].hp > 0 && characters[id].hp > 0) {
            message = string(abi.encodePacked(bosses[_whichBossToAttack].name, " has lost 100 HP and now has ",
            Strings.toString(uint32(bosses[_whichBossToAttack].hp)), " HP left\nYour character has lost ",
            Strings.toString(uint32(bosses[_whichBossToAttack].damage)), " HP and now has ",
            Strings.toString(uint32(characters[id].hp)), " HP left"));
        } else if (bosses[_whichBossToAttack].hp <= 0 && characters[id].hp > 0) {
            message = string(abi.encodePacked("You have defeated ",
            bosses[_whichBossToAttack].name, "!\nYour character has lost ",
            Strings.toString(uint32(bosses[_whichBossToAttack].damage)), " HP and now has ",
            Strings.toString(uint32(characters[id].hp)), " HP left"));
            characters[id].xp += bosses[_whichBossToAttack].reward;
        } else if (bosses[_whichBossToAttack].hp > 0 && characters[id].hp <= 0) {
            message = string(abi.encodePacked("You have been defeated!\n",
            bosses[_whichBossToAttack].name, " has lost 100 HP and now has ",
            Strings.toString(uint32(bosses[_whichBossToAttack].hp)), " HP left"));
            emit DefeatedCharacter(id, characters[id].name, _whichBossToAttack, bosses[_whichBossToAttack].name);
        } else {
            message = string(abi.encodePacked("You have defeated ",
            bosses[_whichBossToAttack].name, "!\nUnfortunately ",
            bosses[_whichBossToAttack].name, " has also defeated you"));
            emit DefeatedBoss(_whichBossToAttack, bosses[_whichBossToAttack].name, id, characters[id].name);
            emit DefeatedCharacter(id, characters[id].name, _whichBossToAttack, bosses[_whichBossToAttack].name);
        }
        if (characters[id].xp >= characters[id].level * 100) {
            characters[id].xp = characters[id].level *100;
            characters[id].level += 1;
            message = string(abi.encodePacked(message, "\nCongratulations! You have now reached level ",
            Strings.toString(characters[id].level)));
            emit levelUp(id, characters[id].name, characters[id].level);
        }
        return message;
    }

    function healSomeone(uint _characterToHealID) public returns(string memory) {
        uint id = charId[msg.sender];
        require(_characterToHealID != id, "You can't heal yourself");
        require(characters[id].xp >= 100, "You need to be at level 2 and above 100 XP before using Healing");
        require(_characterToHealID < characters.length, "This character ID is not in use");
        require(characters[_characterToHealID].hp <= 0, "This character is not yet defeated");
        characters[_characterToHealID].hp = 150;
        characters[id].xp -= 25;
        string memory message = string(abi.encodePacked(characters[_characterToHealID].name, " has been revived"));
        emit RevivedCharacter(_characterToHealID, characters[_characterToHealID].name, id, characters[id].name);
        return message;
    }

    function bossCount() public view returns(uint) {
        return bosses.length;
    }

    function characterCount() public view returns(uint) {
        return characters.length;
    }

    function myStats() public view returns(string memory) {
        require(charCount[msg.sender] ==1, "You don't have a character");
        uint id = charId[msg.sender];
        uint nextFireball;
        if (characters[id].lastFireball + 1 days < block.timestamp) {
            nextFireball = 0;
        } else {
            nextFireball = (characters[id].lastFireball + 1 days - block.timestamp) / 60;
        }
        string memory message = string(abi.encodePacked("Name: ", characters[id].name, "\nID: ",
        Strings.toString(id), "\nHP: ", Strings.toString(uint32(characters[id].hp)), "\nXP: ",
        Strings.toString(characters[id].xp), "\nLevel: ", Strings.toString(characters[id].level), "\nDamage: ",
        Strings.toString(characters[id].damage), " \nMinutes to next fireball: ", Strings.toString(nextFireball)));
        return message;
    }

}
