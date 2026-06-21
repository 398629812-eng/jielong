import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.title,
    required this.sections,
  });

  final String title;
  final List<LegalSection> sections;

  static const privacy = LegalScreen(
    title: '隐私政策',
    sections: [
      LegalSection(
          '信息收集', '为完成登录、保存游戏进度和保障账号安全，应用会处理手机号、设备标识、游戏记录、金币流水和提现申请信息。'),
      LegalSection(
          '信息使用', '上述信息仅用于身份验证、游戏服务、奖励核算、风险控制和问题排查。测试版本不会向真实广告平台或支付平台提交数据。'),
      LegalSection('信息存储', '登录凭证保存在设备安全存储中，业务数据保存在服务端数据库中。运营方应限制后台权限并定期备份。'),
      LegalSection('用户权利', '用户可以退出登录、停止使用服务，并通过应用内公布的客服渠道申请查询、更正或删除个人信息。'),
      LegalSection('政策更新', '接入短信、广告或提现服务前，本政策应根据实际服务商和发布地区的要求更新。'),
    ],
  );

  static const agreement = LegalScreen(
    title: '用户协议',
    sections: [
      LegalSection('服务说明', '本应用提供成语接龙及测试奖励功能。当前广告、金币兑换和提现均为测试流程，不构成现金支付承诺。'),
      LegalSection('账号使用', '用户应妥善保管账号，不得利用程序漏洞、自动化工具或虚假设备信息获取奖励。'),
      LegalSection('游戏规则', '奖励结果以服务端记录为准。发现异常操作时，运营方可以暂停相关账号并核查记录。'),
      LegalSection('服务调整', '正式运营前，奖励比例、每日上限和提现规则可能调整；调整后的规则应在应用内明确展示。'),
      LegalSection('责任范围', '因设备、网络或第三方服务故障造成的暂时不可用，将在合理范围内修复并恢复服务。'),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(section.heading,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(section.body, style: const TextStyle(height: 1.7)),
            ],
          );
        },
      ),
    );
  }
}

class LegalSection {
  const LegalSection(this.heading, this.body);

  final String heading;
  final String body;
}
