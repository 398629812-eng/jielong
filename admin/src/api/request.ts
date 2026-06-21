import axios, { AxiosError, AxiosResponse } from 'axios';
import { message } from 'antd';
import { getToken, logout } from '../utils/auth';

const request = axios.create({
  baseURL: 'http://localhost:3000/api/admin',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器：自动附加 JWT Token
request.interceptors.request.use(
  (config) => {
    const token = getToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器：统一错误处理
request.interceptors.response.use(
  (response: AxiosResponse) => {
    const { code, message: msg } = response.data;
    if (code !== 0 && code !== undefined) {
      message.error(msg || '请求失败');
      return Promise.reject(new Error(msg || '请求失败'));
    }
    return response.data;
  },
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      message.error('登录已过期，请重新登录');
      logout();
    } else {
      message.error(error.message || '网络错误');
    }
    return Promise.reject(error);
  }
);

export default request;
