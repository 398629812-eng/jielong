import React, { useState, useEffect } from 'react';
import { Layout as AntLayout, Menu, Button, Breadcrumb, theme } from 'antd';
import {
  DashboardOutlined,
  UserOutlined,
  DollarOutlined,
  WalletOutlined,
  BookOutlined,
  SettingOutlined,
  NotificationOutlined,
  LogoutOutlined,
} from '@ant-design/icons';
import { useNavigate, useLocation } from 'react-router-dom';
import { getUsername, logout } from '../utils/auth';

const { Header, Sider, Content } = AntLayout;

const menuItems = [
  { key: '/dashboard', icon: <DashboardOutlined />, label: '仪表盘' },
  { key: '/users', icon: <UserOutlined />, label: '用户管理' },
  { key: '/gold-records', icon: <DollarOutlined />, label: '金币流水' },
  { key: '/withdrawals', icon: <WalletOutlined />, label: '提现审核' },
  { key: '/idioms', icon: <BookOutlined />, label: '成语库' },
  { key: '/configs', icon: <SettingOutlined />, label: '系统配置' },
  { key: '/announcements', icon: <NotificationOutlined />, label: '公告管理' },
];

const breadcrumbMap: Record<string, string> = {
  '/dashboard': '仪表盘',
  '/users': '用户管理',
  '/gold-records': '金币流水',
  '/withdrawals': '提现审核',
  '/idioms': '成语库',
  '/configs': '系统配置',
  '/announcements': '公告管理',
};

const Layout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [collapsed, setCollapsed] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const username = getUsername() || '管理员';

  const {
    token: { colorBgContainer, borderRadiusLG },
  } = theme.useToken();

  useEffect(() => {
    // 路由切换时自动高亮对应菜单项
  }, [location.pathname]);

  const handleMenuClick = ({ key }: { key: string }) => {
    navigate(key);
  };

  const breadcrumbItems = [
    { title: '首页' },
    { title: breadcrumbMap[location.pathname] || '仪表盘' },
  ];

  return (
    <AntLayout style={{ minHeight: '100vh' }}>
      <Sider
        trigger={null}
        collapsible
        collapsed={collapsed}
        theme="light"
        style={{
          boxShadow: '2px 0 8px rgba(0,0,0,0.05)',
        }}
      >
        <div
          style={{
            height: 64,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: collapsed ? 14 : 18,
            fontWeight: 'bold',
            borderBottom: '1px solid #f0f0f0',
            padding: '0 16px',
            overflow: 'hidden',
            whiteSpace: 'nowrap',
            textOverflow: 'ellipsis',
          }}
        >
          {collapsed ? '成语' : '成语接龙管理后台'}
        </div>
        <Menu
          theme="light"
          mode="inline"
          selectedKeys={[location.pathname]}
          items={menuItems}
          onClick={handleMenuClick}
        />
      </Sider>
      <AntLayout>
        <Header
          style={{
            padding: '0 24px',
            background: colorBgContainer,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            boxShadow: '0 2px 8px rgba(0,0,0,0.05)',
          }}
        >
          <span style={{ fontSize: 16, fontWeight: 500 }}>
            {breadcrumbMap[location.pathname] || '仪表盘'}
          </span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <span style={{ color: '#666' }}>欢迎，{username}</span>
            <Button type="primary" danger icon={<LogoutOutlined />} onClick={logout}>
              退出
            </Button>
          </div>
        </Header>
        <Content style={{ margin: '16px' }}>
          <Breadcrumb
            style={{ marginBottom: 16 }}
            items={breadcrumbItems.map((item) => ({ title: item.title }))}
          />
          <div
            style={{
              padding: 24,
              minHeight: 360,
              background: colorBgContainer,
              borderRadius: borderRadiusLG,
            }}
          >
            {children}
          </div>
        </Content>
      </AntLayout>
    </AntLayout>
  );
};

export default Layout;
