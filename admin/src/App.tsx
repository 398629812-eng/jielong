import React, { Suspense, lazy } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { ConfigProvider, Spin } from 'antd';
import zhCN from 'antd/locale/zh_CN';
import Layout from './components/Layout';
import { isLoggedIn } from './utils/auth';

const Login = lazy(() => import('./pages/Login'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Users = lazy(() => import('./pages/Users'));
const GoldRecords = lazy(() => import('./pages/GoldRecords'));
const AdRevenue = lazy(() => import('./pages/AdRevenue'));
const Withdrawals = lazy(() => import('./pages/Withdrawals'));
const Idioms = lazy(() => import('./pages/Idioms'));
const Configs = lazy(() => import('./pages/Configs'));
const Announcements = lazy(() => import('./pages/Announcements'));

const PrivateRoute: React.FC<{ element: React.ReactNode }> = ({ element }) => {
  return isLoggedIn() ? <Layout>{element}</Layout> : <Navigate to="/login" replace />;
};

const App: React.FC = () => {
  return (
    <ConfigProvider locale={zhCN}>
      <Suspense
        fallback={
          <div style={{ display: 'grid', minHeight: '100vh', placeItems: 'center' }}>
            <Spin size="large" />
          </div>
        }
      >
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<PrivateRoute element={<Dashboard />} />} />
          <Route path="/dashboard" element={<PrivateRoute element={<Dashboard />} />} />
          <Route path="/users" element={<PrivateRoute element={<Users />} />} />
          <Route path="/gold-records" element={<PrivateRoute element={<GoldRecords />} />} />
          <Route path="/ad-revenue" element={<PrivateRoute element={<AdRevenue />} />} />
          <Route path="/withdrawals" element={<PrivateRoute element={<Withdrawals />} />} />
          <Route path="/idioms" element={<PrivateRoute element={<Idioms />} />} />
          <Route path="/configs" element={<PrivateRoute element={<Configs />} />} />
          <Route path="/announcements" element={<PrivateRoute element={<Announcements />} />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Suspense>
    </ConfigProvider>
  );
};

export default App;
