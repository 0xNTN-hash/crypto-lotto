# Crypto Lotto dApp

🚀 **Note:** I'm building my first stand-alone project—a decentralized crypto lottery dApp!

## Project Overview
The Crypto Lotto dApp is a decentralized lottery system built with Solidity, Chainlink VRF, and OpenZeppelin. Users can pick 6 numbers (ranging from 1 to 49) and participate for a chance to win the jackpot. Every participant receives a portion of the jackpot based on the number of matching numbers. Participants lotto tickets are NFTs, ensuring transparency and authenticity.

This project applies concepts learned from Cyfrin's Updraft courses and leverages blockchain technology to create a secure, transparent, and tamper-proof lottery system.

## Features
- **Pick 6 Numbers**: Users select 6 numbers between 1 and 49.
- **Random Number Generation**: Uses Chainlink VRF for true randomness.
- **Jackpot Distribution**: Jackpot is distributed to winners based on their matching numbers.
- **Uniqueness Check**: Ensures all picked numbers are unique and within the valid range.
- **Decentralized Execution**: Smart contracts handle number generation, validation, and prize distribution.

## Tech Stack
- **Solidity**: For writing secure and efficient smart contracts.
- **Chainlink VRF**: Ensures fair and tamper-proof randomness.
- **OpenZeppelin**: Provides reusable and secure contract templates.
- **Foundry**: Used for testing and deploying the contracts.
- **Frontend Tools**: UI/UX for the app is designed using [Uizard.io](https://uizard.io) for a clean and intuitive interface.

## How It Works
1. **User Participation**: Users interact with the dApp to choose 6 numbers and enter the lottery.
2. **Random Number Generation**: Chainlink VRF generates 6 random numbers after the entry period ends.
3. **Validation and Payouts**: The contract validates the winners and distributes the jackpot proportionally based on the number of matching numbers.

## Key Challenges Addressed
1. **Ensuring Uniqueness**: Filtering duplicate numbers from random results.
2. **Number Range Mapping**: Mapping Chainlink VRF random outputs to the 1-49 range.
3. **Gas Optimization**: Writing efficient logic for checking number uniqueness and prize distribution.

## Installation
1. Clone the repository:
    ```bash
    git clone <repository-url>
    cd crypto-lotto-dapp
    ```

2. Install Foundry:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3. Install dependencies:
    ```bash
    forge install
    ```

4. Compile contracts:
    ```bash
    forge build
    ```

5. Run tests:
    ```bash
    forge test
    ```

## Future Enhancements
- **UI Integration**: Build a sleek and responsive UI for users to interact with the dApp.
- **Multichain Support**: Deploy on multiple EVM-compatible chains.
- **Analytics Dashboard**: Show live statistics on participation and payouts.
- **Token Rewards**: Reward participants with tokens for joining the lottery.

## Acknowledgments
- **Cyfrin Updraft Course**: For teaching the foundational skills in Solidity and blockchain development.
- **Chainlink Documentation**: For providing insights on VRF integration.
- **OpenZeppelin**: For their robust library of contract templates.

---

🎰 **Decentralized lottery made simple. Let’s build and play together!**
