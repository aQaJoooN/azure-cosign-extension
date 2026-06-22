#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');

// Get task inputs
const cosignService = process.env.INPUT_COSIGNSERVICE;
const dockerRegistryService = process.env.INPUT_DOCKERREGISTRYSERVICE;

if (!cosignService) {
    console.error('##[error]Cosign service connection ID not found');
    process.exit(1);
}

if (!dockerRegistryService) {
    console.error('##[error]Docker registry service connection ID not found');
    process.exit(1);
}

// Build the environment variable names for Cosign service connection
const urlVarName = `ENDPOINT_URL_${cosignService}`;
const authParamPrefix = `ENDPOINT_AUTH_PARAMETER_${cosignService}_`;

// Build the environment variable names for Docker registry service connection
const dockerUrlVarName = `ENDPOINT_URL_${dockerRegistryService}`;
const dockerAuthPrefix = `ENDPOINT_AUTH_PARAMETER_${dockerRegistryService}_`;
const dockerDataPrefix = `ENDPOINT_DATA_${dockerRegistryService}_`;

// Create a clean environment with all needed variables
const cleanEnv = { ...process.env };

// Get the Cosign endpoint URL and pass it as a clean variable
const endpointUrl = process.env[urlVarName] || '';
cleanEnv.COSIGN_ENDPOINT_URL = endpointUrl;

// Get Cosign authentication parameters and pass them with clean names
cleanEnv.COSIGN_PRIVATE_KEY = process.env[`${authParamPrefix}COSIGNPRIVATEKEY`] || '';
cleanEnv.COSIGN_PUBLIC_KEY = process.env[`${authParamPrefix}COSIGNPUBLICKEY`] || '';
cleanEnv.COSIGN_KEY_PASSWORD = process.env[`${authParamPrefix}COSIGNPASSWORD`] || '';

// Get Docker registry connection details
// Try multiple possible variable names for Docker registry URL
let dockerRegistryUrl = process.env[dockerUrlVarName] || '';
console.log(`DEBUG: ENDPOINT_URL_${dockerRegistryService} = ${dockerRegistryUrl}`);

if (!dockerRegistryUrl) {
    dockerRegistryUrl = process.env[`${dockerDataPrefix}REGISTRYURL`] || '';
    console.log(`DEBUG: ENDPOINT_DATA_${dockerRegistryService}_REGISTRYURL = ${dockerRegistryUrl}`);
}
if (!dockerRegistryUrl) {
    dockerRegistryUrl = process.env[`${dockerAuthPrefix}REGISTRY`] || '';
    console.log(`DEBUG: ENDPOINT_AUTH_PARAMETER_${dockerRegistryService}_REGISTRY = ${dockerRegistryUrl}`);
}

// Additional checks for Others registry type
if (!dockerRegistryUrl) {
    dockerRegistryUrl = process.env[`${dockerAuthPrefix}LOGINSERVER`] || '';
    console.log(`DEBUG: ENDPOINT_AUTH_PARAMETER_${dockerRegistryService}_LOGINSERVER = ${dockerRegistryUrl}`);
}

console.log(`DEBUG: Final Docker Registry URL: ${dockerRegistryUrl}`);

// Get Docker credentials - try multiple possible variable names
let dockerUsername = process.env[`${dockerAuthPrefix}USERNAME`] || '';
if (!dockerUsername) {
    dockerUsername = process.env[`${dockerAuthPrefix}REGISTRY_USERNAME`] || '';
}
if (!dockerUsername) {
    dockerUsername = process.env[`${dockerDataPrefix}USERNAME`] || '';
}

console.log(`DEBUG: Docker Username: ${dockerUsername}`);

let dockerPassword = process.env[`${dockerAuthPrefix}PASSWORD`] || '';
if (!dockerPassword) {
    dockerPassword = process.env[`${dockerAuthPrefix}REGISTRY_PASSWORD`] || '';
}
if (!dockerPassword) {
    dockerPassword = process.env[`${dockerDataPrefix}PASSWORD`] || '';
}

cleanEnv.DOCKER_REGISTRY_URL = dockerRegistryUrl;
cleanEnv.DOCKER_REGISTRY_USERNAME = dockerUsername;
cleanEnv.DOCKER_REGISTRY_PASSWORD = dockerPassword;

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
