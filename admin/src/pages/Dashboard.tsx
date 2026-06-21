import React, { useEffect, useState } from 'react';
import { Row, Col, Card, Statistic, Table, Tag, Spin } from 'antd';
import { Column, Line } from '@ant-design/charts';
import { TeamOutlined, UserAddOutlined, EyeOutlined, DollarOutlined, WalletOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';
import request from '../api/request';

interface TrendPoint { date: string; value: number }
interface DashboardData {
  today: { active_users: number; new_users: number; ad_count: number; gold_total: number; withdraw_count: number; withdraw_amount: number };
  total: { users: number; pending_withdrawals: number; total_gold: number };
  trends: { active_users: TrendPoint[]; ad_views: TrendPoint[] };
  recent_gold: Array<{ id: number; nickname: string; amount: number; type: string; created_at: string }>;
  recent_withdrawals: Array<{ id: number; nickname: string; rmb_amount: number; status: string; created_at: string }>;
}

const emptyData: DashboardData = {
  today: { active_users: 0, new_users: 0, ad_count: 0, gold_total: 0, withdraw_count: 0, withdraw_amount: 0 },
  total: { users: 0, pending_withdrawals: 0, total_gold: 0 },
  trends: { active_users: [], ad_views: [] },
  recent_gold: [],
  recent_withdrawals: [],
};

const Dashboard: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<DashboardData>(emptyData);

  useEffect(() => {
    request.get('/dashboard').then((res: any) => setStats(res.data)).finally(() => setLoading(false));
  }, []);

  const chartData = (rows: TrendPoint[]) => rows.map((row) => ({ ...row, date: dayjs(row.date).format('MM-DD') }));
  const activeData = chartData(stats.trends?.active_users || []);
  const adData = chartData(stats.trends?.ad_views || []);

  const goldColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '用户', dataIndex: 'nickname', key: 'nickname' },
    { title: '变动', dataIndex: 'amount', key: 'amount', render: (value: number) => <Tag color={value > 0 ? 'green' : 'red'}>{value > 0 ? '+' : ''}{value}</Tag> },
    { title: '类型', dataIndex: 'type', key: 'type' },
    { title: '时间', dataIndex: 'created_at', key: 'created_at' },
  ];
  const statusLabels: Record<string, string> = { pending: '待审核', approved: '已通过', rejected: '已拒绝', paid: '已打款' };
  const statusColors: Record<string, string> = { pending: 'orange', approved: 'green', rejected: 'red', paid: 'blue' };
  const withdrawColumns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '用户', dataIndex: 'nickname', key: 'nickname' },
    { title: '金额', dataIndex: 'rmb_amount', key: 'rmb_amount', render: (value: number) => `¥${value}` },
    { title: '状态', dataIndex: 'status', key: 'status', render: (value: string) => <Tag color={statusColors[value] || 'default'}>{statusLabels[value] || value}</Tag> },
    { title: '时间', dataIndex: 'created_at', key: 'created_at' },
  ];

  return (
    <Spin spinning={loading}>
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={8} xl={4}><Card><Statistic title="今日活跃用户" value={stats.today.active_users} prefix={<TeamOutlined />} /></Card></Col>
        <Col xs={24} sm={12} lg={8} xl={4}><Card><Statistic title="今日新增用户" value={stats.today.new_users} prefix={<UserAddOutlined />} /></Card></Col>
        <Col xs={24} sm={12} lg={8} xl={4}><Card><Statistic title="今日广告观看" value={stats.today.ad_count} prefix={<EyeOutlined />} /></Card></Col>
        <Col xs={24} sm={12} lg={8} xl={4}><Card><Statistic title="今日金币发放" value={stats.today.gold_total} prefix={<DollarOutlined />} /></Card></Col>
        <Col xs={24} sm={12} lg={8} xl={4}><Card><Statistic title="今日提现金额" value={stats.today.withdraw_amount} precision={2} suffix="元" prefix={<WalletOutlined />} /></Card></Col>
        <Col xs={24} sm={12} lg={8} xl={4}><Card><Statistic title="待审核提现" value={stats.total.pending_withdrawals} /></Card></Col>
      </Row>
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} lg={12}><Card title="近 7 日活跃用户"><Column data={activeData} xField="date" yField="value" color="#52c41a" /></Card></Col>
        <Col xs={24} lg={12}><Card title="近 7 日广告观看"><Line data={adData} xField="date" yField="value" point={{ size: 4 }} color="#faad14" /></Card></Col>
      </Row>
      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} lg={12}><Card title="最近金币流水" extra={<a href="#/gold-records">查看更多</a>}><Table dataSource={stats.recent_gold} columns={goldColumns} pagination={false} rowKey="id" size="small" scroll={{ x: 620 }} /></Card></Col>
        <Col xs={24} lg={12}><Card title="最近提现申请" extra={<a href="#/withdrawals">查看更多</a>}><Table dataSource={stats.recent_withdrawals} columns={withdrawColumns} pagination={false} rowKey="id" size="small" scroll={{ x: 620 }} /></Card></Col>
      </Row>
    </Spin>
  );
};

export default Dashboard;
