import axios from 'axios';

// Use environment variable for API URL, fallback to localhost for development
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add a request interceptor to include the JWT token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Auth API
export const authAPI = {
  login: (credentials) => api.post('/auth/login', credentials),
  signup: (userData) => api.post('/auth/signup', userData),
};

// Poll API
export const pollAPI = {
  getAllPolls: () => api.get('/polls/all'),
  getPollById: (id) => api.get(`/polls/${id}`),
  getUserPolls: () => api.get('/polls/user'),
  createPoll: (pollData) => api.post('/polls', pollData),
  vote: (pollId, optionId) => api.post(`/polls/${pollId}/vote`, { optionId }),
};

export default api;
