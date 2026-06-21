import React, { useCallback, useEffect, useState } from 'react';
import { Table, Button, Tag, Space, Modal, Form, Input, Tooltip, message, Popconfirm } from 'antd';
import { PlusOutlined, DeleteOutlined } from '@ant-design/icons';
import request from '../api/request';

interface Announcement {
  id: number;
  title: string;
  content: string;
  is_active: number;
  created_at: string;
}

const Announcements: React.FC = () => {
  const [data, setData] = useState<Announcement[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);
  const [form] = Form.useForm();

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const res: any = await request.get('/announcements');
      setData(res.data);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadData(); }, [loadData]);

  const handleDelete = async (id: number) => {
    await request.delete(`/announcements/${id}`);
    message.success('删除成功');
    await loadData();
  };

  const handleAdd = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      await request.post('/announcements', values);
      message.success('公告发布成功');
      setModalVisible(false);
      form.resetFields();
      await loadData();
    } finally {
      setSaving(false);
    }
  };

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 60 },
    { title: '标题', dataIndex: 'title', key: 'title' },
    { title: '内容', dataIndex: 'content', key: 'content', ellipsis: { showTitle: false }, render: (text: string) => <Tooltip placement="topLeft" title={text}><span>{text.length > 30 ? `${text.slice(0, 30)}...` : text}</span></Tooltip> },
    { title: '状态', dataIndex: 'is_active', key: 'is_active', render: (v: number) => v ? <Tag color="green">已发布</Tag> : <Tag>已停用</Tag> },
    { title: '创建时间', dataIndex: 'created_at', key: 'created_at' },
    { title: '操作', key: 'action', render: (_: unknown, record: Announcement) => <Space><Popconfirm title="确认删除" description={`确定删除公告“${record.title}”吗？`} onConfirm={() => handleDelete(record.id)}><Button type="link" danger icon={<DeleteOutlined />}>删除</Button></Popconfirm></Space> },
  ];

  return (
    <div>
      <div style={{ marginBottom: 16 }}><Button type="primary" icon={<PlusOutlined />} onClick={() => setModalVisible(true)}>新增公告</Button></div>
      <Table loading={loading} dataSource={data} columns={columns} rowKey="id" pagination={{ pageSize: 10, showTotal: (total) => `共 ${total} 条` }} />
      <Modal title="新增公告" open={modalVisible} confirmLoading={saving} onOk={handleAdd} onCancel={() => { setModalVisible(false); form.resetFields(); }} okText="发布" cancelText="取消" width={600}>
        <Form form={form} layout="vertical">
          <Form.Item label="标题" name="title" rules={[{ required: true, message: '请输入标题' }, { max: 100, message: '标题最多 100 字' }]}><Input placeholder="请输入公告标题" /></Form.Item>
          <Form.Item label="内容" name="content" rules={[{ required: true, message: '请输入内容' }]}><Input.TextArea rows={5} placeholder="请输入公告内容" /></Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default Announcements;
