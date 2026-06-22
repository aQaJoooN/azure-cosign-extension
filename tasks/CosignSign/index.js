#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

// Get the script path
const scriptPath = path.join(__dirname, 'sign.sh');

// Run the bash script with inherited stdio
const proc = spawn('bash', [scriptPath], {
    stdio: 'inherit',
    env: process.env,
    shell: false
});

proc.on('close', (code) => {
    process.exit(code || 0);
});

proc.on('error', (err) => {
    console.error('Failed to start bash script:', err);
    process.exit(1);
});
