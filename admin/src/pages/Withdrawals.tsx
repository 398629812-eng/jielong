import React, { useCallback, useEffect, useState } from 'react';
import { Table, Button, Tag, Space, Modal, Form, Input, Pagination, Tabs, message } from 'antd';
import { CheckOutlined, CloseOutlined } from '@ant-design/icons';
import request from '../api/request';

interface Withdrawal {
  id: number; user_id: number; nickname: string; phone: string | null;
  gold_amount: number; rmb_amount: number; method: string; status: string;
  reject_reason?: string; created_at: string;
}

const statusMap: Record<string, { label: string; color: string }> = {
  pending: { label: '待审核', color: 'orange' }, approved: { label: '已通过', color: 'green' },
  rejected: { label: '已拒绝', color: 'red' }, paid: { label: '已打款', color: 'blue' },
};

const Withdrawals: React.FC = () => {
  const [records, setRecords] = useState<Withdrawal[]>([]);
  const [activeTab, setActiveTab] = useState('all');
  const [page, setPage] = useState(1);
  const [pageSize] = useState(10);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [rejectModalVisible, setRejectModalVisible] = useState(false);
  const [currentRecord, setCurrentRecord] = useState<Withdrawal | null>(null);
  const [rejectForm] = Form.useForm();

  const fetchRecords = useCallback(async () => {
    setLoading(true);
    try {
      const res: any = await request.get('/withdrawals', {
        params: { page, pageSize, status: activeTab === 'all' ? undefined : activeTab },
      });
      setRecords(res.data?.list ?? []);
      setTotal(res.data?.total ?? 0);
    } finally { setLoading(false); }
  }, [page, pageSize, activeTab]);

  useEffect(() => { fetchRecords(); }, [fetchRecords]);

  const handleApprove = (record: Withdrawal) => Modal.confirm({
    title: '确认通过', content: `确定通过「${record.nickname}」的 ¥${record.rmb_amount} 提现申请？`,
    onOk: async () => { await request.put(`/withdrawals/${record.id}/approve`); message.success('已通过'); await fetchRecords(); },
  });

  const handleReject = (record: Withdrawal) => { setCurrentRecord(record); setRejectModalVisible(true); rejectForm.resetFields(); };
  const confirmReject = async () => {
    const values = await rejectForm.validateFields();
    if (!currentRecord) return;
    await request.put(`/withdrawals/${currentRecord.id}/reject`, { reason: values.reason });
    message.success('已拒绝并退回金币');
    setRejectModalVisible(false);
    await fetchRecords();
  };

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id' }, { title: '用户ID', dataIndex: 'user_id', key: 'user_id' },
    { title: '昵称', dataIndex: 'nickname', key: 'nickname' },
    { title: '金币', dataIndex: 'gold_amount', key: 'gold_amount', render: (v: number) => v.toLocaleString() },
    { title: '金额', dataIndex: 'rmb_amount', key: 'rmb_amount', render: (v: number) => `¥${v}` },
    { title: '方式', dataIndex: 'method', key: 'method', render: (v: string) => v === 'wechat' ? '微信' : '支付宝' },
    { title: '状态', dataIndex: 'status', key: 'status', render: (v: string) => { const i = statusMap[v] || { label: v, color: 'default' }; return <Tag color={i.color}>{i.label}</Tag>; } },
    { title: '申请时间', dataIndex: 'created_at', key: 'created_at' },
    { title: '操作', key: 'action', render: (_: unknown, record: Withdrawal) => record.status !== 'pending'
      ? (record.reject_reason ? <span style={{ color: '#999' }}>原因：{record.reject_reason}</span> : '-')
      : <Space><Button type="primary" size="small" icon={<CheckOutlined />} onClick={() => handleApprove(record)}>通过</Button><Button danger size="small" icon={<CloseOutlined />} onClick={() => handleReject(record)}>拒绝</Button></Space> },
  ];

  const tabItems = ['all', 'pending', 'paid', 'rejected'].map((key) => ({ key, label: key === 'all' ? '全部' : statusMap[key].label }));
  return <div>
    <Tabs activeKey={activeTab} onChange={(key) => { setActiveTab(key); setPage(1); }} items={tabItems} style={{ marginBottom: 16 }} />
    <Table dataSource={records} columns={columns} rowKey="id" loading={loading} pagination={false} />
    <div style={{ marginTop: 16, textAlign: 'right' }}><Pagination current={page} pageSize={pageSize} total={total} onChange={setPage} showTotal={(n) => `共 ${n} 条`} /></div>
    <Modal title="拒绝提现" open={rejectModalVisible} onOk={confirmReject} onCancel={() => setRejectModalVisible(false)} okText="确认拒绝" cancelText="取消">
      <Form form={rejectForm} layout="vertical"><Form.Item label="拒绝原因" name="reason" rules={[{ required: true, message: '请填写拒绝原因' }]}><Input.TextArea rows={3} placeholder="请输入拒绝原因" /></Form.Item></Form>
    </Modal>
  </div>;
};

export default Withdrawals;
