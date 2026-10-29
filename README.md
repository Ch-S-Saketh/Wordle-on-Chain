# Wordle On-Chain (Mini Version)

An on-chain Wordle on the Ethereum Sepolia testnet. A smart contract (`Wordle.sol`) checks each guess and publishes the result as an event. A single-page frontend (`index.html`) shows a 6 x 5 board and uses a temporary session key so players don't need a MetaMask popup for every guess.

---

## 1. Why Wordle On-Chain?

In normal Wordle, a server or script checks your guess and you must trust it. With a smart contract:
- **Tamper-proof rules:** The deployed contract cannot be edited, so the rules for green / yellow / gray cannot change mid-game.
- **Publicly auditable results:** Every guess and result is emitted as a `GuessResult` event that anyone can read on-chain.
- **No game server:** The checking logic runs on the Ethereum network, so there is no backend to go down.

**Possible use cases:** tournaments where a contract holds entry fees and pays the fastest solver, NFT badges for solve streaks, and other verifiable on-chain puzzles or trivia.

---

## 2. Smart Contract (`Wordle.sol`)

- **Network:** Ethereum Sepolia Testnet (Chain ID 11155111)
- **Contract:** [`0x7A5f99F2616Cd2E4E6935d7b1dEe486724b1aDeb`](https://sepolia.etherscan.io/address/0x7A5f99F2616Cd2E4E6935d7b1dEe486724b1aDeb)
- **Compiler:** Solidity `^0.8.0`

### How a guess is checked
The contract compares the guess to the pre-set target word (`APPLE`) in two passes, so repeated letters are handled correctly:
1. **Input:** The guess is a `bytes5`, so the EVM itself enforces exactly 5 bytes.
2. **Pass 1, green:** Mark letters in the same position in guess and target, and mark those target positions as used.
3. **Pass 2, yellow:** For each remaining guess letter, look for the same letter in an unused target position. If found, mark it yellow and mark that target position as used.
4. **Result:** The 5 results are packed into one `uint16`, 2 bits per letter: `0` gray (absent), `1` yellow (misplaced), `2` green (correct).

$$\text{result} = \sum_{i=0}^{4} (\text{status}_i \ll (i \times 2))$$

Event read by the frontend to color the tiles:
```solidity
event GuessResult(address player, bytes5 guess, uint16 result);
```

### Gas optimizations
- **`bytes5 constant`:** The target word lives in the contract code, not storage, avoiding a storage read (about 2,100 gas).
- **`bytes5` input:** No dynamic string decoding or runtime length check.
- **`unchecked { ++i; }`:** Skips overflow checks on loop counters that never exceed 5.
- **`uint256` indexes and bitmasks:** Matches the EVM's native 32-byte word size.

---

## 3. Frontend (`index.html`)

A single page using Ethers.js v5 that talks directly to the contract.

- **Session key (auto-signing):** A temporary wallet key is created in the browser (`localStorage`) and funded once with 0.005 Sepolia ETH through MetaMask. After that, guesses are signed automatically.
- **Network check:** The page verifies MetaMask is on Sepolia before sending any funds.
- **6 x 5 board:** Letters appear as you type and turn green / yellow / gray when the result event arrives.
- **Pre-typing:** You can type your next word while the current guess confirms.
- **Safe restart:** Restarting during an in-flight transaction waits for it to finish, avoiding nonce errors.
- **Refund Session:** Sends leftover ETH from the session wallet back to MetaMask.

---

## 4. Setup and Usage

- **Prerequisites:** the [MetaMask extension](https://metamask.io/), set to the Sepolia Testnet, with some Sepolia test ETH from a faucet.
- **Run locally:** download `Wordle.sol`, `index.html` and `README.md`, then open `index.html` in a browser or serve it:
  ```bash
  python -m http.server 8000 # or: npx serve .
  ```
  Open `http://localhost:8000`.

### How to play
1. Click **"Connect & Auto-Sign"** and approve the connection.
2. Approve the one-time funding transaction (0.005 Sepolia ETH) to the session wallet.
3. Type a 5-letter word and press <kbd>Enter</kbd> or click **Submit**.
4. When the transaction confirms, tiles show:
   - 🟩 : Correct position
   - 🟨 : Letter in the word but wrong position
   - ⬛ : Letter not in the word
5. You have 6 guesses. Click **Restart** for a new board.

**Note:** Testnet only. The session key is stored unencrypted in the browser, which is fine for test ETH but not real funds. Use **Refund Session** before clearing browser data.

---

## 5. Known Limitations & Future Work

- **The target word is public:** Everything on a public blockchain is readable, so `APPLE` can be read from the contract code on Etherscan. This project demonstrates on-chain validation against a pre-set word, not a hidden answer. A real fix is zero-knowledge proofs (ZK Wordle): the owner publishes only a hash of the word, and each result comes with a proof that it is correct for the committed word, so the contract can verify results without learning the word.
- **Game rules live in the browser:** The contract stores no game state. The 6-guess limit and Restart exist only in `index.html`, and the contract does not record who won. A future version would track attempts and solved status per player on-chain.
- **Other ideas:** accept only real dictionary words (for example via a Merkle proof of a word list) and add contract tests for repeated-letter cases like `PPPPP` and `ALLEE`.
