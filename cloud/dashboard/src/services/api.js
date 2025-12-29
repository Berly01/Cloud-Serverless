import axios from 'axios';
import { loadConfig } from '../config';

let apiClient = null;

export async function initApiClient(getToken) {
  const config = await loadConfig();
  
  apiClient = axios.create({
    baseURL: config.apiUrl,
    timeout: 30000,
    headers: {
      'Content-Type': 'application/json',
    },
  });

  // Request interceptor to add auth token
  apiClient.interceptors.request.use(
    (requestConfig) => {
      const token = getToken();
      if (token) {
        requestConfig.headers.Authorization = `Bearer ${token}`;
      }
      return requestConfig;
    },
    (error) => {
      return Promise.reject(error);
    }
  );

  // Response interceptor for error handling
  apiClient.interceptors.response.use(
    (response) => response,
    (error) => {
      if (error.response?.status === 401) {
        // Token expired, redirect to login
        window.location.href = '/login';
      }
      return Promise.reject(error);
    }
  );

  return apiClient;
}

export function getApiClient() {
  if (!apiClient) {
    throw new Error('API client not initialized. Call initApiClient first.');
  }
  return apiClient;
}

// ============================================================================
// API Functions
// ============================================================================

/**
 * Get current BPM status
 */
export async function getCurrentStatus() {
  const client = getApiClient();
  const response = await client.get('/bpm/current');
  return response.data;
}

/**
 * Get BPM history
 */
export async function getBpmHistory(params = {}) {
  const client = getApiClient();
  const response = await client.get('/bpm/history', { params });
  return response.data;
}

/**
 * Get BPM statistics
 */
export async function getBpmStatistics(period = 'day') {
  const client = getApiClient();
  const response = await client.get('/bpm/statistics', { params: { period } });
  return response.data;
}

/**
 * Get user devices
 */
export async function getDevices() {
  const client = getApiClient();
  const response = await client.get('/devices');
  return response.data;
}

/**
 * Get user profile
 */
export async function getUserProfile() {
  const client = getApiClient();
  const response = await client.get('/user/profile');
  return response.data;
}

/**
 * Health check
 */
export async function healthCheck() {
  const client = getApiClient();
  const response = await client.get('/health');
  return response.data;
}
