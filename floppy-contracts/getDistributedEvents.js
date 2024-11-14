const ethers = require('ethers');
require('dotenv').config();

const contractABI = [
    "event Distributed(address indexed recipient, uint256 commissionAmount)"
];
let totalAmount = BigInt(0);
let eventCount = 0;
let lastBlockTracked = 0;
async function getDistributedEvents() {
    try {
        const provider = new ethers.JsonRpcProvider("https://api-archived.roninchain.com/rpc");
        const contractAddress = "0x1bece3a948c14eefbaace67fe6f51cd21b79aa21";
        const contract = new ethers.Contract(contractAddress, contractABI, provider);

        const currentBlock = await provider.getBlockNumber();
        console.log("Current block:", currentBlock);

        // Define block range
        const fromBlock = 39833407;
        const toBlock = currentBlock;
        const BATCH_SIZE = 499; // Adjust based on RPC provider limits

        // Calculate number of batches needed
        const totalBlocks = toBlock - fromBlock;
        const batchCount = Math.ceil(totalBlocks / BATCH_SIZE);


        // Process in batches
        for (let i = 0; i < batchCount; i++) {
            const start = fromBlock + (i * BATCH_SIZE);
            const end = Math.min(start + BATCH_SIZE - 1, toBlock);

            console.log(`Fetching batch ${i + 1}/${batchCount} (blocks ${start} to ${end})`);

            const filter = {
                address: contractAddress,
                topics: [
                    ethers.id("Distributed(address,uint256)") // event signature
                ],
                fromBlock: start,
                toBlock: end
            };

            const logs = await provider.getLogs(filter);
            const events = logs.map(log => {
                const parsed = contract.interface.parseLog(log);
                totalAmount += parsed.args[1];
                eventCount++;
            });
            console.log(`Amount distributed in batch ${i + 1}: ${ethers.formatEther(totalAmount.toString())} RON`);


            // Optional: Add delay between batches to avoid rate limiting
            if (i < batchCount - 1) {
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            lastBlockTracked = end;
        }

        console.log(`\nTotal events found: ${eventCount}`);
        console.log(`\nTotal amount distributed: ${ethers.formatEther(totalAmount.toString())} RON`);

    } catch (error) {
        console.log(`Last block: ${lastBlockTracked}`);
        console.log(`Total amount distributed: ${ethers.formatEther(totalAmount.toString())} RON`);
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


//     Last block: 37347058
// Total amount distributed: 1835.909766683154573894 RON

// Last block: 37723802
// Total amount distributed: 571.697248144176514259 RON

// Last block: 38411423
// Total amount distributed: 1543.79900782752481796 RON

// Last block: 38644455
// Total amount distributed: 361.968670379229700101 RON

// Last block: 38872497
// Total amount distributed: 1104.625211742303078245 RON

// Last block: 39619499
// Total amount distributed: 5636.102292530991209143 RON

// Fetching batch 429/429 (blocks 39833071 to 39833407)
// Amount distributed in batch 429: 5002.524400349048288309 RON

// Total amount distributed across all batches: 15656.626597655428972911 RON

// Total events found: 36

// Total amount distributed: 69.323981796465870895 RON