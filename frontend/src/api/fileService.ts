import { getUser } from '../auth/oidc-config';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:4000/api';

/**
 * Get authentication token from OIDC user
 */
const getAuthToken = async (): Promise<string | null> => {
  try {
    const user = await getUser();
    return user?.access_token || null;
  } catch (error) {
    console.error('Error getting auth token:', error);
    return null;
  }
};

/**
 * Get headers with authentication token
 */
const getAuthHeaders = async (): Promise<HeadersInit> => {
  const token = await getAuthToken();
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };
  
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  
  return headers;
};

/**
 * Get a list of all files
 */
export const getFiles = async () => {
  const headers = await getAuthHeaders();
  const response = await fetch(`${API_URL}/files`, { 
    method: 'GET',
    headers 
  });
  
  if (!response.ok) {
    throw new Error(`Error fetching files: ${response.statusText}`);
  }
  
  return await response.json();
};

/**
 * Upload files to the static site
 */
export const uploadFiles = async (files: File[]) => {
  const token = await getAuthToken();
  const formData = new FormData();
  
  files.forEach(file => {
    formData.append('files', file);
  });
  
  const response = await fetch(`${API_URL}/files/upload`, {
    method: 'POST',
    headers: {
      'Authorization': token ? `Bearer ${token}` : '',
      // Don't set Content-Type for FormData, the browser will set it with the boundary
    },
    body: formData
  });
  
  if (!response.ok) {
    throw new Error(`Error uploading files: ${response.statusText}`);
  }
  
  return await response.json();
};

/**
 * Delete a file from the static site
 */
export const deleteFile = async (filename: string) => {
  const headers = await getAuthHeaders();
  const response = await fetch(`${API_URL}/files/${encodeURIComponent(filename)}`, {
    method: 'DELETE',
    headers
  });
  
  if (!response.ok) {
    throw new Error(`Error deleting file: ${response.statusText}`);
  }
  
  return await response.json();
};

/**
 * Get information about a specific file
 */
export const getFileInfo = async (filename: string) => {
  const headers = await getAuthHeaders();
  const response = await fetch(`${API_URL}/files/${encodeURIComponent(filename)}`, {
    method: 'GET',
    headers
  });
  
  if (!response.ok) {
    throw new Error(`Error getting file info: ${response.statusText}`);
  }
  
  return await response.json();
};