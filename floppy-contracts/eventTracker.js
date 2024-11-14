const ethers = require('ethers');
require('dotenv').config();
const fs = require('fs');

const contractABI = [
    "event Transfer(address indexed _from, address indexed _to, uint256 _value)"
];
let totalFees = BigInt(0);
let totalId0Blueprints = 0;
let totalId1Blueprints = 0;
let eventCount = 0;
let totalTxHashes = 0;
let lastBlockTracked = 0;
let allTxHashes = [];
async function getDistributedEvents() {
    try {
        const provider = new ethers.JsonRpcProvider("https://api-archived.roninchain.com/rpc");
        const contractAddress = "0x97a9107c1793bc407d6f527b77e7fff4d812bece";
        const contract = new ethers.Contract(contractAddress, contractABI, provider);

        const currentBlock = await provider.getBlockNumber();
        console.log("Current block:", currentBlock);

        // Define block range
        const fromBlock = 39246306;
        const toBlock = currentBlock;
        const BATCH_SIZE = 499; // Adjust based on RPC provider limits

        // Calculate number of batches needed
        const totalBlocks = toBlock - fromBlock;
        const batchCount = Math.ceil(totalBlocks / BATCH_SIZE);

        const writeTxHashes = (txHashes) => {
            const filePath = 'transactionHashes.txt';
            fs.writeFile(filePath, txHashes.join('\n'), (err) => {
                if (err) {
                    console.error('Error writing to file:', err);
                }
            });
        }


        // Process in batches
        for (let i = 0; i < batchCount; i++) {
            const start = fromBlock + (i * BATCH_SIZE);
            const end = Math.min(start + BATCH_SIZE - 1, toBlock);

            console.log(`Fetching batch ${i + 1}/${batchCount} (blocks ${start} to ${end})`);

            const filter = {
                address: contractAddress,
                fromBlock: start,
                topics: [
                    ethers.id("Transfer(address,address,uint256)") // Updated event signature
                ],
                toBlock: end
            };

            const logs = await provider.getLogs(filter);

            const events = logs.map(log => {
                let parsed = contract.interface.parseLog(log);
                if (parsed.args[1] === '0x245db945c485b68fDc429E4F7085a1761Aa4d45d') {
                    allTxHashes.push(log.transactionHash);
                    totalTxHashes++;
                }
            });
            // Optional: Add delay between batches to avoid rate limiting
            if (i < batchCount - 1) {
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            console.log("totalTxHashes in batch", totalTxHashes);
            lastBlockTracked = end;
        }

        console.log(`\nTotal events found: ${eventCount}`);
        console.log(`Last block: ${lastBlockTracked}`);
        writeTxHashes(allTxHashes);
        

    } catch (error) {
        writeTxHashes(allTxHashes);
        console.log("lastBlockTracked", lastBlockTracked);
        console.error("Error:", error);
    }
}

// Execute
getDistributedEvents()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

