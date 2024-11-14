const { ethers } = require('ethers');
require('dotenv').config();

// ABI of a simple storage contract
const contractABI = [
    "function placeBet(address receiver, uint256 amount, uint8 tier) external returns (uint256)",
    "function getBetInfoById(uint256 betId) external view returns (tuple(address requester, address receiver, uint8 tier, uint8 status, uint256 amount, uint256 points, uint256 reward, uint256 timestamp, bool win, bool claimed))",
    "function getMinBetAmount() external view returns (uint256)"
];

const BetTier = {
    0: "Bronze",
    1: "Silver",
    2: "Gold",
    3: "Diamond"
};

const BetStatus = {
    0: "Unknown",
    1: "Pending",
    2: "Resolved",
    3: "Canceled"
};


const contractAddress = "0xec6be1d0c53489de129b2c13ac3edb393865c22f";
const RPC_URL = `https://saigon-archive.roninchain.com/rpc`;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

async function main() {
    let betId = 1;
    try {
        // Connect to the network
        const provider = new ethers.JsonRpcProvider(RPC_URL);
        const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

        // 1. Send RON Transaction
        async function sendTransaction() {
            const tx = {
                to: '0xEf46169CD1e954aB10D5e4C280737D9b92d0a936',
                value: ethers.parseEther("1"),
            };

            const transaction = await wallet.sendTransaction(tx);
            await transaction.wait();
            console.log("Transaction confirmed");
            console.log("Check transaction on https://saigon-app.roninchain.com/tx/" + transaction.hash);
        }

        // 2. Interact with Contract
        const contract = new ethers.Contract(contractAddress, contractABI, wallet);

        // Read from contract
        async function readContract(id) {
            const betInfo = await contract.getBetInfoById(id);
            const mappedBetInfo = {
                requester: betInfo[0],
                receiver: betInfo[1],
                tier: BetTier[betInfo[2]],
                status: BetStatus[betInfo[3]],
                amount: betInfo[4],
                points: betInfo[5],
                reward: betInfo[6],
                timestamp: betInfo[7],
                win: betInfo[8],
                claimed: betInfo[9]
            };
            console.log("Bet info:", mappedBetInfo);
        }

        async function writeContract() {
            const minBetAmount = await contract.getMinBetAmount();
            const tx = await contract.placeBet(
                wallet.address,
                minBetAmount + BigInt(1),
                1
            );
            await tx.wait();
            console.log("Transaction confirmed");
            console.log("Check transaction on https://saigon-app.roninchain.com/tx/" + tx.hash);
        }

        // Execute all operations
        console.log("Sending RON...");
        await sendTransaction();

        console.log("\nReading contract...");
        await readContract(6);

        console.log("\nWriting to contract...");
        await writeContract();

    } catch (error) {
        console.error("Error:", error);
    }
}

main();
