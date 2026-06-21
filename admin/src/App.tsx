import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import GoldRecords from './pages/GoldRecords';
import Withdrawals from './pages/Withdrawals';
import Idioms from './pages/Idioms';
import Configs from './pages/Configs';
import Announcements from './pages/Announcements';
import { isLoggedIn } from './utils/auth';

const PrivateRoute: React.FC<{ element: React.ReactNode }> = ({ element }) => {
  return isLoggedIn() ? <Layout>{element}</Layout> : <Navigate to="/login" replace />;
};

const App: React.FC = () => {
  return (
    <ConfigProvider locale={zhCN}>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={<PrivateRoute element={<Dashboard />} />} />
        <Route path="/dashboard" element={<PrivateRoute element={<Dashboard />} />} />
        <Route path="/users" element={<PrivateRoute element={<Users />} />} />
        <Route path="/gold-records" element={<PrivateRoute element={<GoldRecords />} />} />
        <Route path="/withdrawals" element={<PrivateRoute element={<Withdrawals />} />} />
        <Route path="/idioms" element={<PrivateRoute element={<Idioms />} />} />
        <Route path="/configs" element={<PrivateRoute element={<Configs />} />} />
        <Route path="/announcements" element={<PrivateRoute element={<Announcements />} />} />
      </Routes>
    </ConfigProvider>
  );
};

export default App;
