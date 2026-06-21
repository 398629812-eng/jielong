import React, { useCallback, useEffect, useState } from 'react';
import { Table, Input, Button, Tag, Space, Modal, message, Pagination, Switch } from 'antd';
import { SearchOutlined } from '@ant-design/icons';
import request from '../api/request';

interface User {
  id: number;
  phone: string | null;
  nickname: string;
  gold: number;
  total_withdrawn: number;
  hints: number;
  is_guest: number;
  is_banned: number;
  created_at: string;
}

const Users: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [inputKeyword, setInputKeyword] = useState('');
  const [keyword, setKeyword] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize] = useState(10);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    try {
      const res: any = await request.get('/users', {
        params: { page, pageSize, keyword: keyword || undefined },
      });
      setUsers(res.data?.list ?? []);
      setTotal(res.data?.total ?? 0);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, keyword]);

  useEffect(() => {
    fetchUsers();
  }, [fetchUsers]);

  const handleSearch = () => {
    setPage(1);
    setKeyword(inputKeyword.trim());
  };

  const handleBan = (user: User) => {
    const action = user.is_banned ? '解封' : '封禁';
    Modal.confirm({
      title: `确认${action}用户`,
      content: `确定要${action}用户「${user.nickname}」吗？`,
      onOk: async () => {
        await request.put(`/users/${user.id}/ban`, {
          is_banned: user.is_banned ? 0 : 1,
        });
        message.success(`${action}成功`);
        await fetchUsers();
      },
    });
  };

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id' },
    { title: '昵称', dataIndex: 'nickname', key: 'nickname' },
    { title: '手机号', dataIndex: 'phone', key: 'phone', render: (v: string | null) => v || '-' },
    { title: '金币余额', dataIndex: 'gold', key: 'gold', render: (v: number) => v.toLocaleString() },
    { title: '注册时间', dataIndex: 'created_at', key: 'created_at' },
    {
      title: '状态', dataIndex: 'is_banned', key: 'is_banned',
      render: (v: number) => v ? <Tag color="red">已封禁</Tag> : <Tag color="green">正常</Tag>,
    },
    {
      title: '操作', key: 'action',
      render: (_: unknown, record: User) => (
        <Space>
          <Switch
            checked={record.is_banned === 0}
            checkedChildren="正常"
            unCheckedChildren="封禁"
            onChange={() => handleBan(record)}
          />
        </Space>
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: 16, display: 'flex', gap: 8 }}>
        <Input
          placeholder="搜索手机号或昵称"
          value={inputKeyword}
          onChange={(e) => setInputKeyword(e.target.value)}
          onPressEnter={handleSearch}
          style={{ width: 280 }}
        />
        <Button type="primary" icon={<SearchOutlined />} onClick={handleSearch}>搜索</Button>
      </div>
      <Table dataSource={users} columns={columns} rowKey="id" loading={loading} pagination={false} />
      <div style={{ marginTop: 16, textAlign: 'right' }}>
        <Pagination current={page} pageSize={pageSize} total={total} onChange={setPage} showTotal={(n) => `共 ${n} 条`} />
      </div>
    </div>
  );
};

export default Users;
