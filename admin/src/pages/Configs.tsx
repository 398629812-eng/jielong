import React, { useEffect, useState } from 'react';
import { Card, Form, InputNumber, Button, Row, Col, message, Spin } from 'antd';
import { SaveOutlined } from '@ant-design/icons';
import request from '../api/request';

interface ConfigValues {
  ad_gold_reward: number;
  gold_to_rmb: number;
  withdraw_min: number;
  withdraw_max: number;
  daily_ad_limit: number;
  game_gold_per_round: number;
  game_gold_daily_cap: number;
  record_gold_reward: number;
  sign_in_base: number;
  spin_daily_limit: number;
}

const defaultConfigs: ConfigValues = {
  ad_gold_reward: 500,
  gold_to_rmb: 10000,
  withdraw_min: 10000,
  withdraw_max: 50000,
  daily_ad_limit: 50,
  game_gold_per_round: 10,
  game_gold_daily_cap: 1000,
  record_gold_reward: 2000,
  sign_in_base: 50,
  spin_daily_limit: 1,
};

const configItems = [
  { key: 'ad_gold_reward', label: '广告金币奖励', desc: '观看一次激励视频获得的金币数量', min: 0 },
  { key: 'gold_to_rmb', label: '金币兑换比例', desc: '多少金币兑换 1 元人民币', min: 1 },
  { key: 'withdraw_min', label: '最低提现门槛', desc: '用户提现所需的最低金币数', min: 0 },
  { key: 'withdraw_max', label: '单笔提现上限', desc: '单次提现的最高金币数', min: 0 },
  { key: 'daily_ad_limit', label: '每日广告上限', desc: '每名用户每天最多观看广告次数', min: 0 },
  { key: 'game_gold_per_round', label: '游戏每轮金币', desc: '每成功接龙一轮获得的金币', min: 0 },
  { key: 'game_gold_daily_cap', label: '游戏每日金币上限', desc: '每天通过游戏获得金币的上限', min: 0 },
  { key: 'record_gold_reward', label: '纪录刷新奖励', desc: '打破个人纪录时的额外金币奖励', min: 0 },
  { key: 'sign_in_base', label: '签到基础金币', desc: '每日签到获得的基础金币', min: 0 },
  { key: 'spin_daily_limit', label: '每日转盘次数', desc: '每名用户每天最多可转盘抽奖的次数', min: 0 },
] as const;

const Configs: React.FC = () => {
  const [form] = Form.useForm<ConfigValues>();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    request.get('/configs').then((res: any) => {
      const values = { ...defaultConfigs };
      for (const key of Object.keys(values) as (keyof ConfigValues)[]) {
        if (res.data[key] !== undefined) values[key] = Number(res.data[key]);
      }
      form.setFieldsValue(values);
    }).finally(() => setLoading(false));
  }, [form]);

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      await request.put('/configs', values);
      message.success('配置已保存');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Spin spinning={loading}>
      <Card title="系统配置" extra={<Button type="primary" icon={<SaveOutlined />} loading={saving} onClick={handleSave}>保存配置</Button>}>
        <Form form={form} layout="vertical">
          <Row gutter={[24, 0]}>
            {configItems.map((item) => (
              <Col xs={24} md={12} lg={8} key={item.key}>
                <Form.Item label={item.label} name={item.key} rules={[{ required: true, message: `请输入${item.label}` }]} extra={<span style={{ color: '#999', fontSize: 12 }}>{item.desc}</span>}>
                  <InputNumber min={item.min} precision={0} style={{ width: '100%' }} size="large" />
                </Form.Item>
              </Col>
            ))}
          </Row>
        </Form>
      </Card>
    </Spin>
  );
};

export default Configs;
