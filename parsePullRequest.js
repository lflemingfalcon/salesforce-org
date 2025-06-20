const fs = require('fs');
const readLine = require('readLine');

async function extractTests() {

    let testsFile = __dirname+'testsToRun.txt';
    await fs.promises.writeFile(testsFile, 'all');

    const lines = readLine.createInterface({
        input: fs.createReadStream(__dirname+'pr_body.txt'),
        crlfDelay: Infinity
    });

    for await (const line of lines) {
        if (line.includes('Apex::[') && line.includes(']::Apex')) {
            let tests = line.substring(8, line.length-7);
            await fs.promises.writeFile(testsFile, tests);
            await fs.promises.appendFile(testsFile, '\n');
        }
    }
}

extractTests();