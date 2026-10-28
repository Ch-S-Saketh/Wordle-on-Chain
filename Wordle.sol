pragma solidity ^0.8.0;

contract Wordle {
    bytes5 private constant TARGET_WORD = "APPLE";

    event GuessResult(address player, bytes5 guess, uint16 result);

    function guessWord(bytes5 _guess) external {
        uint16 result = 0;
        uint256 targetUsed = 0;
        uint256 guessMatched = 0;

        for (uint256 i = 0; i < 5;) {
            if (_guess[i] == TARGET_WORD[i]) {
                result |= uint16(2 << (i * 2));
                targetUsed |= (1 << i);
                guessMatched |= (1 << i);
            }
            unchecked { ++i; }
        }

        for (uint256 i = 0; i < 5;) {
            if ((guessMatched & (1 << i)) == 0) {
                bytes1 gChar = _guess[i];
                for (uint256 j = 0; j < 5;) {
                    if ((targetUsed & (1 << j)) == 0 && gChar == TARGET_WORD[j]) {
                        result |= uint16(1 << (i * 2));
                        targetUsed |= (1 << j);
                        break;
                    }
                    unchecked { ++j; }
                }
            }
            unchecked { ++i; }
        }

        emit GuessResult(msg.sender, _guess, result);
    }
}
