import React, { useState, useCallback, useEffect } from 'react';
import { 
  Box, AppBar, Toolbar, Typography, Button, Container, 
  Paper, Grid, List, ListItem, ListItemText, ListItemIcon,
  ListItemSecondaryAction, IconButton, Divider, Alert, CircularProgress
} from '@mui/material';
import { useDropzone } from 'react-dropzone';
import { InsertDriveFile, Delete, CloudUpload, Refresh } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { getFiles, uploadFiles, deleteFile } from '../api/fileService';

interface FileInfo {
  name: string;
  size: number;
  modified: string;
  url: string;
}

const DashboardPage: React.FC = () => {
  const { user, logout } = useAuth();
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [uploadedFiles, setUploadedFiles] = useState<FileInfo[]>([]);
  const [uploadStatus, setUploadStatus] = useState<{
    message: string;
    severity: 'success' | 'error' | 'info' | 'warning' | null;
  }>({ message: '', severity: null });
  const [loading, setLoading] = useState<boolean>(false);

  // Fetch files from the API
  const fetchFiles = async () => {
    try {
      setLoading(true);
      const files = await getFiles();
      setUploadedFiles(files);
    } catch (error) {
      console.error('Error fetching files:', error);
      setUploadStatus({
        message: `Error fetching files: ${error instanceof Error ? error.message : 'Unknown error'}`,
        severity: 'error'
      });
    } finally {
      setLoading(false);
    }
  };

  // Upload files to the API
  const handleUpload = async () => {
    if (selectedFiles.length === 0) {
      setUploadStatus({
        message: 'No files selected for upload',
        severity: 'warning'
      });
      return;
    }

    try {
      setLoading(true);
      await uploadFiles(selectedFiles);
      setSelectedFiles([]);
      setUploadStatus({
        message: `Successfully uploaded ${selectedFiles.length} file(s)`,
        severity: 'success'
      });
      // Refresh the file list
      fetchFiles();
    } catch (error) {
      console.error('Error uploading files:', error);
      setUploadStatus({
        message: `Error uploading files: ${error instanceof Error ? error.message : 'Unknown error'}`,
        severity: 'error'
      });
    } finally {
      setLoading(false);
    }
  };

  // Delete a file using the API
  const handleDelete = async (fileName: string) => {
    try {
      setLoading(true);
      await deleteFile(fileName);
      setUploadStatus({
        message: `File "${fileName}" deleted`,
        severity: 'info'
      });
      // Refresh the file list
      fetchFiles();
    } catch (error) {
      console.error('Error deleting file:', error);
      setUploadStatus({
        message: `Error deleting file: ${error instanceof Error ? error.message : 'Unknown error'}`,
        severity: 'error'
      });
    } finally {
      setLoading(false);
    }
  };

  // Dropzone configuration
  const onDrop = useCallback((acceptedFiles: File[]) => {
    setSelectedFiles(prev => [...prev, ...acceptedFiles]);
    setUploadStatus({
      message: `${acceptedFiles.length} file(s) added to queue`,
      severity: 'info'
    });
  }, []);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({ onDrop });

  // Clear status message after 5 seconds
  useEffect(() => {
    if (uploadStatus.message) {
      const timer = setTimeout(() => {
        setUploadStatus({ message: '', severity: null });
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [uploadStatus]);

  // Fetch files on component mount
  useEffect(() => {
    fetchFiles();
  }, []);

  // Format file size for display
  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
  };

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh', width: '100%' }}>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Static Site Generator
          </Typography>
          <Typography variant="body1" sx={{ mr: 2 }}>
            {user?.profile.name || user?.profile.email}
          </Typography>
          <Button color="inherit" onClick={logout}>
            Logout
          </Button>
        </Toolbar>
      </AppBar>
      
      <Container sx={{ mt: 4, flexGrow: 1, width: '100%', maxWidth: 'none', pb: 4 }}>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="h5" component="div" gutterBottom>
                Static Site File Manager
              </Typography>
              
              {uploadStatus.message && uploadStatus.severity && (
                <Alert 
                  severity={uploadStatus.severity} 
                  sx={{ mb: 2 }}
                  onClose={() => setUploadStatus({ message: '', severity: null })}
                >
                  {uploadStatus.message}
                </Alert>
              )}
              
              <Grid container spacing={3}>
                {/* Drag & Drop Area */}
                <Grid item xs={12} md={6}>
                  <Paper
                    {...getRootProps()}
                    sx={{
                      p: 3,
                      border: '2px dashed',
                      borderColor: isDragActive ? 'primary.main' : 'grey.400',
                      backgroundColor: isDragActive ? 'rgba(25, 118, 210, 0.08)' : 'background.paper',
                      textAlign: 'center',
                      cursor: 'pointer',
                      transition: 'all 0.2s ease',
                      minHeight: '200px',
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}
                  >
                    <input {...getInputProps()} />
                    <CloudUpload sx={{ fontSize: 48, color: 'primary.main', mb: 2 }} />
                    <Typography variant="h6">
                      {isDragActive ? 'Drop files here' : 'Drag & drop files here'}
                    </Typography>
                    <Typography variant="body2" color="textSecondary" sx={{ mt: 1 }}>
                      or click to select files
                    </Typography>
                  </Paper>
                  
                  {/* Selected Files Queue */}
                  {selectedFiles.length > 0 && (
                    <Box sx={{ mt: 2 }}>
                      <Typography variant="subtitle1" gutterBottom>
                        Ready to upload ({selectedFiles.length} file{selectedFiles.length !== 1 ? 's' : ''})
                      </Typography>
                      <List dense>
                        {selectedFiles.map((file, index) => (
                          <ListItem key={`${file.name}-${index}`}>
                            <ListItemIcon>
                              <InsertDriveFile />
                            </ListItemIcon>
                            <ListItemText
                              primary={file.name}
                              secondary={formatFileSize(file.size)}
                            />
                          </ListItem>
                        ))}
                      </List>
                      <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 2 }}>
                        <Button 
                          variant="outlined" 
                          color="secondary" 
                          onClick={() => setSelectedFiles([])}
                        >
                          Clear
                        </Button>
                        <Button 
                          variant="contained" 
                          color="primary" 
                          onClick={handleUpload}
                          startIcon={<CloudUpload />}
                          disabled={loading}
                        >
                          {loading ? <CircularProgress size={24} /> : 'Upload All'}
                        </Button>
                      </Box>
                    </Box>
                  )}
                </Grid>
                
                {/* Current Files List */}
                <Grid item xs={12} md={6}>
                  <Paper sx={{ p: 2, height: '100%' }}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                      <Typography variant="h6">
                        Site Files
                      </Typography>
                      <IconButton 
                        size="small" 
                        title="Refresh file list" 
                        onClick={fetchFiles}
                        disabled={loading}
                      >
                        {loading ? <CircularProgress size={20} /> : <Refresh />}
                      </IconButton>
                    </Box>
                    <Divider />
                    {loading && !uploadedFiles.length ? (
                      <Box sx={{ p: 4, textAlign: 'center' }}>
                        <CircularProgress />
                        <Typography sx={{ mt: 2 }}>Loading files...</Typography>
                      </Box>
                    ) : uploadedFiles.length === 0 ? (
                      <Box sx={{ p: 4, textAlign: 'center' }}>
                        <Typography color="textSecondary">
                          No files uploaded yet
                        </Typography>
                      </Box>
                    ) : (
                      <List>
                        {uploadedFiles.map((file) => (
                          <ListItem key={file.name}>
                            <ListItemIcon>
                              <InsertDriveFile />
                            </ListItemIcon>
                            <ListItemText 
                              primary={file.name} 
                              secondary={`${formatFileSize(file.size)} | Modified: ${new Date(file.modified).toLocaleString()}`}
                            />
                            <ListItemSecondaryAction>
                              <IconButton 
                                edge="end" 
                                aria-label="delete"
                                onClick={() => handleDelete(file.name)}
                                disabled={loading}
                              >
                                {loading ? <CircularProgress size={20} /> : <Delete />}
                              </IconButton>
                            </ListItemSecondaryAction>
                          </ListItem>
                        ))}
                      </List>
                    )}
                  </Paper>
                </Grid>
              </Grid>
            </Paper>
          </Grid>
        </Grid>
      </Container>
    </Box>
  );
};

export default DashboardPage;