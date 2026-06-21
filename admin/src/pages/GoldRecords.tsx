import React, { useCallback, useEffect, useState } from 'react';
import { Table, Input, Button, Tag, Pagination } from 'antd';
import { SearchOutlined } from '@ant-design/icons';
import request from '../api/request';

interface GoldRecord {
  id: number;
  user_id: number;
  nickname: string;
  amount: number;
  type: string;
  description: string;
  created_at: string;
}

const typeMap: Record<string, { label: string; color: string }> = {
  ad_watch: { label: '广告观看', color: 'blue' }, game: { label: '游戏奖励', color: 'green' },
  record: { label: '刷新纪录', color: 'purple' }, sign_in: { label: '每日签到', color: 'cyan' },
  spin: { label: '转盘抽奖', color: 'volcano' }, task: { label: '任务奖励', color: 'gold' },
  withdraw: { label: '提现', color: 'red' }, hint: { label: '使用提示', color: 'orange' },
};

const GoldRecords: React.FC = () => {
  const [records, setRecords] = useState<GoldRecord[]>([]);
  const [inputUserId, setInputUserId] = useState('');
  const [userId, setUserId] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize] = useState(10);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);

  const fetchRecords = useCallback(async () => {
    setLoading(true);
    try {
      const res: any = await request.get('/gold-records', {
        params: { page, pageSize, user_id: userId || undefined },
      });
      setRecords(res.data?.list ?? []);
      setTotal(res.data?.total ?? 0);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, userId]);

  useEffect(() => { fetchRecords(); }, [fetchRecords]);

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id' },
    { title: '用户ID', dataIndex: 'user_id', key: 'user_id' },
    { title: '昵称', dataIndex: 'nickname', key: 'nickname' },
    { title: '金币变动', dataIndex: 'amount', key: 'amount', render: (v: number) => <Tag color={v > 0 ? 'green' : 'red'}>{v > 0 ? '+' : ''}{v}</Tag> },
    { title: '类型', dataIndex: 'type', key: 'type', render: (v: string) => { const i = typeMap[v] || { label: v, color: 'default' }; return <Tag color={i.color}>{i.label}</Tag>; } },
    { title: '说明', dataIndex: 'description', key: 'description' },
    { title: '时间', dataIndex: 'created_at', key: 'created_at' },
  ];

  const handleSearch = () => { setPage(1); setUserId(inputUserId.trim()); };

  return (
    <div>
      <div style={{ marginBottom: 16, display: 'flex', gap: 8 }}>
        <Input placeholder="按用户ID筛选" value={inputUserId} onChange={(e) => setInputUserId(e.target.value)} onPressEnter={handleSearch} style={{ width: 280 }} />
        <Button type="primary" icon={<SearchOutlined />} onClick={handleSearch}>搜索</Button>
      </div>
      <Table dataSource={records} columns={columns} rowKey="id" loading={loading} pagination={false} />
      <div style={{ marginTop: 16, textAlign: 'right' }}>
        <Pagination current={page} pageSize={pageSize} total={total} onChange={setPage} showTotal={(n) => `共 ${n} 条`} />
      </div>
    </div>
  );
};

export default GoldRecords;
