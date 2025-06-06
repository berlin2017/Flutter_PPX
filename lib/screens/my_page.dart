import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_notifier.dart';
// 如果你使用了 CachedNetworkImage，请取消注释下一行
// import 'package:cached_network_image/cached_network_image.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool _isDarkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar 可以根据你的应用整体设计来决定是否需要，或者自定义
      // appBar: AppBar(
      //   title: const Text('我的'),
      // ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // floating: true,
            // pinned: true,
            expandedHeight: 180.0, // 根据实际头部内容调整
            backgroundColor: Colors.transparent, // AppBar背景设为透明，让头部内容自己控制背景
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildUserInfoSection(context),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                _buildActionButtonsSection(context),
                // _buildPromotionSection(context),
                _buildMainListSection(context),
                // _buildMoreServicesSection(context),
                _buildAppSettingsSection(context),
                const SizedBox(height: 20), // 底部留白
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    // 模拟图片中的头部样式
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16), // 调整padding以适应状态栏
      // color: Theme.of(context).primaryColor.withOpacity(0.1), // 示例背景色
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end, // 内容沉底，如果上面有其他元素
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                // backgroundImage: CachedNetworkImageProvider('YOUR_AVATAR_URL_HERE'), // 替换为真实头像
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '愤怒的蝴蝶侠',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('共1个微章'), // 示例文字
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to personal main page
                },
                child: const Text('个人主页 >'),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const [
              Text('关注 23'),
              SizedBox(width: 16),
              Text('粉丝 1'),
              SizedBox(width: 16),
              Text('获赞 10'),
            ],
          ),
          // "进入宠物乐园" 这部分可以根据实际需求添加
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(context, '帖子', '我发布的', Icons.article_outlined, Colors.blue[100]),
          _buildActionButton(context, '评论', '我发出的', Icons.comment_outlined, Colors.green[100]),
          _buildActionButton(context, '插眼', '期待后续', Icons.visibility_outlined, Colors.orange[100]),
          _buildActionButton(context, '收藏', '我的最爱', Icons.collections_bookmark_outlined, Colors.yellow[100]),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, String subtitle, IconData icon, Color? iconBackgroundColor) {
    return Expanded(
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: iconBackgroundColor,
                child: Icon(icon, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        // color: Colors.orangeAccent, // 示例背景色
        child: AspectRatio(
          aspectRatio: 16 / 5, // 调整为你图片广告的宽高比
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4), // Card 默认有圆角，这里可以不用
              // image: DecorationImage(
              //   image: CachedNetworkImageProvider('YOUR_PROMO_IMAGE_URL_HERE'), // 替换为真实图片
              //   fit: BoxFit.cover,
              // ),
            ),
            child: const Center(child: Text('推广横幅区域 (可替换为图片)', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))),
          ),
        ),
      ),
    );
  }

  Widget _buildMainListSection(BuildContext context) {
    return Column(
      children: [
        _buildListTile(context, '历史记录', Icons.history, () { /* TODO: Navigate */ }),
        _buildListTile(context, '金币', Icons.monetization_on_outlined, () { /* TODO: Navigate */ }),
        _buildListTileWithSubtitle(
          context,
          '创作中心',
          Icons.lightbulb_outline,
          [
            _buildCreatorStat('昨日新增播放', '0', Icons.play_arrow, Colors.red),
            _buildCreatorStat('昨日新增获赞', '0', Icons.thumb_up, Colors.blue),
          ],
          () { /* TODO: Navigate */ }
        ),
        _buildListTile(context, '原创特权', Icons.verified_user_outlined, () { /* TODO: Navigate */ }),
        const Divider(height: 20, indent: 16, endIndent: 16),
      ],
    );
  }
  
  Widget _buildCreatorStat(String label, String value, IconData icon, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$label ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              TextSpan(text: value, style: TextStyle(fontSize: 12, color: iconColor, fontWeight: FontWeight.bold)),
            ]
          )
        ),
      ],
    );
  }
  
  Widget _buildListTileWithSubtitle(BuildContext context, String title, IconData icon, List<Widget> subtitleWidgets, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: subtitleWidgets,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }


  Widget _buildListTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildMoreServicesSection(BuildContext context) {
    final services = [
      {'icon': Icons.admin_panel_settings_outlined, 'label': '神评鉴定'},
      {'icon': Icons.list_alt_outlined, 'label': '我的订单'},
      {'icon': Icons.security_outlined, 'label': '小黑屋'}, // 示意图标
      {'icon': Icons.shield_outlined, 'label': '安心借'},
      {'icon': Icons.favorite_border_outlined, 'label': '放心借'}, // 示意图标
      {'icon': Icons.feedback_outlined, 'label': '意见反馈'},
      {'icon': Icons.settings_outlined, 'label': '设置'},
      {'icon': Icons.privacy_tip_outlined, 'label': '隐私设置'}, // 示意图标
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('更多功能', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0, // 调整图标和文字的比例
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return InkWell(
                onTap: () {
                  // TODO: Handle service tap
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(service['icon'] as IconData, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      service['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 30),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection(BuildContext context) {
    // 从 Provider 获取 ThemeNotifier。listen: false 用于在回调中修改状态而不引起当前 build 重复。
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    // 获取当前主题模式用于UI展示，listen: true (默认) 会在主题改变时更新UI。
    final currentThemeMode = Provider.of<ThemeNotifier>(context).themeMode;

    IconData themeIcon;
    String currentThemeDescription;

    // 根据当前主题模式确定图标和描述文字
    switch (currentThemeMode) {
      case ThemeMode.light:
        themeIcon = Icons.brightness_7; // 浅色模式图标
        currentThemeDescription = '浅色模式';
        break;
      case ThemeMode.dark:
        themeIcon = Icons.brightness_3; // 深色模式图标
        currentThemeDescription = '深色模式';
        break;
      case ThemeMode.system:
      default:
        themeIcon = Icons.settings_brightness; // 跟随系统图标
        currentThemeDescription = '跟随系统';
        break;
    }

    return Column(
      children: [
        ListTile(
          leading: Icon(themeIcon),
          title: const Text('主题模式'),
          trailing: DropdownButton<ThemeMode>(
            value: currentThemeMode,
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('跟随系统'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('浅色模式'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('深色模式'),
              ),
            ],
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                themeNotifier.setThemeMode(newMode);
              }
            },
          ),
        ),

        ListTile(
          title: Center( // Center the Row containing the icon and text
            child: Row(
              mainAxisSize: MainAxisSize.min, // So the Row doesn't take full width unnecessarily
              children: <Widget>[
                const Icon(Icons.exit_to_app, color: Colors.red), // Your icon
                const SizedBox(width: 8), // Add some spacing between icon and text
                const Text('退出登录', style: TextStyle(color: Colors.red)), // Your text
              ],
            ),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: const Text('确认退出'),
                  content: const Text('你确定要退出登录吗？'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('取消'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('退出', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // TODO: 执行实际的退出登录操作
                        // 例如: 清除用户数据, 跳转到登录页
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已退出登录 (模拟)')),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
