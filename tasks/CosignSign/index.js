#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

// Get task inputs
const cosignService = process.env.INPUT_COSIGNSERVICE;

if (!cosignService) {
    console.error('##[error]Service connection ID not found');
    process.exit(1);
}

// Build the environment variable names for the service connection
// Azure DevOps creates these environment variables automatically
const urlVarName = `ENDPOINT_URL_${cosignService}`;
const authParamPrefix = `ENDPOINT_AUTH_PARAMETER_${cosignService}_`;

// Create a clean environment with all needed variables
const cleanEnv = { ...process.env };

// Get the endpoint URL and pass it as a clean variable
const endpointUrl = process.env[urlVarName] || '';
cleanEnv.COSIGN_ENDPOINT_URL = endpointUrl;

// Get authentication parameters and pass them with clean names
cleanEnv.COSIGN_PRIVATE_KEY = process.env[`${authParamPrefix}COSIGNPRIVATEKEY`] || '';
cleanEnv.COSIGN_PUBLIC_KEY = process.env[`${authParamPrefix}COSIGNPUBLICKEY`] || '';
cleanEnv.COSIGN_KEY_PASSWORD = process.env[`${authParamPrefix}COSIGNPASSWORD`] || '';

// Get the script path
const scriptPath = path.join(__dirname, 'sign.sh');

// Run the bash script with clean environment
const proc = spawn('bash', [scriptPath], {
    stdio: 'inherit',
    env: cleanEnv,
    shell: false
});

proc.on('close', (code) => {
    process.exit(code || 0);
});

proc.on('error', (err) => {
    console.error('##[error]Failed to start bash script:', err);
    process.exit(1);
});
