/**
 * Configuration loader for the BPM Dashboard
 * Loads configuration from config.json (deployed by Terraform)
 */

let config = null;

export async function loadConfig() {
  if (config) return config;

  try {
    // In production, load from S3 via CloudFront
    const response = await fetch('/config.json');
    config = await response.json();
    return config;
  } catch (error) {
    console.error('Error loading config:', error);
    // Fallback for development
    config = {
      apiUrl: import.meta.env.VITE_API_URL || 'http://localhost:3001',
      cognitoUserPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID || '',
      cognitoClientId: import.meta.env.VITE_COGNITO_CLIENT_ID || '',
      cognitoDomain: import.meta.env.VITE_COGNITO_DOMAIN || '',
      region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
    };
    return config;
  }
}

export function getConfig() {
  if (!config) {
    throw new Error('Config not loaded. Call loadConfig() first.');
  }
  return config;
}
