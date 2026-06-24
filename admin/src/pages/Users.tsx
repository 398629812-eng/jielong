import React, { useCallback, useEffect, useState } from 'react';
import {
  Button,
  Descriptions,
  Drawer,
  Input,
  message,
  Modal,
  Pagination,
  Space,
  Statistic,
  Switch,
  Table,
  Tag,
} from 'antd';
import { ReloadOutlined, SearchOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';
import request from '../api/request';

interface LedgerUser {
  id: number;
  phone: string | null;
  nickname: string;
  gold: number;
  total_withdrawn: number;
  hints: number;
  is_guest: number;
  is_banned: number;
  created_at: string;
  latest_amount: number | null;
  latest_type: string | null;
  latest_description: string | null;
  latest_time: string | null;
  today_gold_income: number;
  today_ad_count: number;
  pending_withdraw_count: number;
}

interface GoldRecord {
  id: number;
  user_id: number;
  amount: number;
  type: string;
  description: string;
  created_at: string;
}

const typeMap: Record<string, { label: string; color: string }> = {
  ad_watch: { label: '广告奖励', color: 'blue' },
  game: { label: '游戏奖励', color: 'green' },
  record: { label: '刷新纪录', color: 'purple' },
  sign_in: { label: '每日签到', color: 'cyan' },
  spin: { label: '转盘抽奖', color: 'volcano' },
  task: { label: '任务奖励', color: 'gold' },
  withdraw: { label: '提现变动', color: 'red' },
  hint: { label: '提示消耗', color: 'orange' },
};

function formatDate(value?: string | null) {
  return value ? dayjs(value).format('YYYY-MM-DD HH:mm:ss') : '-';
}

function GoldChange({ amount }: { amount?: number | null }) {
  if (amount === null || amount === undefined) return <span>-</span>;
  return (
    <Tag color={amount >= 0 ? 'green' : 'red'}>
      {amount >= 0 ? '+' : ''}
      {Number(amount).toLocaleString()}
    </Tag>
  );
}

function TypeTag({ type }: { type?: string | null }) {
  if (!type) return <span>-</span>;
  const item = typeMap[type] || { label: type, color: 'default' };
  return <Tag color={item.color}>{item.label}</Tag>;
}

const Users: React.FC = () => {
  const [users, setUsers] = useState<LedgerUser[]>([]);
  const [inputKeyword, setInputKeyword] = useState('');
  const [keyword, setKeyword] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<LedgerUser | null>(null);
  const [records, setRecords] = useState<GoldRecord[]>([]);
  const [recordsLoading, setRecordsLoading] = useState(false);

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    try {
      const res: any = await request.get('/user-ledger', {
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

  const fetchUserRecords = async (user: LedgerUser) => {
    setSelectedUser(user);
    setDrawerOpen(true);
    setRecordsLoading(true);
    try {
      const res: any = await request.get(`/user-ledger/${user.id}`, {
        params: { page: 1, pageSize: 50 },
      });
      setRecords(res.data?.records?.list ?? []);
    } finally {
      setRecordsLoading(false);
    }
  };

  const handleSearch = () => {
    setPage(1);
    setKeyword(inputKeyword.trim());
  };

  const handleBan = (user: LedgerUser) => {
    const action = user.is_banned ? '解封' : '封号';
    Modal.confirm({
      title: `确认${action}用户`,
      content: `确定要${action}「${user.nickname || user.phone || user.id}」吗？`,
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
    { title: 'ID', dataIndex: 'id', key: 'id', width: 72, fixed: 'left' as const },
    { title: '用户名', dataIndex: 'nickname', key: 'nickname', width: 140 },
    {
      title: '手机号',
      dataIndex: 'phone',
      key: 'phone',
      width: 140,
      render: (value: string | null) => value || '-',
    },
    {
      title: '金币余额',
      dataIndex: 'gold',
      key: 'gold',
      width: 130,
      render: (value: number) => <strong>{Number(value).toLocaleString()}</strong>,
      sorter: (a: LedgerUser, b: LedgerUser) => a.gold - b.gold,
    },
    {
      title: '最近变动',
      key: 'latest',
      width: 300,
      render: (_: unknown, record: LedgerUser) => (
        <Space direction="vertical" size={2}>
          <Space>
            <GoldChange amount={record.latest_amount} />
            <TypeTag type={record.latest_type} />
          </Space>
          <span style={{ color: '#666' }}>{record.latest_description || '-'}</span>
          <span style={{ color: '#999', fontSize: 12 }}>{formatDate(record.latest_time)}</span>
        </Space>
      ),
    },
    {
      title: '今日广告',
      dataIndex: 'today_ad_count',
      key: 'today_ad_count',
      width: 100,
      render: (value: number) => `${value || 0} 次`,
    },
    {
      title: '今日金币',
      dataIndex: 'today_gold_income',
      key: 'today_gold_income',
      width: 110,
      render: (value: number) => <GoldChange amount={value || 0} />,
    },
    {
      title: '用户状态',
      dataIndex: 'is_banned',
      key: 'is_banned',
      width: 110,
      render: (value: number, record: LedgerUser) => (
        <Space direction="vertical" size={2}>
          {value ? <Tag color="red">已封号</Tag> : <Tag color="green">正常</Tag>}
          {record.pending_withdraw_count > 0 && <Tag color="orange">待提现审核</Tag>}
        </Space>
      ),
    },
    {
      title: '操作',
      key: 'action',
      width: 170,
      fixed: 'right' as const,
      render: (_: unknown, record: LedgerUser) => (
        <Space>
          <Button size="small" onClick={() => fetchUserRecords(record)}>
            流水
          </Button>
          <Switch
            checked={record.is_banned === 0}
            checkedChildren="正常"
            unCheckedChildren="封号"
            onChange={() => handleBan(record)}
          />
        </Space>
      ),
    },
  ];

  const recordColumns = [
    { title: '流水ID', dataIndex: 'id', key: 'id', width: 90 },
    { title: '金币变动', dataIndex: 'amount', key: 'amount', render: (value: number) => <GoldChange amount={value} /> },
    { title: '类型', dataIndex: 'type', key: 'type', render: (value: string) => <TypeTag type={value} /> },
    { title: '说明', dataIndex: 'description', key: 'description' },
    { title: '时间', dataIndex: 'created_at', key: 'created_at', render: (value: string) => formatDate(value) },
  ];

  return (
    <div>
      <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', gap: 12 }}>
        <Space>
          <Input
            placeholder="搜索用户ID、手机号或用户名"
            value={inputKeyword}
            onChange={(event) => setInputKeyword(event.target.value)}
            onPressEnter={handleSearch}
            style={{ width: 300 }}
          />
          <Button type="primary" icon={<SearchOutlined />} onClick={handleSearch}>
            搜索
          </Button>
          <Button icon={<ReloadOutlined />} onClick={fetchUsers}>
            刷新余额
          </Button>
        </Space>
      </div>

      <Table
        dataSource={users}
        columns={columns}
        rowKey="id"
        loading={loading}
        pagination={false}
        scroll={{ x: 1280 }}
      />

      <div style={{ marginTop: 16, textAlign: 'right' }}>
        <Pagination
          current={page}
          pageSize={pageSize}
          total={total}
          onChange={setPage}
          showTotal={(value) => `共 ${value} 名用户`}
        />
      </div>

      <Drawer
        title="用户金币流水"
        width={860}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
      >
        {selectedUser && (
          <Space direction="vertical" size={16} style={{ width: '100%' }}>
            <Descriptions bordered size="small" column={3}>
              <Descriptions.Item label="用户ID">{selectedUser.id}</Descriptions.Item>
              <Descriptions.Item label="用户名">{selectedUser.nickname || '-'}</Descriptions.Item>
              <Descriptions.Item label="手机号">{selectedUser.phone || '-'}</Descriptions.Item>
              <Descriptions.Item label="金币余额">
                <Statistic value={selectedUser.gold} valueStyle={{ fontSize: 18 }} />
              </Descriptions.Item>
              <Descriptions.Item label="累计提现金币">
                {Number(selectedUser.total_withdrawn || 0).toLocaleString()}
              </Descriptions.Item>
              <Descriptions.Item label="状态">
                {selectedUser.is_banned ? <Tag color="red">已封号</Tag> : <Tag color="green">正常</Tag>}
              </Descriptions.Item>
            </Descriptions>

            <Table
              dataSource={records}
              columns={recordColumns}
              rowKey="id"
              loading={recordsLoading}
              pagination={false}
              size="small"
            />
          </Space>
        )}
      </Drawer>
    </div>
  );
};

export default Users;
