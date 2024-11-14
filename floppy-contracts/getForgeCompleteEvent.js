const ethers = require('ethers');
require('dotenv').config();

const contractABI = [
    "event ForgingCompleted(address indexed requester, uint256 indexed blueprintId, uint256[] axieIds, tuple(uint128 cooldown, uint128 nonce)[] updatedAxieInfos, uint256 feeInAXS)"
];
let totalFees = BigInt(0);
let totalId0Blueprints = 0;
let totalId1Blueprints = 0;
let eventCount = 0;
let lastBlockTracked = 0;
async function getDistributedEvents() {
    try {
        const provider = new ethers.JsonRpcProvider("https://api-archived.roninchain.com/rpc");
        const contractAddress = "0xee85902589eb0c7f88603bb203045b885a1c3a98";
        const contract = new ethers.Contract(contractAddress, contractABI, provider);

        const currentBlock = await provider.getBlockNumber();
        console.log("Current block:", currentBlock);

        // Define block range
        const fromBlock = 39650307;
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
                    ethers.id("ForgingCompleted(address,uint256,uint256[],(uint128,uint128)[],uint256)") // Updated event signature
                ],
                fromBlock: start,
                toBlock: end
            };

            const logs = await provider.getLogs(filter);
            const events = logs.map(log => {
                const parsed = contract.interface.parseLog(log);
                totalFees += parsed.args[4]; // feeInAXS is the 5th argument
                eventCount++;
                if (parsed.args[1] === BigInt(0)) {
                    totalId0Blueprints++;
                } else if (parsed.args[1] === BigInt(1)) {
                    totalId1Blueprints++;
                }
            });
            console.log(`Fees collected in batch ${i + 1}: ${ethers.formatEther(totalFees.toString())} AXS`);
            // Optional: Add delay between batches to avoid rate limiting
            if (i < batchCount - 1) {
                await new Promise(resolve => setTimeout(resolve, 100));
            }
            lastBlockTracked = end;
        }

        console.log(`\nTotal events found: ${eventCount}`);
        console.log(`Last block: ${lastBlockTracked}`);
        console.log(`\nTotal fees collected: ${ethers.formatEther(totalFees.toString())} AXS`);
        console.log(`Total ID0 blueprints: ${totalId0Blueprints}`);
        console.log(`Total ID1 blueprints: ${totalId1Blueprints}`);

    } catch (error) {
        console.log(`Last block: ${lastBlockTracked}`);
        console.log(`Total fees collected: ${ethers.formatEther(totalFees.toString())} AXS`);
        console.log(`Total ID0 blueprints: ${totalId0Blueprints}`);
        console.log(`Total ID1 blueprints: ${totalId1Blueprints}`);
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




// Total events found: 1186
// Last block: 39845910

// Total fees collected: 587.59279276262662362 AXS
// Total ID0 blueprints: 113
// Total ID1 blueprints: 1073