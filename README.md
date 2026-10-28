# Wordle On-Chain (Mini Version)

A decentralized, on-chain implementation of the Wordle word-guessing game built on Ethereum Sepolia testnet. Guess validation logic is executed securely via a smart contract, paired with a web frontend featuring an interactive $6 \times 5$ board and ephemeral session keys for popup-free gameplay.

---

## 1. Understanding Wordle On-Chain & Use Cases

In standard web-based Wordle, word validation occurs on a centralized backend server or client-side script where the solution can be inspected. Building Wordle on-chain establishes a trustless architecture:

### Key Advantages
- **Trustless & Tamper-Proof Execution**: The evaluation logic resides inside an immutable smart contract (`Wordle.sol`). Game rules cannot be altered mid-game.
- **Provable Fairness**: Every guess and its validation result are emitted as immutable events (`GuessResult`) on the Ethereum network, enabling independent auditing.
- **Decentralized State**: Operates independently of centralized web servers, eliminating server downtime and single points of failure.

### Potential Web3 Use Cases
- **GameFi Tournaments**: Smart contracts can pool entry fees into an escrow and automatically distribute prize pools to players solving words in the fewest turns.
- **On-Chain Achievements**: Successfully guessing words can trigger automated minting of soulbound dynamic NFTs representing player streaks.
- **Trustless Mini-Games**: Serves as a foundational model for on-chain trivia, puzzles, and verifiable interactive experiences.

---

## 2. Smart Contract Architecture (`Wordle.sol`)

- **Network**: Ethereum Sepolia Testnet (Chain ID: `11155111`)
- **Contract Address**: [`0x7A5f99F2616Cd2E4E6935d7b1dEe486724b1aDeb`](https://sepolia.etherscan.io/address/0x7A5f99F2616Cd2E4E6935d7b1dEe486724b1aDeb)
- **Compiler**: Solidity `^0.8.0`

### Validation Algorithm & Bit-Packing
The contract validates guesses against a target word (`APPLE`) using a two-pass algorithm to accurately handle duplicate characters:

1. **Type-Level Enforcement (`bytes5`)**: Accepting a fixed `bytes5` parameter enforces 5-byte length at the EVM ABI decoding level, eliminating the need for runtime length checks.
2. **First Pass (Green / Exact Matches)**: Matches characters at identical indices (`guess[i] == target[i]`). Sets position bits to prevent double-matching.
3. **Second Pass (Yellow / Misplaced Matches)**: For remaining unmatched characters, checks for occurrences in unflagged target positions.
4. **Gas-Efficient 2-Bit Result Encoding**:
   The status of all 5 letters is packed into a single 10-bit integer (`uint16`) emitted in the `GuessResult` event:
   - `0` (`00`): ⬛ Absent
   - `1` (`01`): 🟨 Misplaced
   - `2` (`10`): 🟩 Correct

   $$\text{result} = \sum_{i=0}^{4} (\text{status}_i \ll (i \times 2))$$

5. **Event Specification**:
   ```solidity
   event GuessResult(address player, bytes5 guess, uint16 result);
   ```

### Gas Optimizations
- **Bytecode Constant (`bytes5 constant`)**: Inlines the target word directly into runtime bytecode (`PUSH5`), saving ~2,100 gas by eliminating `SLOAD` storage operations.
- **Type-Level Validation**: Uses `bytes5` to avoid dynamic string decoding, calldata expansion, and runtime length reverts.
- **Unchecked Loop Increments (`unchecked { ++i; }`)**: Bypasses redundant integer overflow checks on loops bounded at 5 iterations.
- **Native Word Size (`uint256`)**: Employs 32-byte EVM registers for loop indices and bitmasks to avoid register truncation opcodes (`AND 0xff`).

---

## 3. Frontend Interface (`index.html`)

A single-page interface built with **Ethers.js (v5)** connecting directly to the Sepolia smart contract.

### Features
- **Ephemeral Session Key (Auto-Signing)**: Standard Web3 DApps require a MetaMask confirmation for every on-chain move. To eliminate this UX bottleneck, an ephemeral keypair is generated in `localStorage` and funded once (`0.005 Sepolia ETH`) via MetaMask. Subsequent guesses are signed automatically in the background.
- **$6 \times 5$ Interactive Board**: Replicates the classic Wordle layout. Letters render as you type and flip into their verified colors (`🟩`, `🟨`, `⬛`) upon event receipt.
- **Pre-Typing Support**: Players can type their next 5-letter word into the input while the current guess is confirming on-chain.
- **Race-Condition Safe Restart**: If a restart is triggered during an in-flight transaction, the interface awaits settlement before clearing state, preventing Ethereum nonce collisions.
- **Session Refund**: A "Refund Session" button sweeps any remaining burner wallet balance back to the player's primary MetaMask account.

---

## 4. Setup and Usage Instructions

### Prerequisites
1. Install the [MetaMask extension](https://metamask.io/).
2. Switch MetaMask network to **Sepolia Testnet**.
3. Ensure your wallet has Sepolia testnet ETH.

### Running Locally
1. Clone or download the repository files:
   - `Wordle.sol`
   - `index.html`
   - `README.md`
2. Open `index.html` in any web browser, or serve it locally:
   ```bash
   # Python 3
   python -m http.server 8000

   # Node.js
   npx serve .
   ```
3. Navigate to `http://localhost:8000` (or open `index.html` directly).

### Gameplay Walkthrough
1. Click **"Connect & Auto-Sign"** and approve the MetaMask connection.
2. Confirm the one-time funding prompt (`0.005 Sepolia ETH`) to activate background signing.
3. Type a 5-letter word and press <kbd>Enter</kbd> or click **Submit**.
4. The board updates with on-chain verification feedback:
   - 🟩 : Correct letter and position.
   - 🟨 : Letter is present in target word, wrong position.
   - ⬛ : Letter is absent from target word.
5. Players have up to **6 attempts** to solve the word. Click **Restart** to reset the board.
