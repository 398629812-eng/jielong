import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Card, Col, Pagination, Row, Select, Space, Statistic, Table, Tag } from 'antd';
import {
  BarChartOutlined,
  FileTextOutlined,
  PlayCircleOutlined,
  SearchOutlined,
  WalletOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import request from '../api/request';

interface RevenueRecord {
  id: number;
  user_id: number;
  username: string;
  phone: string | null;
  platform: string | null;
  platform_label: string;
  ad_type: string;
  ad_type_label: string;
  ad_format: string | null;
  placement_id: string | null;
  transaction_id: string | null;
  verify_status: string;
  revenue: number;
  created_at: string;
}

interface RevenueSummary {
  total_revenue: number;
  total_count: number;
  by_platform: Record<string, { platform: string; label: string; revenue: number; count: number }>;
}

const platformColors: Record<string, string> = {
  tencent: '#1677ff',
  youlianghui: '#1677ff',
  pangolin: '#13c2c2',
  chuanshanjia: '#13c2c2',
  kuaishou: '#722ed1',
  baidu: '#ff4d4f',
  huawei: '#52c41a',
  mock: '#8c8c8c',
  unknown: '#faad14',
};

function money(value: number) {
  return Number(value || 0).toFixed(6);
}

function formatDate(value: string) {
  return value ? dayjs(value).format('YYYY-MM-DD HH:mm:ss') : '-';
}

const AdRevenue: React.FC = () => {
  const [records, setRecords] = useState<RevenueRecord[]>([]);
  const [summary, setSummary] = useState<RevenueSummary>({
    total_revenue: 0,
    total_count: 0,
    by_platform: {},
  });
  const [platform, setPlatform] = useState<string | undefined>();
  const [adType, setAdType] = useState<string | undefined>();
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const res: any = await request.get('/ad-revenue', {
        params: {
          page,
          pageSize,
          platform,
          ad_type: adType,
        },
      });
      setSummary(res.data?.summary ?? { total_revenue: 0, total_count: 0, by_platform: {} });
      setRecords(res.data?.records?.list ?? []);
      setTotal(res.data?.records?.total ?? 0);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, platform, adType]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const platformCards = useMemo(() => {
    const values = Object.values(summary.by_platform || {});
    const known = [
      { key: 'youlianghui', aliases: ['youlianghui', 'tencent'], label: '优量汇' },
      { key: 'kuaishou', aliases: ['kuaishou'], label: '快手' },
      { key: 'chuanshanjia', aliases: ['chuanshanjia', 'pangolin'], label: '穿山甲' },
      { key: 'baidu', aliases: ['baidu'], label: '百度' },
    ];
    const cards = known.map((item) => {
      const matched = values.filter((value) => item.aliases.includes(value.platform));
      return {
        platform: item.key,
        label: item.label,
        revenue: matched.reduce((sum, value) => sum + Number(value.revenue || 0), 0),
        count: matched.reduce((sum, value) => sum + Number(value.count || 0), 0),
      };
    });
    return cards;
  }, [summary.by_platform]);

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 90 },
    {
      title: '用户名',
      key: 'username',
      width: 180,
      render: (_: unknown, record: RevenueRecord) => record.phone || record.username || `用户${record.user_id}`,
    },
    {
      title: '广告平台',
      dataIndex: 'platform_label',
      key: 'platform_label',
      width: 150,
      render: (value: string, record: RevenueRecord) => (
        <Tag color={platformColors[(record.platform || 'unknown').toLowerCase()] || 'default'}>{value}</Tag>
      ),
    },
    {
      title: '广告类型',
      dataIndex: 'ad_type_label',
      key: 'ad_type_label',
      width: 140,
    },
    {
      title: '收益',
      dataIndex: 'revenue',
      key: 'revenue',
      width: 140,
      render: (value: number) => <strong>{money(value)}</strong>,
    },
    {
      title: '校验状态',
      dataIndex: 'verify_status',
      key: 'verify_status',
      width: 120,
      render: (value: string) => {
        const color = value === 'verified' ? 'green' : value === 'mock' ? 'orange' : 'default';
        return <Tag color={color}>{value || 'unknown'}</Tag>;
      },
    },
    {
      title: '创建时间',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 180,
      render: (value: string) => formatDate(value),
    },
  ];

  const resetPageAnd = (setter: (value: string | undefined) => void, value: string | undefined) => {
    setPage(1);
    setter(value);
  };

  return (
    <Space direction="vertical" size={20} style={{ width: '100%' }}>
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} xl={4}>
          <Card style={{ background: '#1677ff', color: '#fff' }}>
            <Statistic title={<span style={{ color: '#fff' }}>总收益</span>} value={money(summary.total_revenue)} prefix={<WalletOutlined />} valueStyle={{ color: '#fff' }} />
          </Card>
        </Col>
        {platformCards.map((item) => (
          <Col xs={24} sm={12} xl={4} key={item.platform}>
            <Card style={{ background: platformColors[item.platform] || '#13c2c2', color: '#fff' }}>
              <Statistic title={<span style={{ color: '#fff' }}>{item.label}收益</span>} value={money(item.revenue)} prefix={<BarChartOutlined />} valueStyle={{ color: '#fff' }} />
            </Card>
          </Col>
        ))}
        <Col xs={24} sm={12} xl={4}>
          <Card style={{ background: '#52c41a', color: '#fff' }}>
            <Statistic title={<span style={{ color: '#fff' }}>总条数</span>} value={summary.total_count} prefix={<FileTextOutlined />} valueStyle={{ color: '#fff' }} />
          </Card>
        </Col>
      </Row>

      <Card>
        <Space style={{ marginBottom: 16 }} wrap>
          <Select
            allowClear
            placeholder="广告平台"
            value={platform}
            style={{ width: 160 }}
            onChange={(value) => resetPageAnd(setPlatform, value)}
            options={[
              { value: 'tencent', label: '优量汇' },
              { value: 'chuanshanjia', label: '穿山甲' },
              { value: 'kuaishou', label: '快手' },
              { value: 'baidu', label: '百度' },
              { value: 'mock', label: '测试平台' },
            ]}
          />
          <Select
            allowClear
            placeholder="广告类型"
            value={adType}
            style={{ width: 160 }}
            onChange={(value) => resetPageAnd(setAdType, value)}
            options={[
              { value: 'hint', label: '提示激励视频' },
              { value: 'continue', label: '续命激励视频' },
              { value: 'sign_in_double', label: '签到翻倍' },
              { value: 'spin', label: '转盘抽奖' },
              { value: 'task', label: '任务奖励' },
            ]}
          />
          <Tag icon={<SearchOutlined />} color="blue">
            收益字段已预留，接入SDK回调后写入真实结算金额
          </Tag>
          <Tag icon={<PlayCircleOutlined />} color="orange">
            当前 mock/旧记录收益可能为 0
          </Tag>
        </Space>

        <Table
          dataSource={records}
          columns={columns}
          rowKey="id"
          loading={loading}
          pagination={false}
          scroll={{ x: 980 }}
        />
        <div style={{ marginTop: 16, textAlign: 'right' }}>
          <Pagination
            current={page}
            pageSize={pageSize}
            total={total}
            onChange={setPage}
            showTotal={(value) => `共 ${value} 条广告记录`}
          />
        </div>
      </Card>
    </Space>
  );
};

export default AdRevenue;
