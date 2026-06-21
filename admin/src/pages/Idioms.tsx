import React, { useCallback, useEffect, useState } from 'react';
import { Table, Input, Button, Space, Modal, Form, Upload, message, Pagination, Popconfirm } from 'antd';
import { SearchOutlined, PlusOutlined, UploadOutlined, DownloadOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import request from '../api/request';

interface Idiom {
  id: number;
  idiom: string;
  pinyin: string;
  pinyin_no_tones: string;
  first_char: string;
  first_pinyin: string;
  first_pinyin_no_tone: string;
  last_char: string;
  last_pinyin: string;
  last_pinyin_no_tone: string;
  meaning: string;
}

const Idioms: React.FC = () => {
  const [data, setData] = useState<Idiom[]>([]);
  const [inputKeyword, setInputKeyword] = useState('');
  const [keyword, setKeyword] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize] = useState(10);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);
  const [editingRecord, setEditingRecord] = useState<Idiom | null>(null);
  const [form] = Form.useForm();

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const res: any = await request.get('/idioms', { params: { page, pageSize, keyword } });
      setData(res.data.list);
      setTotal(res.data.total);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, keyword]);

  useEffect(() => { loadData(); }, [loadData]);

  const search = () => {
    setPage(1);
    setKeyword(inputKeyword.trim());
  };

  const handleAdd = () => {
    setEditingRecord(null);
    form.resetFields();
    setModalVisible(true);
  };

  const handleEdit = (record: Idiom) => {
    setEditingRecord(record);
    form.setFieldsValue(record);
    setModalVisible(true);
  };

  const handleDelete = async (id: number) => {
    await request.delete(`/idioms/${id}`);
    message.success('删除成功');
    if (data.length === 1 && page > 1) setPage(page - 1); else await loadData();
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      if (editingRecord) {
        await request.put(`/idioms/${editingRecord.id}`, values);
        message.success('编辑成功');
      } else {
        await request.post('/idioms', values);
        message.success('新增成功');
      }
      setModalVisible(false);
      await loadData();
    } finally {
      setSaving(false);
    }
  };

  const handleImport = (file: File) => {
    const reader = new FileReader();
    reader.onload = async (event) => {
      try {
        const idioms = JSON.parse(event.target?.result as string);
        if (!Array.isArray(idioms) || idioms.length === 0) throw new Error('JSON 内容必须是非空数组');
        const res: any = await request.post('/idioms/import', { idioms });
        message.success(`成功导入 ${res.data.count} 条成语`);
        setPage(1);
        await loadData();
      } catch (error) {
        if (error instanceof SyntaxError) message.error('文件不是有效的 JSON');
        else if (error instanceof Error && error.message.startsWith('JSON 内容')) message.error(error.message);
      }
    };
    reader.readAsText(file);
    return false;
  };

  const handleExport = async () => {
    const res: any = await request.post('/idioms/export');
    const blob = new Blob([JSON.stringify(res.data.idioms, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = `idioms_export_${Date.now()}.json`;
    anchor.click();
    URL.revokeObjectURL(url);
    message.success(`已导出 ${res.data.total} 条成语`);
  };

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 70 },
    { title: '成语', dataIndex: 'idiom', key: 'idiom', width: 120 },
    { title: '拼音', dataIndex: 'pinyin', key: 'pinyin', width: 180 },
    { title: '释义', dataIndex: 'meaning', key: 'meaning', ellipsis: true },
    { title: '首字拼音', dataIndex: 'first_pinyin', key: 'first_pinyin', width: 110 },
    { title: '尾字拼音', dataIndex: 'last_pinyin', key: 'last_pinyin', width: 110 },
    { title: '操作', key: 'action', width: 160, render: (_: unknown, record: Idiom) => <Space><Button type="link" icon={<EditOutlined />} onClick={() => handleEdit(record)}>编辑</Button><Popconfirm title="确认删除" description={`确定删除成语“${record.idiom}”吗？`} onConfirm={() => handleDelete(record.id)}><Button type="link" danger icon={<DeleteOutlined />}>删除</Button></Popconfirm></Space> },
  ];

  return (
    <div>
      <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: 8 }}>
        <Space.Compact><Input placeholder="搜索成语、首字或尾字" value={inputKeyword} onChange={(e) => setInputKeyword(e.target.value)} onPressEnter={search} style={{ width: 260 }} /><Button type="primary" icon={<SearchOutlined />} onClick={search}>搜索</Button></Space.Compact>
        <Space><Button icon={<PlusOutlined />} onClick={handleAdd}>新增</Button><Upload beforeUpload={handleImport} showUploadList={false} accept=".json,application/json"><Button icon={<UploadOutlined />}>导入 JSON</Button></Upload><Button icon={<DownloadOutlined />} onClick={handleExport}>导出 JSON</Button></Space>
      </div>
      <Table loading={loading} dataSource={data} columns={columns} rowKey="id" pagination={false} scroll={{ x: 900 }} />
      <div style={{ marginTop: 16, textAlign: 'right' }}><Pagination current={page} pageSize={pageSize} total={total} onChange={setPage} showTotal={(count) => `共 ${count} 条`} /></div>
      <Modal title={editingRecord ? '编辑成语' : '新增成语'} open={modalVisible} confirmLoading={saving} onOk={handleSave} onCancel={() => setModalVisible(false)} okText="保存" cancelText="取消" width={560}>
        <Form form={form} layout="vertical">
          <Form.Item label="成语" name="idiom" rules={[{ required: true, message: '请输入成语' }]}><Input /></Form.Item>
          <Form.Item label="拼音" name="pinyin" rules={[{ required: true, message: '请输入拼音' }]}><Input /></Form.Item>
          <Form.Item label="拼音（无声调）" name="pinyin_no_tones"><Input /></Form.Item>
          <Form.Item label="首字" name="first_char"><Input /></Form.Item>
          <Form.Item label="首字拼音" name="first_pinyin"><Input /></Form.Item>
          <Form.Item label="首字拼音（无声调）" name="first_pinyin_no_tone"><Input /></Form.Item>
          <Form.Item label="尾字" name="last_char"><Input /></Form.Item>
          <Form.Item label="尾字拼音" name="last_pinyin"><Input /></Form.Item>
          <Form.Item label="尾字拼音（无声调）" name="last_pinyin_no_tone"><Input /></Form.Item>
          <Form.Item label="释义" name="meaning"><Input.TextArea rows={3} /></Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default Idioms;
