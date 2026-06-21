import React, { useState } from 'react';
import { Card, Form, Input, Button, message } from 'antd';
import { LoginOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import request from '../api/request';
import { setToken, setUsername } from '../utils/auth';

const Login: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleLogin = async (values: { username: string; password: string }) => {
    setLoading(true);
    try {
      const res: any = await request.post('/login', values);
      if (res.code === 0) {
        setToken(res.data.token);
        setUsername(res.data.username || values.username);
        message.success('登录成功');
        navigate('/dashboard');
      }
    } catch (err) {
      // 错误已在拦截器中处理
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        height: '100vh',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        background: '#f5f5f5',
      }}
    >
      <Card
        title={
          <div style={{ textAlign: 'center', fontSize: 20, fontWeight: 'bold' }}>
            <LoginOutlined style={{ marginRight: 8 }} />
            成语接龙管理后台
          </div>
        }
        style={{ width: 400, boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}
      >
        <Form
          name="login"
          onFinish={handleLogin}
          autoComplete="off"
          layout="vertical"
        >
          <Form.Item
            label="用户名"
            name="username"
            rules={[{ required: true, message: '请输入用户名' }]}
          >
            <Input placeholder="请输入用户名" size="large" />
          </Form.Item>

          <Form.Item
            label="密码"
            name="password"
            rules={[{ required: true, message: '请输入密码' }]}
          >
            <Input.Password placeholder="请输入密码" size="large" />
          </Form.Item>

          <Form.Item>
            <Button
              type="primary"
              htmlType="submit"
              size="large"
              block
              loading={loading}
            >
              登录
            </Button>
          </Form.Item>
        </Form>
      </Card>
    </div>
  );
};

export default Login;
