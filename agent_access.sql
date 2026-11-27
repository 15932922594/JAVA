/*
 Navicat Premium Dump SQL

 Source Server         : test
 Source Server Type    : MySQL
 Source Server Version : 80039 (8.0.39)
 Source Host           : localhost:3306
 Source Schema         : agent_access

 Target Server Type    : MySQL
 Target Server Version : 80039 (8.0.39)
 File Encoding         : 65001

 Date: 27/11/2026 14:53:17
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for admin_log
-- ----------------------------
DROP TABLE IF EXISTS `admin_log`;
CREATE TABLE `admin_log`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `admin_id` bigint NOT NULL DEFAULT 0 COMMENT '操作人 id',
  `admin_name` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '操作人账号',
  `target` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '对象：archive/category/feed/mission/admin',
  `action` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '动作：CREATE/UPDATE/DELETE/LOGIN/PASSWORD',
  `detail` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '摘要说明',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_admin`(`admin_id` ASC) USING BTREE,
  INDEX `idx_time`(`create_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 29 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '后台操作日志' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of admin_log
-- ----------------------------
INSERT INTO `admin_log` VALUES (1, 1, 'admin', 'admin', 'LOGIN', '管理员登录', '2026-10-28 16:38:19');
INSERT INTO `admin_log` VALUES (2, 1, 'admin', 'admin', 'LOGIN', '管理员登录', '2026-10-29 14:02:18');
INSERT INTO `admin_log` VALUES (3, 4, 'TESTADMIN', 'admin', 'LOGIN', '管理员登录：TESTADMIN', '2026-10-29 14:36:40');
INSERT INTO `admin_log` VALUES (4, 4, 'TESTADMIN', 'user', 'PERMISSION', 'TESTPERM → 管理员', '2026-10-29 14:37:06');
INSERT INTO `admin_log` VALUES (5, 3, 'TESTPERM', 'admin', 'LOGIN', '管理员登录：TESTPERM', '2026-10-29 14:37:06');
INSERT INTO `admin_log` VALUES (6, 4, 'TESTADMIN', 'user', 'PERMISSION', 'TESTPERM → 默认', '2026-10-29 14:37:17');
INSERT INTO `admin_log` VALUES (7, 1, 'admin', 'admin', 'LOGIN', '管理员登录', '2026-10-29 14:37:18');
INSERT INTO `admin_log` VALUES (8, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-10-29 14:45:54');
INSERT INTO `admin_log` VALUES (9, 1, '爱打球的T', 'user', 'PERMISSION', 'UIADMIN → 默认', '2026-10-29 14:46:39');
INSERT INTO `admin_log` VALUES (10, 6, 'UIADMIN', 'admin', 'LOGIN', '管理员登录：UIADMIN', '2026-10-29 14:52:19');
INSERT INTO `admin_log` VALUES (11, 6, 'UIADMIN', 'admin', 'LOGIN', '管理员登录：UIADMIN', '2026-10-29 14:53:49');
INSERT INTO `admin_log` VALUES (12, 6, 'UIADMIN', 'admin', 'LOGIN', '管理员登录：UIADMIN', '2026-10-29 14:54:49');
INSERT INTO `admin_log` VALUES (13, 8, 'UICHK', 'admin', 'LOGIN', '管理员登录：UICHK', '2026-10-29 15:00:05');
INSERT INTO `admin_log` VALUES (14, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-10-29 15:03:10');
INSERT INTO `admin_log` VALUES (15, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-02 08:58:33');
INSERT INTO `admin_log` VALUES (16, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-05 13:58:46');
INSERT INTO `admin_log` VALUES (17, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-05 18:50:37');
INSERT INTO `admin_log` VALUES (18, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-05 21:58:10');
INSERT INTO `admin_log` VALUES (19, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-06 08:44:19');
INSERT INTO `admin_log` VALUES (20, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-09 09:30:00');
INSERT INTO `admin_log` VALUES (21, 1, 'admin', 'admin', 'LOGIN', '管理员登录', '2026-11-09 09:56:04');
INSERT INTO `admin_log` VALUES (22, 1, 'admin', 'armory', 'UPDATE', '武器配置：狂徒 价格=2500 需等级=3', '2026-11-09 09:56:10');
INSERT INTO `admin_log` VALUES (23, 1, 'admin', 'armory', 'UPDATE', '武器配置：狂徒 价格=2900 需等级=4', '2026-11-09 09:56:21');
INSERT INTO `admin_log` VALUES (24, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-11 16:18:03');
INSERT INTO `admin_log` VALUES (25, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-12 14:22:20');
INSERT INTO `admin_log` VALUES (26, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-12 14:26:23');
INSERT INTO `admin_log` VALUES (27, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-16 08:38:36');
INSERT INTO `admin_log` VALUES (28, 1, '爱打球的T', 'admin', 'LOGIN', '管理员登录：爱打球的T', '2026-11-16 08:47:32');

-- ----------------------------
-- Table structure for admin_user
-- ----------------------------
DROP TABLE IF EXISTS `admin_user`;
CREATE TABLE `admin_user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `username` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '登录账号（唯一）',
  `display_name` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '显示名',
  `password_hash` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT 'sha256(salt::password) hex',
  `salt` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '16 字节随机盐（32 位 hex）',
  `token` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '当前会话 token（单会话，重登覆盖）',
  `token_expires_at` datetime NULL DEFAULT NULL COMMENT 'token 过期时间',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1 启用，0 停用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_username`(`username` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '后台管理员' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of admin_user
-- ----------------------------
INSERT INTO `admin_user` VALUES (1, 'admin', '超级管理员', 'b0b168d92e122cca122586f50d2e1d05af219d8eed3d79945d51cabef6de5bd3', '5f8a9b3c1d2e4f60718293a4b5c6d7e8', 'd47e02ba1628457da9480d33f26c6d6b', '2026-11-11 09:56:04', 1, '2026-10-28 16:35:51', '2026-10-28 16:35:51');

-- ----------------------------
-- Table structure for agent_archive
-- ----------------------------
DROP TABLE IF EXISTS `agent_archive`;
CREATE TABLE `agent_archive`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `category_code` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '一级分类编码（archive_category.code）',
  `sub_code` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '二级分类编码（定位 / 枪型 / 模式）',
  `tier` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'B' COMMENT '分级：S / A / B',
  `code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '档案代号（英文，唯一），如 vector',
  `name` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '档案名称（展示用大写），如 VECTOR',
  `name_cn` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '中文名',
  `mono` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '单字符缩写，卡片水印用',
  `color` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '#FF4655' COMMENT '主题色，卡片主色',
  `bio` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '简介，参与关键词匹配',
  `story` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '人物故事 / 背景档案（\n\n 分段，详情弹窗展示）',
  `abilities` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '能力/特性 JSON 数组 [{slot,name,desc}]',
  `img` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '立绘地址，可为空（前端回退为 mono 徽标）',
  `firepower` int NOT NULL DEFAULT 0 COMMENT '火力',
  `mobility` int NOT NULL DEFAULT 0 COMMENT '机动',
  `control` int NOT NULL DEFAULT 0 COMMENT '控制',
  `defense` int NOT NULL DEFAULT 0 COMMENT '防御',
  `heat` int NOT NULL DEFAULT 0 COMMENT '热度，用于首页精选与排序',
  `featured` tinyint NOT NULL DEFAULT 0 COMMENT '1 首页精选',
  `sort` int NOT NULL DEFAULT 0 COMMENT '排序，越小越靠前',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1 启用，0 下线',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_code`(`code` ASC) USING BTREE,
  INDEX `idx_cat`(`category_code` ASC) USING BTREE,
  INDEX `idx_sub`(`sub_code` ASC) USING BTREE,
  INDEX `idx_tier`(`tier` ASC) USING BTREE,
  INDEX `idx_heat`(`heat` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 71 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '首页档案主表（特工/装备/任务）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of agent_archive
-- ----------------------------
INSERT INTO `agent_archive` VALUES (1, 'AGENT', 'ASSAULT', 'S', 'vector', 'Jett', '捷风', 'V', '#FF4655', '以极高机动性撕裂防线的突进型特工，擅长在瞬间改写交火态势。', '档案解密等级：S。\n\n VECTOR 原是环城竞速联盟最年轻的冠军车手，一场针对护送车队的伏击改变了她的轨迹——她以 217km/h 的极速连穿三道封锁线，把十二名伤员从火线上完整带回。战后审查官问她凭什么敢那样开，她只回了一句：「速度就是我的掩体。」\n\n 入队三年，她的突入记录无人打破：从破墙到占点，平均用时 1.7 秒。教官在评语栏里写：她不是在冲锋，是在瞬移。', '[\n    {\"slot\":\"Q\",\"name\":\"相位突进\",\"desc\":\"向准星方向瞬间位移一小段，用来抢点、拉枪线或脱离交叉火力。\"},\n    {\"slot\":\"E\",\"name\":\"破障射线\",\"desc\":\"放出一道穿透射线，短暂削弱命中敌人的护甲，正面硬刚更占便宜。\"},\n    {\"slot\":\"X\",\"name\":\"矢量过载\",\"desc\":\"短时疾行且移动射击精度不下降，适合一口气撕开一道防线。\"}\n  ]', '/agents/vector.png', 92, 76, 44, 38, 98, 1, 10, 1, '2026-10-28 16:35:52', '2026-11-05 14:53:13');
INSERT INTO `agent_archive` VALUES (2, 'AGENT', 'RECON', 'A', 'arclight', 'Viper', '蝰蛇', 'A', '#00E0C6', '用电弧脉冲扫描战场，为队伍点亮迷雾中的每一个目标。', '档案解密等级：A。\n\n ARCLIGHT 曾是深空监听站的值守员，在长达四年的孤站生活里，他练就了从宇宙噪声中分辨一句耳语的耐心。一次例行检修中，他从一段被判定为背景辐射的信号里，还原出敌方跳频通讯的完整频率表，整个战区的预警时间因此提前了十一分钟。\n\n 如今他把监听天线换成了电弧脉冲，战场在他眼中是一张不断刷新的点云图。队友的说法更直接：「他开枪之前，地图早就打完了。」', '[\n    {\"slot\":\"Q\",\"name\":\"电弧脉冲\",\"desc\":\"向身前扇区释放脉冲，被命中的敌人轮廓会被标记，隔着墙也能看见。\"},\n    {\"slot\":\"E\",\"name\":\"全域扫描\",\"desc\":\"一次性点亮附近区域的敌人位置，持续时间短，进点前摸站位最好用。\"},\n    {\"slot\":\"X\",\"name\":\"电网陷阱\",\"desc\":\"布下电网，敌人经过会被减速并暴露位置，兼顾封锁与预警。\"}\n  ]', '/agents/arclight.png', 58, 86, 72, 46, 91, 1, 11, 1, '2026-10-28 16:35:52', '2026-11-05 14:53:26');
INSERT INTO `agent_archive` VALUES (3, 'AGENT', 'CONTROL', 'S', 'phantom', 'Omen', '幽影', 'P', '#A66CFF', '制造幻象与烟幕，掌控每一次交火的节奏与视野。', '档案解密等级：S。\n\n 关于 PHANTOM 的入职档案只有一页，且一半被涂黑。已知信息：他曾在敌后情报部门服役九年，执行过十七次任务，无一次留下影像记录；他的上一任搭档坚称自己从未见过他的正脸。\n\n 他从不解释能力原理，只留下一句被全体队员记住的话：「你们看到的，是我想让你们看到的。」第一次和他在训练场对枪的人，最后都在朝空气开火。', '[\n    {\"slot\":\"Q\",\"name\":\"幻影分身\",\"desc\":\"生成一个向前走的分身诱饵，用来骗第一枪、确认敌人架在哪。\"},\n    {\"slot\":\"E\",\"name\":\"遮断烟幕\",\"desc\":\"在指定位置落下烟幕切断视野，进点、拆包、撤退都靠它。\"},\n    {\"slot\":\"X\",\"name\":\"错觉领域\",\"desc\":\"大范围幻象区，敌人视野受阻且分不清真假身，能强行改写交火节奏。\"}\n  ]', '/agents/phantom.png', 52, 74, 93, 50, 95, 1, 12, 1, '2026-10-28 16:35:52', '2026-11-05 14:53:40');
INSERT INTO `agent_archive` VALUES (4, 'AGENT', 'SENTINEL', 'A', 'onyx', 'Iso', '壹决', 'O', '#FFB443', '以坚固壁垒庇护队友，是阵地攻防中不可撼动的支点。', '档案解密等级：B。\n\n ONYX 是全队唯一拒绝佩枪的特工。他曾是一支山地救援队的队长，在一次雪崩中用身体撑住坍塌的冰缝整整四十分钟，让七名被困者全部脱险——他的左肩里至今留着三枚钢钉，阴雨天会替他记住那天的气温。\n\n 入队后，他把「守住」变成了战术：他站的防线没有后退这个词。指挥部对他的评估只有一行字：把任何交火地点，变成我方主场。', '[\n    {\"slot\":\"Q\",\"name\":\"岩壁屏障\",\"desc\":\"竖起一道可再生的墙体，封住通路或专门挡对面狙击的枪线。\"},\n    {\"slot\":\"E\",\"name\":\"哨位陷阱\",\"desc\":\"布置自动预警装置，敌人靠近就减速并暴露位置。\"},\n    {\"slot\":\"X\",\"name\":\"壁垒成型\",\"desc\":\"短时间展开加固防线，站在后面的队友受到的伤害明显减少。\"}\n  ]', '/agents/onyx.png', 46, 52, 64, 96, 88, 1, 13, 1, '2026-10-28 16:35:52', '2026-11-05 14:53:55');
INSERT INTO `agent_archive` VALUES (5, 'AGENT', 'CONTROL', 'A', 'tempest', 'Harbor', '海神', 'T', '#4DA6FF', '召唤风暴封锁通路，让敌人在自己的领地寸步难行。', '档案解密等级：A。\n\n TEMPEST 出生在气旋观测船「信风号」上，整个童年在风暴眼里度过。十六岁那年，她用自己的气象模型提前六小时预报了一场被官方判定「不可能生成」的台风，救下了一整座港口。\n\n 现在她召唤的风暴只封锁一件东西：敌人的退路。被她控住过通道的对手给出了一致评价：宁可绕路三公里。', '[\n    {\"slot\":\"Q\",\"name\":\"强风幕墙\",\"desc\":\"生成一堵风墙，敌人穿行时视野受损、移速下降。\"},\n    {\"slot\":\"E\",\"name\":\"乱流推挤\",\"desc\":\"用气流把敌人推向一侧，强行打乱他站位，为队友拉出击杀窗口。\"},\n    {\"slot\":\"X\",\"name\":\"风暴中心\",\"desc\":\"在一片区域降下持续风暴，长时间封锁通路，拖延或守点时极强。\"}\n  ]', '/agents/tempest.png', 54, 70, 90, 62, 84, 0, 14, 1, '2026-10-28 16:35:52', '2026-11-05 14:54:07');
INSERT INTO `agent_archive` VALUES (6, 'AGENT', 'ASSAULT', 'B', 'ember', 'Phoenix', '不死鸟', 'E', '#FF6B4A', '以烈焰灼烧前线的爆发型特工，高风险，也高回报。', '档案解密等级：S。\n\n EMBER 的档案从一个失败开始：爆破课程三次不及格，理由都是「当量超出教学大纲上限」。教官最后在评语里写：这不是学不会，是不甘心只炸那么大。\n\n 他是全队公认的疯子，也是公认的幸运儿——七次被判定「阵亡」的战报，七次都活着回来了。他的战前动员只有一句话：「烧完这把，就赢了。」', '[\n    {\"slot\":\"Q\",\"name\":\"燃焰喷发\",\"desc\":\"近距离喷射火焰，专门清理两个人就得挤过去的窄通道。\"},\n    {\"slot\":\"E\",\"name\":\"火墙封路\",\"desc\":\"在地面拉出一段火墙，穿过的敌人持续掉血，逼他们改路线。\"},\n    {\"slot\":\"X\",\"name\":\"燃尽冲刺\",\"desc\":\"自身短暂燃烧，移速和换弹大幅加快，代价是血量持续下降。\"}\n  ]', '/agents/ember.png', 90, 64, 52, 54, 79, 0, 15, 1, '2026-10-28 16:35:52', '2026-11-05 14:54:17');
INSERT INTO `agent_archive` VALUES (7, 'GEAR', 'RIFLE', 'S', 'vandal', 'Guardian', '戍卫', 'V', '#FF4655', '高伤害全自动步枪，远距离头部一枪致命，正面交火的标杆。', '流水线上的第一支 VANDAL 编号 V-0001，至今仍在一线服役，其命中率常年霸榜军械库。', '[\n    {\"slot\":\"优势\",\"name\":\"任意距离一枪爆头\",\"desc\":\"不管多远，打中头就是秒杀，远距离对枪的标杆。\"},\n    {\"slot\":\"优势\",\"name\":\"伤害不衰减\",\"desc\":\"远距离伤害没有距离惩罚，架点可以完全不考虑站位深度。\"},\n    {\"slot\":\"代价\",\"name\":\"后坐大\",\"desc\":\"连射很飘，要点射、要压枪，不适合闭着眼泼。\"}\n  ]', '/agents/vandal.png', 88, 52, 40, 30, 96, 1, 20, 1, '2026-10-28 16:35:52', '2026-11-05 14:55:54');
INSERT INTO `agent_archive` VALUES (8, 'GEAR', 'RIFLE', 'A', 'phantom-w', 'Vandal', '狂徒', 'P', '#A66CFF', '消音步枪，后坐可控，适合中距离压制与隐蔽推进。', '消音组件让它被称作「听不见的死神」，每一支出厂前都要在静音舱里过最后一道检测。', '[\n    {\"slot\":\"优势\",\"name\":\"消音\",\"desc\":\"开枪不会暴露自己的位置提示，隔着烟打人对方很难反查。\"},\n    {\"slot\":\"优势\",\"name\":\"后坐可控\",\"desc\":\"连发比劫掠者柔和得多，中距离压枪一串很稳。\"},\n    {\"slot\":\"代价\",\"name\":\"远距离衰减\",\"desc\":\"超过中远距离伤害明显下降，远点不如劫掠者。\"}\n  ]', '/agents/phantom-w.png', 76, 66, 52, 34, 90, 0, 21, 1, '2026-10-28 16:35:52', '2026-11-05 14:56:17');
INSERT INTO `agent_archive` VALUES (9, 'GEAR', 'SMG', 'A', 'spectre', 'Phantom', '幻影', 'S', '#00E0C6', '高射速冲锋枪，近距离泼洒压制，经济局的性价比之选。', '经济局之王。老队员的说法：手头紧的时候，SPECTRE 比勇气可靠。', '[\n    {\"slot\":\"优势\",\"name\":\"高射速泼洒\",\"desc\":\"近距离短时间叠出成吨伤害，贴上脸几乎必胜。\"},\n    {\"slot\":\"优势\",\"name\":\"跑打稳定\",\"desc\":\"移动射击散布小，边走边输出也不至于全飘。\"},\n    {\"slot\":\"代价\",\"name\":\"距离衰减\",\"desc\":\"稍微远一点伤害就掉，中远距离基本打不动。\"}\n  ]', '/agents/spectre.png', 70, 74, 44, 28, 82, 0, 22, 1, '2026-10-28 16:35:52', '2026-11-05 14:50:33');
INSERT INTO `agent_archive` VALUES (10, 'GEAR', 'SNIPER', 'S', 'operator', 'OPERATOR', '冥狙', 'O', '#FFB443', '一击必杀的重型狙击枪，架点封锁整条通路的终极答案。', '每一支 OPERATOR 的镜桥都由匠人手工校准，编号刻在枪托内侧，遗失即全员追责。', '[\n    {\"slot\":\"优势\",\"name\":\"一枪必杀\",\"desc\":\"打中躯干直接终结，哪怕打腿也是重伤。\"},\n    {\"slot\":\"优势\",\"name\":\"封锁通路\",\"desc\":\"一个人架枪就能封死整条主路，对面必须花道具强行开。\"},\n    {\"slot\":\"代价\",\"name\":\"贵且笨重\",\"desc\":\"价格高、移速慢、开镜慢，一旦掉枪代价巨大。\"}\n  ]', '/agents/operator.png', 99, 30, 36, 44, 93, 1, 23, 1, '2026-10-28 16:35:52', '2026-10-28 16:54:40');
INSERT INTO `agent_archive` VALUES (11, 'GEAR', 'SNIPER', 'B', 'marshal', 'MARSHAL', '鸟狙', 'M', '#4DA6FF', '轻型狙击枪，机动性更好，命中躯干即可终结交火。', '西部时代的精神续作。MARSHAL 的准星上没有多余的花纹，因为它只服务一件事。', '[\n    {\"slot\":\"优势\",\"name\":\"轻便好上手\",\"desc\":\"比战神便宜也轻得多，转移和补点灵活得多。\"},\n    {\"slot\":\"优势\",\"name\":\"躯干终结\",\"desc\":\"胸腹以上一枪致命，中距离一枪一个。\"},\n    {\"slot\":\"代价\",\"name\":\"容错低\",\"desc\":\"打腿杀不掉，开镜后不能连发，节奏慢。\"}\n  ]', '/agents/marshal.png', 82, 58, 40, 36, 71, 0, 24, 1, '2026-10-28 16:35:52', '2026-10-28 16:53:26');
INSERT INTO `agent_archive` VALUES (12, 'GEAR', 'SIDEARM', 'B', 'classic', 'CLASSIC', '标配', 'C', '#FF6B4A', '开局标配手枪，右键三连发在贴脸距离拥有惊喜爆发。', '所有人拿到的第一支枪。训练营墙上的标语：CLASSIC 用得好，你缺的从来不是枪。', '[\n    {\"slot\":\"优势\",\"name\":\"开局自带\",\"desc\":\"每回合白给，经济落后时最稳的兜底武器。\"},\n    {\"slot\":\"优势\",\"name\":\"右键三连\",\"desc\":\"贴脸三连发爆发很高，近距离容错极低。\"},\n    {\"slot\":\"代价\",\"name\":\"远距离无力\",\"desc\":\"超过中距离伤害骤降，别指望用它架远点。\"}\n  ]', '/agents/classic.png', 54, 60, 32, 26, 68, 0, 25, 1, '2026-10-28 16:35:52', '2026-10-28 16:53:41');
INSERT INTO `agent_archive` VALUES (13, 'GEAR', 'SIDEARM', 'A', 'sheriff', 'SHERIFF', '正义', 'H', '#FF4655', '高伤害左轮，一发入魂，是翻盘局最廉价的希望。', '赌徒的选择。一发命中叫翻盘，一发落空叫下班。', '[\n    {\"slot\":\"优势\",\"name\":\"躯干一枪\",\"desc\":\"打身子也是一枪致命，不用非得爆头。\"},\n    {\"slot\":\"优势\",\"name\":\"便宜高回报\",\"desc\":\"价格低但威力接近步枪，翻盘局最常见的选择。\"},\n    {\"slot\":\"代价\",\"name\":\"弹少且慢\",\"desc\":\"弹匣小、开火间隔长，空一枪就是致命失误。\"}\n  ]', '/agents/sheriff.png', 86, 50, 34, 30, 87, 0, 26, 1, '2026-10-28 16:35:52', '2026-10-28 16:53:51');
INSERT INTO `agent_archive` VALUES (14, 'GEAR', 'RIFLE', 'A', 'odin', 'Ares', '战神', 'D', '#00E0C6', '弹链供弹的重机枪，穿墙压制能力冠绝全场。', '代号来自北欧主神。士兵们说，它开火的时候，整条走廊都在替对面祈祷。', '[\n    {\"slot\":\"优势\",\"name\":\"弹链压制\",\"desc\":\"超大弹容持续输出，一个人就能压死一条通道。\"},\n    {\"slot\":\"优势\",\"name\":\"穿墙射击\",\"desc\":\"子弹能打穿墙体，可以直接透过掩体验证甚至击杀。\"},\n    {\"slot\":\"代价\",\"name\":\"又重又慢\",\"desc\":\"移速慢、开镜慢，架点无敌但被人绕后基本没救。\"}\n  ]', '/agents/odin.png', 94, 24, 58, 48, 80, 0, 27, 1, '2026-10-28 16:35:52', '2026-11-05 14:50:40');
INSERT INTO `agent_archive` VALUES (15, 'MISSION', 'RANKED', 'A', 'ascent', 'ASCENT', '幽邃地窟', 'A', '#4DA6FF', '双点位地图，中路可开闭的闸门决定了整局的攻防节奏。', '高空平台 ASCENT 由旧轨道电梯中转站改建，中央闸门的开合至今沿用战前的机械逻辑。', '[\n  {\"slot\":\"适合枪械\",\"name\":\"步枪 + 狙击\",\"desc\":\"长道与中路枪线开阔，步枪中远距离最稳；狙击架长道收益高。冲锋枪只在 A 点管道与贴脸补枪时有用。\"},\n  {\"slot\":\"进攻\",\"name\":\"先夺中路控制\",\"desc\":\"用烟封住闸门两侧再开闸，配合闪光切 A/B 连接。没有道具就别硬冲长道，容易被一个人架死。\"},\n  {\"slot\":\"防守\",\"name\":\"闸门 + 长道架枪\",\"desc\":\"开局用闸门切断中路视野，一人架长道、一人守 B 主道，留一个自由人随时补位。\"},\n  {\"slot\":\"节奏\",\"name\":\"中慢速控图\",\"desc\":\"胜负由信息和道具决定，适合愿意慢慢磨掉对面耐心的队伍。\"}\n]', '/missions/ascent.png', 62, 70, 66, 58, 92, 1, 30, 1, '2026-10-28 16:35:52', '2026-11-05 14:20:31');
INSERT INTO `agent_archive` VALUES (16, 'MISSION', 'RANKED', 'S', 'bind', 'BIND', '天枢云阙', 'B', '#A66CFF', '无中路的双点图，两处单向传送门让绕后变得随心所欲。', 'BIND 的单向传送门是战前物流网络的遗产，如今搬运的只有子弹与坏消息。', '[\n  {\"slot\":\"适合枪械\",\"name\":\"冲锋枪 / 霰弹\",\"desc\":\"传送门与短道全是贴脸距离，冲锋枪和霰弹爆发最高；狙击只在 A 短与 B 长窗有价值。\"},\n  {\"slot\":\"进攻\",\"name\":\"传送门做假动作\",\"desc\":\"先在 A 制造动静再从传送门转 B，或者反过来。两个点必须同时给压力，单点硬打必被回防。\"},\n  {\"slot\":\"防守\",\"name\":\"卡住传送出口\",\"desc\":\"别站在门的正对面，提前卡住出口侧身位；B 点长窗一定要有人架，否则被一个人看穿全图。\"},\n  {\"slot\":\"节奏\",\"name\":\"快节奏转点\",\"desc\":\"全图没有中路缓冲，一旦掉点就是几秒内的攻防互换，谁先转谁占便宜。\"}\n]', '/missions/bind.png', 66, 78, 70, 54, 90, 0, 31, 1, '2026-10-28 16:35:52', '2026-11-05 14:20:31');
INSERT INTO `agent_archive` VALUES (17, 'MISSION', 'RANKED', 'A', 'haven', 'HAVEN', '莲花古城', 'H', '#FFB443', '罕见的三点位地图，战线被拉长，信息收集比枪法更重要。', 'HAVEN 原是边境疗养院，三点位的布局让它成为侦察兵最爱的战场。', '[\n  {\"slot\":\"适合枪械\",\"name\":\"步枪全能\",\"desc\":\"三条战线距离接近，步枪最不容易吃亏；狙击只在 C 长道与 A 长有价值，控场靠烟与燃烧瓶。\"},\n  {\"slot\":\"进攻\",\"name\":\"先拿一点再夹 B\",\"desc\":\"三点图最忌讳平均分兵，建议两人压 A 或 C 其中一点，三人从中路夹 B，逼对面来回救。\"},\n  {\"slot\":\"防守\",\"name\":\"一人一区 + 快速轮转\",\"desc\":\"三个点各留一人报信息，靠轮转补位；这张图信息收集比枪法更重要。\"},\n  {\"slot\":\"节奏\",\"name\":\"战线长 · 消耗战\",\"desc\":\"容易出现长时间拉锯，注意道具与经济的分配，别把把梭哈。\"}\n]', '/missions/haven.png', 60, 64, 74, 62, 86, 0, 32, 1, '2026-10-28 16:35:52', '2026-11-05 14:20:31');
INSERT INTO `agent_archive` VALUES (18, 'MISSION', 'TRAINING', 'B', 'range', 'RANGE', '靶场', 'R', '#3DDC97', '训练场，靶机与 bots 全开放，压枪与急停的日常修行地。', 'RANGE 的靶机每天被击倒两万次，然后被维修技师救活两万次。', '[\n  {\"slot\":\"适合枪械\",\"name\":\"全枪械开放\",\"desc\":\"步枪练压枪与弹道，冲锋枪练急停与身法，狙击练甩枪与预瞄，靶场不限制经济。\"},\n  {\"slot\":\"进攻\",\"name\":\"专注专项练习\",\"desc\":\"固定靶练准度、移动靶练跟枪，建议每次只练一个项目，10 分钟一组。\"},\n  {\"slot\":\"节奏\",\"name\":\"从静止靶开始\",\"desc\":\"先把 30 米静止靶打稳，再上移动靶与跳靶，最后再进实战，别一上来就练身法。\"}\n]', '/missions/range.png', 30, 40, 20, 20, 74, 0, 33, 1, '2026-10-28 16:35:52', '2026-11-05 14:20:31');
INSERT INTO `agent_archive` VALUES (19, 'MISSION', 'EVENT', 'S', 'nightfall', 'NIGHTFALL', '源工重镇', 'N', '#FF4655', '限时行动：夜幕下的据点争夺，视野受限，投掷物价值翻倍。', 'NIGHTFALL 行动只在停电的街区展开，目击报告里提到最多的东西是红色探照灯。', '[\n  {\"slot\":\"适合枪械\",\"name\":\"冲锋枪 / 霰弹\",\"desc\":\"视野受限，交火距离被压到十几米内，近距离爆发武器吃香，狙击价值明显下降。\"},\n  {\"slot\":\"进攻\",\"name\":\"道具开路\",\"desc\":\"闪光与烟必带，先照亮再进点，贴着探照灯边缘推进，别在黑暗里直着走。\"},\n  {\"slot\":\"防守\",\"name\":\"卡转角听脚步\",\"desc\":\"利用黑暗卡住转角与窄道，听见脚步再拉出去，主动拉枪线基本等于送。\"},\n  {\"slot\":\"节奏\",\"name\":\"慢而闷\",\"desc\":\"听觉和投掷物的价值翻倍，谁先暴露谁先死，耐心比手速重要。\"}\n]', '/missions/nightfall.png', 78, 72, 80, 60, 89, 1, 34, 1, '2026-10-28 16:35:52', '2026-11-05 14:46:04');
INSERT INTO `agent_archive` VALUES (20, 'MISSION', 'EVENT', 'B', 'breakout', 'BREAKOUT', '盐海矿镇', 'K', '#FF6B4A', '限时行动：护送与突围交替，节奏快到没有喘息窗口。', 'BREAKOUT 的原型是一次真实的监狱护送行动，代号沿用至今。', '[\n  {\"slot\":\"适合枪械\",\"name\":\"步枪 + 冲锋枪混编\",\"desc\":\"中近距离连续交火，步枪打主线、冲锋枪贴脸护航，狙击带一把就够。\"},\n  {\"slot\":\"进攻\",\"name\":\"抱团推进\",\"desc\":\"护送目标时全队跟车走，别单走；用烟墙切断高台枪线，把对面逼进近身距离。\"},\n  {\"slot\":\"防守\",\"name\":\"两层埋伏\",\"desc\":\"远端卡视野、近端卡转角，重点封锁撤离路口，别把人都堆在最前面。\"},\n  {\"slot\":\"节奏\",\"name\":\"高节奏连续交战\",\"desc\":\"一波接一波，几乎没有喘息窗口，经济管理比单局枪法更影响结果。\"}\n]', '/missions/breakout.png', 74, 80, 56, 46, 70, 0, 35, 1, '2026-10-28 16:35:52', '2026-11-05 14:45:02');
INSERT INTO `agent_archive` VALUES (21, 'AGENT', 'CONTROL', 'S', 'anvil', 'ANVIL', '铁砧', 'N', '#F08A4B', '以战术地图调度轨道支援的指挥型控场，烟幕与火力覆盖让推进路线变得可靠。', '档案解密等级：Ω。\n\n ANVIL 出身轨道炮兵部队，退役后仍坚持随身带着那台老式战术地图终端。年轻士兵问他为什么不用新系统，他指了指屏幕上的手绘标记：「机器算得出弹道，算不出人会不会慌。」\n\n 他的支援从不讲花哨：一片烟幕挡住视线，一发燃烧弹逼出掩体，最后一道天基光束收尾。指挥部对他的评价只有一句——把复杂问题变成三步流程。', '[{\"slot\":\"C\",\"name\":\"空投烟幕\",\"desc\":\"在战术地图上选点，空投烟幕切断关键点位视野。\"},{\"slot\":\"Q\",\"name\":\"灼地弹\",\"desc\":\"投出燃烧弹形成持续燃烧区，逼敌人离开掩体。\"},{\"slot\":\"E\",\"name\":\"战意信标\",\"desc\":\"部署增益装置，强化范围内队友的作战状态。\"},{\"slot\":\"X\",\"name\":\"天罚光柱\",\"desc\":\"引导轨道光束覆盖指定区域，高额伤害清场。\"}]', '/agents/anvil.png', 78, 44, 92, 68, 86, 0, 16, 1, '2026-11-26 14:15:17', '2026-11-27 14:34:15');
INSERT INTO `agent_archive` VALUES (22, 'AGENT', 'CONTROL', 'A', 'nebula', 'NEBULA', '星云', 'N', '#A66CFF', '以星界投影重塑战场，引力与星云让整片区域按她的节奏移动。', '档案解密等级：Ω。\n\n NEBULA 曾在深空天文台绘制过三百二十七张引力异常图，同行说她看星图像在看一张棋盘。一次观测事故后，她的投影能力再也离不开那套星界坐标系统——她必须先布下星体，才能把力量投到战场。\n\n 队友评价她控场像下棋：先摆好几颗星，再让对手在不知不觉中走进引力井。', '[{\"slot\":\"C\",\"name\":\"星界布点\",\"desc\":\"预先布置星体，作为其他技能的作用原点。\"},{\"slot\":\"Q\",\"name\":\"星震脉冲\",\"desc\":\"在星体处引爆震荡，打乱范围内敌人站位。\"},{\"slot\":\"E\",\"name\":\"星霭烟幕\",\"desc\":\"生成可反复生效的星云烟幕，切断视线。\"},{\"slot\":\"X\",\"name\":\"引力视界\",\"desc\":\"展开巨大重力场，将敌人拉扯并聚集后爆发。\"}]', '/agents/nebula.png', 58, 46, 96, 64, 84, 0, 17, 1, '2026-11-26 14:15:17', '2026-11-27 14:34:15');
INSERT INTO `agent_archive` VALUES (23, 'AGENT', 'CONTROL', 'A', 'cinder', 'CINDER', '复燃', 'C', '#FF7EB6', '不把死亡当终点的控场者，倒下后仍能布下烟幕，并重新回到战场。', '档案解密等级：Ω。\n\n CINDER 的入职测试有一道著名题目：在判定阵亡后继续完成控场。她做到了，并对考官说：「你们把它叫死亡，我把它叫换一个位置站着。」\n\n 她是队里最不怕送的人，也是最让对手绝望的人——因为倒下的那一刻，往往才是她烟幕真正落下的时候。', '[{\"slot\":\"C\",\"name\":\"惑影干扰\",\"desc\":\"投出干扰装置，影响范围内敌人的判断。\"},{\"slot\":\"Q\",\"name\":\"虚招迷惑\",\"desc\":\"制造假信息与假脚步，让敌人误判她的位置。\"},{\"slot\":\"E\",\"name\":\"余烟帷幕\",\"desc\":\"布置烟幕，阵亡后仍可继续施放。\"},{\"slot\":\"X\",\"name\":\"涅槃重生\",\"desc\":\"阵亡后选择地点重返战场，再次加入交火。\"}]', '/agents/cinder.png', 72, 66, 88, 52, 83, 0, 18, 1, '2026-11-26 14:15:17', '2026-11-27 14:34:15');
INSERT INTO `agent_archive` VALUES (24, 'AGENT', 'CONTROL', 'A', 'kinetic', 'KINETIC', '念涡', 'K', '#7DF9FF', '以念力改变道具轨迹的控场者，把每一次投掷都变成难以预判的奇袭。', '档案解密等级：Ω。\n\n KINETIC 小时候被诊断出一种奇怪能力：扔出去的东西总会在半空拐弯。她把这个「毛病」练成了战术——手雷、烟幕、闪光，所有直线都可能变成弧线。\n\n 训练官的评语很直白：不要试图预判她的投掷，因为你预判的那条线，她根本没打算走。', '[{\"slot\":\"C\",\"name\":\"念动锚点\",\"desc\":\"布置锚点，可在空中悬停后飞向锚点位置。\"},{\"slot\":\"Q\",\"name\":\"折光飞弹\",\"desc\":\"投出可中途转向的道具，命中后致盲目击者。\"},{\"slot\":\"E\",\"name\":\"引力漩涡\",\"desc\":\"投出引力道具，拉扯中心目标并震荡周围。\"},{\"slot\":\"X\",\"name\":\"悬浮领域\",\"desc\":\"释放可制导能量并引爆，令范围内所有人悬浮。\"}]', '/agents/kinetic.png', 66, 74, 90, 54, 82, 0, 19, 1, '2026-11-26 14:15:17', '2026-11-27 14:34:15');
INSERT INTO `agent_archive` VALUES (25, 'AGENT', 'ASSAULT', 'S', 'detonate', 'DETONATE', '爆裂', 'D', '#FF6B4A', '把爆破当成艺术的突击手，靠连环爆炸撕开狭小空间里的僵局。', '档案解密等级：Ω。\n\n DETONATE 的爆破教官只给她上过一节课，课后把教材收走：「你不需要教了，你需要的是离你远一点。」\n\n 她的战术笔记最后一页写着一条原则：如果一条路能走过去，那就炸开它；如果炸不开，说明当量还不够。', '[{\"slot\":\"C\",\"name\":\"爆破机器人\",\"desc\":\"操控机器人追击首个敌人并引爆。\"},{\"slot\":\"Q\",\"name\":\"震荡炸药\",\"desc\":\"投掷爆炸包，击退并伤害附近敌人。\"},{\"slot\":\"E\",\"name\":\"飞溅雷\",\"desc\":\"延迟爆炸后生成子爆弹，双杀可刷新充能。\"},{\"slot\":\"X\",\"name\":\"焰尾火箭\",\"desc\":\"发射大威力火箭，触面爆炸清场。\"}]', '/agents/detonate.png', 94, 72, 46, 40, 90, 0, 20, 1, '2026-11-26 14:15:17', '2026-11-27 14:40:37');
INSERT INTO `agent_archive` VALUES (26, 'AGENT', 'ASSAULT', 'A', 'sanguine', 'SANGUINE', '血契', 'S', '#E5484D', '以击败延续战力的吸血型突击手，越打越冷静，越打越难缠。', '档案解密等级：Ω。\n\n SANGUINE 从不讳言自己的原则：她只相信已经倒下的敌人。每一次击败对她而言都是一次确认——确认自己还站在场上。\n\n 队友说她的状态曲线很奇怪，开局平平无奇，第一滴血之后就开始变得锋利。她本人对此的解释是：「我不需要状态，我需要战果。」', '[{\"slot\":\"C\",\"name\":\"夺目之吻\",\"desc\":\"干扰视线，削弱目击她的敌人。\"},{\"slot\":\"Q\",\"name\":\"汲魂疗伤\",\"desc\":\"击败受伤敌人后恢复自身生命。\"},{\"slot\":\"E\",\"name\":\"虚化撤离\",\"desc\":\"击败敌人后短暂无敌并脱离交火。\"},{\"slot\":\"X\",\"name\":\"血契女皇\",\"desc\":\"大幅强化战斗续航与收割能力。\"}]', '/agents/sanguine.png', 90, 70, 48, 42, 88, 0, 21, 1, '2026-11-26 14:15:17', '2026-11-27 14:40:37');
INSERT INTO `agent_archive` VALUES (27, 'AGENT', 'ASSAULT', 'A', 'rift', 'RIFT', '裂隙', 'R', '#7B61FF', '用传送与假情报绕开正面火力的突击手，专挑敌人最想不到的方向出现。', '档案解密等级：Ω。\n\n RIFT 的入队考核是穿过一栋布满摄像机的训练楼，不许触发任何警报。他交卷用了四十一秒，监控回放里却只有一串假脚步声。\n\n 他解释自己的战术：「正面是给对手看的，我只需要从他们没看的地方出来。」', '[{\"slot\":\"C\",\"name\":\"伪步诱敌\",\"desc\":\"制造假脚步声，引敌人朝错误方向架枪。\"},{\"slot\":\"Q\",\"name\":\"裂隙穿行\",\"desc\":\"布置印记并瞬移，绕开正面火力。\"},{\"slot\":\"E\",\"name\":\"侧翼闪爆\",\"desc\":\"穿墙投掷闪光，为进场创造窗口。\"},{\"slot\":\"X\",\"name\":\"虚空潜行\",\"desc\":\"进入异维度隐身穿越战场。\"}]', '/agents/rift.png', 78, 88, 66, 38, 87, 0, 22, 1, '2026-11-26 14:15:17', '2026-11-27 14:40:37');
INSERT INTO `agent_archive` VALUES (28, 'AGENT', 'ASSAULT', 'S', 'volt', 'VOLT', '电涌', 'V', '#FFE14D', '以电弧加速撕开防线的突击手，滑行与闪电让对手来不及架枪。', '档案解密等级：Ω。\n\n VOLT 在加入前是城市电网的抢修员，习惯在雷雨里爬上高压塔。队友问她怕不怕电，她反问：「你们怕不怕我？」\n\n 她的进攻节奏像一次短路——没有预兆，没有过程，只有结果。', '[{\"slot\":\"C\",\"name\":\"折光闪电\",\"desc\":\"投出可反弹的闪光，致盲视线内敌人。\"},{\"slot\":\"Q\",\"name\":\"电弧幕墙\",\"desc\":\"生成阻挡视线的电流屏障。\"},{\"slot\":\"E\",\"name\":\"疾电冲刺\",\"desc\":\"高速滑行，快速穿越危险区域。\"},{\"slot\":\"X\",\"name\":\"过载风暴\",\"desc\":\"进入高速状态并持续释放闪电输出。\"}]', '/agents/volt.png', 86, 94, 50, 36, 89, 0, 23, 1, '2026-11-26 14:15:17', '2026-11-27 14:40:37');
INSERT INTO `agent_archive` VALUES (29, 'AGENT', 'ASSAULT', 'A', 'blur', 'BLUR', '瞬驰', 'B', '#66FFB3', '把速度练成本能的突击手，一次冲刺就能改变交火发生的地点。', '档案解密等级：Ω。\n\n BLUR 的训练记录里有一条被反复引用的数据：从听到枪声到出现在敌人侧后方，平均 0.9 秒。\n\n 她很少讲战术，只留下一句：「别追我，你追不上的；你该做的是在我落地之前把枪口转过去。」', '[{\"slot\":\"C\",\"name\":\"疾驰突进\",\"desc\":\"短距高速冲刺，迅速改变交火位置。\"},{\"slot\":\"Q\",\"name\":\"缚光索\",\"desc\":\"释放束缚装置，限制敌人移动。\"},{\"slot\":\"E\",\"name\":\"跃迁跳\",\"desc\":\"高机动跳跃，越过常规架点。\"},{\"slot\":\"X\",\"name\":\"极速领域\",\"desc\":\"进入极速状态，短时间内连续突进。\"}]', '/agents/blur.png', 82, 96, 48, 34, 85, 0, 24, 1, '2026-11-26 14:15:17', '2026-11-27 14:42:43');
INSERT INTO `agent_archive` VALUES (30, 'AGENT', 'ASSAULT', 'A', 'resonance', 'RESONANCE', '共鸣', 'R', '#C77DFF', '用声波同时强化队友与压制敌人的突击手，进场时机由他亲手打拍子。', '档案解密等级：Ω。\n\n RESONANCE 曾是地下乐队的鼓手，后来把节拍器改成了战术工具。他说交火和演奏没有区别：早半拍是送，晚半拍是看戏。\n\n 队友对他的信任很简单——他敲下第一拍的时候，所有人一起进场。', '[{\"slot\":\"C\",\"name\":\"电音脉冲\",\"desc\":\"投出脉冲装置，在震荡与治疗两种效果间切换。\"},{\"slot\":\"Q\",\"name\":\"共振旋律\",\"desc\":\"为队友与自己提供作战强化与加速。\"},{\"slot\":\"E\",\"name\":\"声波帷幕\",\"desc\":\"在战术地图上选点施放烟幕。\"},{\"slot\":\"X\",\"name\":\"音脉强袭\",\"desc\":\"释放声波区域，击退并减速范围内敌人。\"}]', '/agents/resonance.png', 74, 68, 84, 56, 84, 0, 25, 1, '2026-11-26 14:15:17', '2026-11-27 14:42:43');
INSERT INTO `agent_archive` VALUES (31, 'AGENT', 'RECON', 'S', 'talon', 'TALON', '猎隼', 'T', '#4DA6FF', '以侦察箭与无人机点亮黑暗的侦察兵，开枪之前整张地图已经写好了答案。', '档案解密等级：Ω。\n\n TALON 在冻原上长大，十二岁就能靠风声判断猎物距离。入队后他把弓换成了制导箭，但那套「先听再射」的习惯没变。\n\n 他的侦察报告几乎没有废话，通常只有三行：人在哪、几条枪、从哪进。', '[{\"slot\":\"C\",\"name\":\"猎隼无人机\",\"desc\":\"操控无人机发射定位镖揭露敌人。\"},{\"slot\":\"Q\",\"name\":\"雷霆箭\",\"desc\":\"爆炸箭矢造成范围伤害，可蓄力或弹跳。\"},{\"slot\":\"E\",\"name\":\"侦测箭\",\"desc\":\"持续揭露技能与视线范围内的敌人。\"},{\"slot\":\"X\",\"name\":\"连环猎矢\",\"desc\":\"连续发射能量箭，命中后持续标记敌人。\"}]', '/agents/talon.png', 74, 72, 84, 44, 92, 0, 26, 1, '2026-11-26 14:15:17', '2026-11-27 14:42:43');
INSERT INTO `agent_archive` VALUES (32, 'AGENT', 'RECON', 'A', 'tremor', 'TREMOR', '震波', 'T', '#F4A261', '把地震波当作开门工具的侦察兵，穿墙的冲击让掩体失去意义。', '档案解密等级：Ω。\n\n TREMOR 的身体经过生化改造，骨密度是常人的两倍——医生说这是为了承受他自己制造的反震。他只关心另一件事：墙能不能挡住他。\n\n 答案通常是不能。', '[{\"slot\":\"C\",\"name\":\"地脉冲击\",\"desc\":\"穿墙爆破，对范围内敌人造成大量伤害。\"},{\"slot\":\"Q\",\"name\":\"穿墙闪爆\",\"desc\":\"穿墙引爆闪光，致盲目击者。\"},{\"slot\":\"E\",\"name\":\"崩陷\",\"desc\":\"在指定区域引发震荡，打乱敌人站位。\"},{\"slot\":\"X\",\"name\":\"大地震荡\",\"desc\":\"释放大范围地震波，击飞并震荡敌人。\"}]', '/agents/tremor.png', 78, 58, 90, 46, 86, 0, 27, 1, '2026-11-26 14:15:17', '2026-11-27 14:42:43');
INSERT INTO `agent_archive` VALUES (33, 'AGENT', 'RECON', 'A', 'lynx', 'LYNX', '山猫', 'L', '#8BD450', '带着野兽穿越敌区的侦察兵，既能找人，也能把队友从崩溃边缘拉回来。', '档案解密等级：Ω。\n\n LYNX 来自大洋洲内陆，随身带着三只「搭档」。她从不对宠物下命令，只给方向——她信它们自己知道该往哪跑。\n\n 队医说她的治疗能力更像一种鼓励：被她扶起来的人，往往会觉得自己还能再打一回合。', '[{\"slot\":\"C\",\"name\":\"生息\",\"desc\":\"治疗视线内队友，治疗池有限。\"},{\"slot\":\"Q\",\"name\":\"猎虎突袭\",\"desc\":\"操控猛虎冲刺并爆炸，震荡敌人。\"},{\"slot\":\"E\",\"name\":\"引路隼\",\"desc\":\"操控飞禽，再激活致盲目击的敌人。\"},{\"slot\":\"X\",\"name\":\"寻踪灵\",\"desc\":\"派出灵体追击最近敌人并减速。\"}]', '/agents/lynx.png', 66, 78, 80, 54, 83, 0, 28, 1, '2026-11-26 14:15:17', '2026-11-27 14:44:55');
INSERT INTO `agent_archive` VALUES (34, 'AGENT', 'RECON', 'A', 'null', 'NULL', '归零', 'N', '#C0C0C0', '为压制超能力而造的战争机器，敌方技能在他的脉冲下一一沉默。', '档案解密等级：Ω。\n\n NULL 没有名字，只有一串出厂编号；他也不需要名字，因为他的任务清单上只有一条：让能力归零。\n\n 有人问他重启之后还记得什么，他回答：「我记得哪些技能不该被使用。」', '[{\"slot\":\"C\",\"name\":\"过载碎片\",\"desc\":\"投出碎片，落地爆炸并持续伤害。\"},{\"slot\":\"Q\",\"name\":\"闪存过载\",\"desc\":\"延迟引爆闪光，致盲目击者。\"},{\"slot\":\"E\",\"name\":\"压制脉冲\",\"desc\":\"触碰表面后脉冲，压制范围内敌人技能。\"},{\"slot\":\"X\",\"name\":\"零号指令\",\"desc\":\"持续压制敌人，获得强化并可重启再战。\"}]', '/agents/null.png', 76, 66, 88, 48, 85, 0, 29, 1, '2026-11-26 14:15:17', '2026-11-27 14:44:55');
INSERT INTO `agent_archive` VALUES (35, 'AGENT', 'RECON', 'A', 'dread', 'DREAD', '惧影', 'D', '#6B5B95', '操控恐惧能量的追猎者，被她盯上的目标连阴影都不再安全。', '档案解密等级：Ω。\n\n DREAD 做过十年赏金猎人，追猎记录里没有一次失手。她说人逃跑时最容易犯的错不是慢，而是回头。\n\n 她的猎犬从不咬人，只是站在你身后——足够让大多数人自己走出掩体。', '[{\"slot\":\"C\",\"name\":\"猎影犬\",\"desc\":\"追击首个敌人或轨迹，碰撞后收缩其视野。\"},{\"slot\":\"Q\",\"name\":\"缚影爪\",\"desc\":\"落地后束缚、致残并腐坏敌人。\"},{\"slot\":\"E\",\"name\":\"窥影眼\",\"desc\":\"标记并揭露范围内的敌人。\"},{\"slot\":\"X\",\"name\":\"暗夜降临\",\"desc\":\"释放能量波，标记、致残并腐坏敌人。\"}]', '/agents/dread.png', 70, 72, 86, 48, 82, 0, 30, 1, '2026-11-26 14:15:17', '2026-11-27 14:44:55');
INSERT INTO `agent_archive` VALUES (36, 'AGENT', 'RECON', 'B', 'sprout', 'SPROUT', '藤灵', 'S', '#7ED957', '带着一群调皮小怪兽冲锋的侦察兵，闹剧散场后往往只剩对手的残局。', '档案解密等级：Ω。\n\n SPROUT 的训练日志里，事故栏比战术栏长三倍：小怪兽咬坏了靶机、把烟幕当球踢、在部署区留下不明黏液。\n\n 但每次任务结算，她的助攻数都排在最前面。教官最后在评语里写：允许携带宠物，前提是它们真的在干活。', '[{\"slot\":\"C\",\"name\":\"爆藤\",\"desc\":\"部署藤蔓生物，落地后持续伤害并爆炸。\"},{\"slot\":\"Q\",\"name\":\"追风仔\",\"desc\":\"派出生物追击敌人并造成震荡。\"},{\"slot\":\"E\",\"name\":\"光刺\",\"desc\":\"向视线内敌人发射电浆致盲。\"},{\"slot\":\"X\",\"name\":\"巨鲨冲撞\",\"desc\":\"操控巨兽冲刺爆炸并束缚敌人。\"}]', '/agents/sprout.png', 72, 80, 78, 50, 78, 0, 31, 1, '2026-11-26 14:15:17', '2026-11-27 14:44:55');
INSERT INTO `agent_archive` VALUES (37, 'AGENT', 'RECON', 'S', 'ricochet', 'RICOCHET', '跳弹', 'R', '#FF7F50', '用制导弹道把敌人从舒适位置上赶走的侦察兵，角度比枪法更致命。', '档案解密等级：Ω。\n\n RICOCHET 是南美情报圈的老人，最擅长的事是让敌人「自己」离开掩体：一发弹墙、一声无人机嗡鸣、一枚精准落点的导弹。\n\n 他常挂在嘴边的一句话：位置不舒服的人，枪也会变慢。', '[{\"slot\":\"C\",\"name\":\"潜行爬虫\",\"desc\":\"操控爬虫揭露并压制附近敌人。\"},{\"slot\":\"Q\",\"name\":\"折跃弹\",\"desc\":\"发射弹跳弹，触面爆炸造成震荡与伤害。\"},{\"slot\":\"E\",\"name\":\"导引打击\",\"desc\":\"战术地图选点，导弹抵达后持续伤害。\"},{\"slot\":\"X\",\"name\":\"审判冲击\",\"desc\":\"设定方向释放大范围冲击波。\"}]', '/agents/ricochet.png', 84, 70, 86, 46, 87, 0, 32, 1, '2026-11-26 14:15:17', '2026-11-27 14:47:10');
INSERT INTO `agent_archive` VALUES (38, 'AGENT', 'SENTINEL', 'S', 'glacier', 'GLACIER', '冰垣', 'G', '#8FD8F2', '以冰墙、治疗与复活守住阵地的守护者，防线在她手里很少真正破裂。', '档案解密等级：Ω。\n\n GLACIER 曾是高原救援队的医师，在一次雪崩中靠一堵临时冰墙撑了六个小时，把整支队伍等到救援。\n\n 入队后她把这件事做成了战术：先立墙，再救人，最后把倒下的人重新拉回战线。', '[{\"slot\":\"C\",\"name\":\"冰晶壁垒\",\"desc\":\"放置墙体阻挡通行，可被打碎。\"},{\"slot\":\"Q\",\"name\":\"霜寒领域\",\"desc\":\"生成减速区域，拖慢敌人推进。\"},{\"slot\":\"E\",\"name\":\"生机之息\",\"desc\":\"治疗目标队友。\"},{\"slot\":\"X\",\"name\":\"回生\",\"desc\":\"复活一名阵亡队友。\"}]', '/agents/glacier.png', 52, 54, 76, 96, 91, 0, 33, 1, '2026-11-26 14:15:17', '2026-11-27 14:47:10');
INSERT INTO `agent_archive` VALUES (39, 'AGENT', 'SENTINEL', 'A', 'vigil', 'VIGIL', '哨卫', 'V', '#D9C27E', '用摄像头与绊线织起情报网的守护者，敌人还没进点就已经暴露。', '档案解密等级：Ω。\n\n VIGIL 卖过十年情报，从不亲自出手。他的原则是：知道得比对手多，就不必打得比对手狠。\n\n 他的摄像头布满每一个通道，连队友有时都怀疑自己是不是也被拍了。他对此的回应是：「拍到了，但没写进报告。」', '[{\"slot\":\"C\",\"name\":\"感应绊线\",\"desc\":\"隐形绊线触发后束缚敌人并揭露位置。\"},{\"slot\":\"Q\",\"name\":\"禁视牢笼\",\"desc\":\"生成阻挡视野的圆柱区域。\"},{\"slot\":\"E\",\"name\":\"暗影摄像\",\"desc\":\"部署隐形摄像头并发射定位镖。\"},{\"slot\":\"X\",\"name\":\"神经回溯\",\"desc\":\"短时间内反复揭露存活敌人位置。\"}]', '/agents/vigil.png', 68, 56, 92, 64, 86, 0, 34, 1, '2026-11-26 14:15:17', '2026-11-27 14:47:10');
INSERT INTO `agent_archive` VALUES (40, 'AGENT', 'SENTINEL', 'A', 'swarm', 'SWARM', '蜂群', 'S', '#F5D547', '把阵地变成精密机关的发明家，炮台与蜂群替她盯住每一条缝隙。', '档案解密等级：Ω。\n\n SWARM 的工坊里堆着一百二十七个失败原型，她只保留成功的那几个，剩下的全拆了重装。\n\n 她的守点方式从不靠反应：提前布好机关，然后站在后面看对手一步步走进设计图。', '[{\"slot\":\"C\",\"name\":\"纳米蜂群\",\"desc\":\"隐形蜂群触发后形成伤害区域。\"},{\"slot\":\"Q\",\"name\":\"巡弋哨兵\",\"desc\":\"自动追击首个敌人并爆炸。\"},{\"slot\":\"E\",\"name\":\"警戒炮台\",\"desc\":\"部署炮台，自动攻击视线内敌人。\"},{\"slot\":\"X\",\"name\":\"全域封锁\",\"desc\":\"延迟后束缚范围内所有敌人。\"}]', '/agents/swarm.png', 72, 52, 94, 72, 85, 0, 35, 1, '2026-11-26 14:15:17', '2026-11-27 14:47:10');
INSERT INTO `agent_archive` VALUES (41, 'AGENT', 'SENTINEL', 'A', 'anchor', 'ANCHOR', '定锚', 'A', '#D8B4A0', '以狙击与锚点转移控制长线的守护者，开枪前早已算好退路。', '档案解密等级：Ω。\n\n ANCHOR 设计过一整条狙击枪产品线，却从不给自己的枪起名。他的理由是：枪只需要准，不需要故事。\n\n 他每次架点都会先放好锚点。有人笑他谨慎，他回了一句：「能活着换位置的人，才有资格开第二枪。」', '[{\"slot\":\"C\",\"name\":\"禁行陷阱\",\"desc\":\"部署陷阱，敌人触发后减速。\"},{\"slot\":\"Q\",\"name\":\"猎头手枪\",\"desc\":\"装备高精度手枪，命中伤害极高。\"},{\"slot\":\"E\",\"name\":\"锚点跃迁\",\"desc\":\"在锚点间即时传送，灵活转移。\"},{\"slot\":\"X\",\"name\":\"孤鸿狙击\",\"desc\":\"召唤重型狙击枪，上半身命中致命。\"}]', '/agents/anchor.png', 92, 68, 50, 58, 88, 0, 36, 1, '2026-11-26 14:15:17', '2026-11-27 14:50:08');
INSERT INTO `agent_archive` VALUES (42, 'AGENT', 'SENTINEL', 'A', 'snare', 'SNARE', '缚网', 'S', '#B49CFF', '用纳米纤维监听并锁死通道的守护者，被她锁住的敌人往往走不到终点。', '档案解密等级：Ω。\n\n SNARE 在北欧极夜中做过信号监听员，习惯从最细微的声响里判断方向。现在她把这种听觉做成了纳米纤维陷阱。\n\n 她唯一的战术守则：让敌人停下，比让敌人死掉更容易控制局面。', '[{\"slot\":\"C\",\"name\":\"阻域网墙\",\"desc\":\"生成纳米纤维屏障，阻挡移动。\"},{\"slot\":\"Q\",\"name\":\"声感捕网\",\"desc\":\"敌方噪音触发后形成震荡区。\"},{\"slot\":\"E\",\"name\":\"重力束缚\",\"desc\":\"落地爆炸，迫使范围内敌人减速。\"},{\"slot\":\"X\",\"name\":\"绝命牵引\",\"desc\":\"捕获首个敌人并拖曳，未破坏则致命。\"}]', '/agents/snare.png', 66, 54, 88, 92, 84, 0, 37, 1, '2026-11-26 14:15:17', '2026-11-27 14:50:08');
INSERT INTO `agent_archive` VALUES (43, 'AGENT', 'SENTINEL', 'S', 'thorn', 'THORN', '荆棘', 'T', '#C4A484', '以液态金属布下陷阱与壁垒的守护者，擅长让进攻方在门口就失去武器。', '档案解密等级：Ω。\n\n THORN 原本是冶金工程师，研究的是「如何在不破坏结构的前提下让金属变形」。战场上她把这门学问用在了对手的武器上。\n\n 她的报告里最爱写一句：最好的防守，是让对方发现自己根本没有进攻的装备。', '[{\"slot\":\"C\",\"name\":\"荆蔓陷阱\",\"desc\":\"隐形藤蔓触发后形成伤害与减速区。\"},{\"slot\":\"Q\",\"name\":\"金属壁垒\",\"desc\":\"生成不可破坏的临时墙体。\"},{\"slot\":\"E\",\"name\":\"弧光飞刃\",\"desc\":\"可穿墙部署，再激活致盲目击者。\"},{\"slot\":\"X\",\"name\":\"缴械囚笼\",\"desc\":\"延迟后封锁范围内敌人的主武器。\"}]', '/agents/thorn.png', 70, 58, 90, 88, 86, 0, 38, 1, '2026-11-26 14:15:17', '2026-11-27 14:50:08');
INSERT INTO `agent_archive` VALUES (44, 'AGENT', 'SENTINEL', 'S', 'warden', 'WARDEN', '守御', 'W', '#9B7EDE', '压制敌方装置的进化型守护者，靠异常体质把科技优势一一抹平。', '档案解密等级：Ω。\n\n WARDEN 的基因报告有十七处「无法解释的变异」，体检医生建议他远离一切危险。他反而把这当成入职理由：既然科技对他无效，那就让科技站在对面。\n\n 他的作战风格近乎固执——不吃控制，不吃压制，一步一步把阵地站回来。', '[{\"slot\":\"C\",\"name\":\"淤流折跃\",\"desc\":\"部署折跃点，在范围内快速传送。\"},{\"slot\":\"Q\",\"name\":\"腐化碎片\",\"desc\":\"隐形碎片触发后束缚并腐坏敌人。\"},{\"slot\":\"E\",\"name\":\"吞噬领域\",\"desc\":\"摧毁视线或范围内的敌方装置。\"},{\"slot\":\"X\",\"name\":\"完全进化\",\"desc\":\"获得强化与持续治疗，免疫非武器伤害。\"}]', '/agents/warden.png', 74, 62, 84, 94, 89, 0, 39, 1, '2026-11-26 14:15:17', '2026-11-27 14:50:08');
INSERT INTO `agent_archive` VALUES (45, 'GEAR', 'SIDEARM', 'B', 'shorty', 'SHORTY', '短炮', 'S', '#FF8C69', '超低价双管霰弹手枪，贴脸两发就能终结，经济局偷点的常客。', '短炮从不在中距离讲道理。老兵的说法：揣着它拐进窄巷，你需要的只是勇气和两步路。', '[{\"slot\":\"优势\",\"name\":\"贴脸双发\",\"desc\":\"近距离两发即可终结，转角遭遇战反应极快。\"},{\"slot\":\"优势\",\"name\":\"价格极低\",\"desc\":\"300 信用点就能入手，经济局也能搏一把。\"},{\"slot\":\"代价\",\"name\":\"射程极短\",\"desc\":\"稍微拉开距离伤害骤降，弹匣只有两发。\"}]', '', 70, 80, 40, 25, 72, 0, 28, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (46, 'GEAR', 'SIDEARM', 'B', 'frenzy', 'FRENZY', '狂怒', 'F', '#FF6B4A', '全自动手枪，近距离倾泻弹药，强起局的暴力答案。', '狂怒的手感像把微型冲锋枪塞进枪套。它不追求精准，只追求在你扣下扳机的瞬间压满对面。', '[{\"slot\":\"优势\",\"name\":\"全自动泼洒\",\"desc\":\"近距离全自动倾泻弹药，先手压制力极强。\"},{\"slot\":\"优势\",\"name\":\"机动灵活\",\"desc\":\"轻便便宜，边跑边打也能保持节奏。\"},{\"slot\":\"代价\",\"name\":\"散布难控\",\"desc\":\"连射后坐明显，中距离几乎打不中。\"}]', '', 68, 84, 45, 25, 76, 0, 29, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (47, 'GEAR', 'SIDEARM', 'A', 'ghost', 'GHOST', '鬼魅', 'G', '#B0BEC5', '消音手枪，爆头即可致命，暗处绕后的首选。', '鬼魅开火时没有枪声标记，敌人往往直到倒下才知道自己被谁盯上。', '[{\"slot\":\"优势\",\"name\":\"自带消音\",\"desc\":\"开火不暴露位置提示，适合绕后偷袭。\"},{\"slot\":\"优势\",\"name\":\"爆头致命\",\"desc\":\"近距离一发爆头即可带走无甲目标。\"},{\"slot\":\"代价\",\"name\":\"身体伤害低\",\"desc\":\"打身子需要多发，容错一般。\"}]', '', 72, 78, 55, 28, 84, 0, 30, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (48, 'GEAR', 'SIDEARM', 'A', 'bandit', 'BANDIT', '追猎', 'B', '#FFB443', '中价位精准手枪，半自动点射回报极高，适合枪法自信的玩家。', '追猎填补了鬼魅与正义之间的空档：花更少的钱，打出接近左轮的爆头收益。', '[{\"slot\":\"优势\",\"name\":\"精准爆头\",\"desc\":\"爆头伤害极高，中距离点射回报丰厚。\"},{\"slot\":\"优势\",\"name\":\"价格适中\",\"desc\":\"600 信用点即可拥有接近正义的爆头收益。\"},{\"slot\":\"代价\",\"name\":\"弹匣偏小\",\"desc\":\"8 发弹容，空枪就是致命失误。\"}]', '', 80, 74, 60, 30, 80, 0, 31, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (49, 'GEAR', 'SMG', 'B', 'stinger', 'STINGER', '蜂刺', 'T', '#00E0C6', '超高射速冲锋枪，近距离压制力惊人，强起局的尖刀。', '蜂刺的价值全在头三秒：贴脸倾泻的弹雨足以让任何没有防备的对手闭嘴。', '[{\"slot\":\"优势\",\"name\":\"极限射速\",\"desc\":\"近距离倾泻弹雨，先手几乎无法反打。\"},{\"slot\":\"优势\",\"name\":\"灵活机动\",\"desc\":\"轻便适合快速突进与补枪。\"},{\"slot\":\"代价\",\"name\":\"远距衰减\",\"desc\":\"散布大、伤害掉得快，中远距乏力。\"}]', '', 72, 86, 42, 26, 82, 0, 32, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (50, 'GEAR', 'SMG', 'A', 'spectre-smg', 'SPECTRE', '骇灵', 'P', '#4DA6FF', '消音冲锋枪，机动与稳定兼备，半买回合的主力选择。', '骇灵把消音与冲锋枪的手感揉在一起，既能在半买局冲锋，也能安静地摸掉信息点。', '[{\"slot\":\"优势\",\"name\":\"消音机动\",\"desc\":\"开火不暴露位置，偷点与绕后两相宜。\"},{\"slot\":\"优势\",\"name\":\"稳定连发\",\"desc\":\"后坐柔和，中近距离压枪手感顺。\"},{\"slot\":\"代价\",\"name\":\"伤害有限\",\"desc\":\"面对重甲目标需要更多子弹。\"}]', '', 76, 80, 52, 30, 88, 0, 33, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (51, 'GEAR', 'SHOTGUN', 'B', 'bucky', 'BUCKY', '雄鹿', 'K', '#FFA07A', '半自动霰弹枪，近距离一发覆盖大范围，守点的暴力工具。', '雄鹿是门后的守卫。它不需要准星，只需要敌人愿意推门进来。', '[{\"slot\":\"优势\",\"name\":\"宽幅弹幕\",\"desc\":\"一发多弹丸覆盖，贴脸几乎必杀。\"},{\"slot\":\"优势\",\"name\":\"守点极强\",\"desc\":\"半买回合守通道的性价比之王。\"},{\"slot\":\"代价\",\"name\":\"射程有限\",\"desc\":\"稍微拉开就形同虚设，射速偏慢。\"}]', '', 85, 55, 40, 42, 78, 0, 34, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (52, 'GEAR', 'SHOTGUN', 'A', 'judge', 'JUDGE', '判官', 'J', '#FF4655', '全自动霰弹枪，连续弹幕封锁狭窄通道，近战绞肉机。', '判官一旦在窄道开火，那条路就不再属于进攻方。它的判决从不拖延。', '[{\"slot\":\"优势\",\"name\":\"全自动弹幕\",\"desc\":\"连续霰弹倾泻，通道封锁几乎无解。\"},{\"slot\":\"优势\",\"name\":\"贴脸统治\",\"desc\":\"近距离伤害堆叠极高。\"},{\"slot\":\"代价\",\"name\":\"笨重昂贵\",\"desc\":\"价格高、机动差，远距完全无力。\"}]', '', 92, 48, 46, 46, 86, 0, 35, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (53, 'GEAR', 'RIFLE', 'A', 'bulldog', 'BULLDOG', '獠犬', 'D', '#3DDC97', '全自动步枪，射速与伤害均衡，中近距离的可靠主力。', '獠犬是步枪里的万金油：不追求极致，却在每一段距离都能给出稳定的答案。', '[{\"slot\":\"优势\",\"name\":\"全自动稳定\",\"desc\":\"全自动模式下弹道可控，中距离压制稳。\"},{\"slot\":\"优势\",\"name\":\"伤害不俗\",\"desc\":\"身体伤害高于多数步枪，容错好。\"},{\"slot\":\"代价\",\"name\":\"远距衰减\",\"desc\":\"距离一拉伤害明显下降。\"}]', '', 80, 68, 54, 36, 82, 0, 36, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (54, 'GEAR', 'RIFLE', 'S', 'warden-rifle', 'WARDEN', '捍卫者', 'W', '#A66CFF', '高精度半自动步枪，一枪爆头，远距离架点的终极威慑。', '捍卫者站在长线的尽头。它不连发，也不追赶——它只需要你露出一次头。', '[{\"slot\":\"优势\",\"name\":\"一枪爆头\",\"desc\":\"半自动高精度，爆头无视距离直接致命。\"},{\"slot\":\"优势\",\"name\":\"穿透力强\",\"desc\":\"子弹穿墙能力出色，可穿掩体验证。\"},{\"slot\":\"代价\",\"name\":\"射速缓慢\",\"desc\":\"必须精确瞄准，连射节奏慢。\"}]', '', 92, 52, 66, 42, 90, 0, 37, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (55, 'GEAR', 'SNIPER', 'A', 'outlaw', 'OUTLAW', '亡命徒', 'O', '#FF7F50', '双发栓动狙击枪，性价比极高的中远距离终结者。', '亡命徒只带两发子弹，因为它相信真正的枪手从不需要第三枪。', '[{\"slot\":\"优势\",\"name\":\"躯干致命\",\"desc\":\"上半身一枪带走，价格远低于冥狙。\"},{\"slot\":\"优势\",\"name\":\"双发连射\",\"desc\":\"两发弹匣允许快速补枪。\"},{\"slot\":\"代价\",\"name\":\"容错极低\",\"desc\":\"打腿杀不掉，空枪代价巨大。\"}]', '', 90, 56, 50, 38, 84, 0, 38, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (56, 'GEAR', 'MACHINE', 'S', 'odin-mg', 'ODIN', '奥丁', 'D', '#00E0C6', '重型机枪，穿墙弹链压制，一个人就能封死整条走廊。', '奥丁开火时，掩体只是装饰。士兵们说，听见它的低吼就该换一条路。', '[{\"slot\":\"优势\",\"name\":\"弹链压制\",\"desc\":\"超大弹容持续输出，一人封锁一条通道。\"},{\"slot\":\"优势\",\"name\":\"穿墙射击\",\"desc\":\"子弹能打穿墙体，隔着掩体压制。\"},{\"slot\":\"代价\",\"name\":\"又重又慢\",\"desc\":\"移速与开镜都慢，被绕后基本没救。\"}]', '', 96, 24, 60, 52, 92, 0, 39, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');
INSERT INTO `agent_archive` VALUES (57, 'GEAR', 'MELEE', 'B', 'knife', 'KNIFE', '战刃', 'N', '#ECECEC', '标配近战战刃，轻盈快捷，特殊情况下的唯一答案。', '战刃是每个人出生就带着的武器。它从不出现在购买界面，却总在弹尽时决定结局。', '[{\"slot\":\"优势\",\"name\":\"永久免费\",\"desc\":\"人手一把，永不掉落。\"},{\"slot\":\"优势\",\"name\":\"出手极快\",\"desc\":\"轻击背刺一击致命，机动无负担。\"},{\"slot\":\"代价\",\"name\":\"仅限贴身\",\"desc\":\"必须贴到脸上才能发挥作用。\"}]', '', 30, 90, 20, 15, 70, 0, 40, 1, '2026-11-27 14:02:30', '2026-11-27 14:02:30');

-- ----------------------------
-- Table structure for agent_friend
-- ----------------------------
DROP TABLE IF EXISTS `agent_friend`;
CREATE TABLE `agent_friend`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '发起方 agent_user.id',
  `user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '发起方代号（冗余展示）',
  `friend_id` bigint NOT NULL COMMENT '对方 agent_user.id',
  `friend_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '对方案号（冗余展示）',
  `status` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING 待同意 / ACCEPTED 已是好友',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发起时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '处理时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_pair`(`user_id` ASC, `friend_id` ASC) USING BTREE,
  INDEX `idx_friend`(`friend_id` ASC, `status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '好友关系表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of agent_friend
-- ----------------------------
INSERT INTO `agent_friend` VALUES (6, 1, '爱打球的T', 9, 'gay', 'PENDING', '2026-11-05 21:25:16', '2026-11-05 21:25:16');

-- ----------------------------
-- Table structure for agent_oauth
-- ----------------------------
DROP TABLE IF EXISTS `agent_oauth`;
CREATE TABLE `agent_oauth`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `provider` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'RIOT' COMMENT '第三方来源',
  `provider_uid` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '第三方的唯一用户 id',
  `riot_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '展示用的 Riot ID，如 JETT#CN1',
  `user_id` bigint NULL DEFAULT NULL COMMENT '绑定的 agent_user.id，NULL 表示未绑定',
  `ticket` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '一次性授权票据',
  `ticket_expires_at` datetime NULL DEFAULT NULL COMMENT '票据过期时间（10 分钟）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_provider_uid`(`provider` ASC, `provider_uid` ASC) USING BTREE,
  UNIQUE INDEX `uk_ticket`(`ticket` ASC) USING BTREE,
  INDEX `idx_user`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '第三方账号绑定与授权票据' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of agent_oauth
-- ----------------------------

-- ----------------------------
-- Table structure for agent_pk
-- ----------------------------
DROP TABLE IF EXISTS `agent_pk`;
CREATE TABLE `agent_pk`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `challenger_id` bigint NOT NULL COMMENT '挑战方',
  `challenger_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '',
  `defender_id` bigint NOT NULL COMMENT '应战方',
  `defender_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '',
  `challenger_power` int NOT NULL DEFAULT 0 COMMENT '挑战方战力',
  `defender_power` int NOT NULL DEFAULT 0 COMMENT '应战方战力',
  `winner_id` bigint NULL DEFAULT NULL COMMENT '胜者 id',
  `detail` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '结算描述',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_challenger`(`challenger_id` ASC) USING BTREE,
  INDEX `idx_defender`(`defender_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 44 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'PK 战绩表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of agent_pk
-- ----------------------------
INSERT INTO `agent_pk` VALUES (13, 1, '爱打球的T', 9, 'gay', 424, 250, 1, '挑战方胜', '2026-11-05 21:54:17');
INSERT INTO `agent_pk` VALUES (14, 1, '爱打球的T', 9, 'gay', 449, 256, 1, '挑战方胜', '2026-11-05 21:54:22');
INSERT INTO `agent_pk` VALUES (15, 1, '爱打球的T', 9, 'gay', 423, 259, 1, '挑战方胜', '2026-11-05 21:54:24');
INSERT INTO `agent_pk` VALUES (16, 1, '爱打球的T', 26, '123', 464, 302, 1, '挑战方胜', '2026-11-06 08:44:06');
INSERT INTO `agent_pk` VALUES (17, 1, '爱打球的T', 26, '123', 423, 278, 1, '挑战方胜', '2026-11-06 08:44:12');
INSERT INTO `agent_pk` VALUES (18, 28, '星落大帝', 1, '爱打球的T', 309, 401, 1, '应战方胜', '2026-11-06 09:04:06');
INSERT INTO `agent_pk` VALUES (19, 28, '星落大帝', 26, '123', 267, 264, 28, '挑战方胜', '2026-11-06 09:04:09');
INSERT INTO `agent_pk` VALUES (20, 28, '星落大帝', 26, '123', 282, 318, 26, '应战方胜', '2026-11-06 09:04:13');
INSERT INTO `agent_pk` VALUES (21, 28, '星落大帝', 26, '123', 289, 262, 28, '挑战方胜', '2026-11-06 09:04:18');
INSERT INTO `agent_pk` VALUES (22, 28, '星落大帝', 9, 'gay', 309, 270, 28, '挑战方胜', '2026-11-06 09:26:42');
INSERT INTO `agent_pk` VALUES (23, 29, 'ww', 1, '爱打球的T', 269, 425, 1, '应战方胜', '2026-11-16 08:45:31');
INSERT INTO `agent_pk` VALUES (24, 29, 'ww', 1, '爱打球的T', 271, 415, 1, '应战方胜', '2026-11-16 08:45:35');
INSERT INTO `agent_pk` VALUES (25, 29, 'ww', 1, '爱打球的T', 295, 391, 1, '应战方胜', '2026-11-16 08:45:38');
INSERT INTO `agent_pk` VALUES (26, 29, 'ww', 28, '星落大帝', 256, 345, 28, '应战方胜', '2026-11-16 08:45:46');
INSERT INTO `agent_pk` VALUES (27, 34, 'xxx', 30, '罗磊', 288, 287, 34, '挑战方胜', '2026-11-16 08:56:28');
INSERT INTO `agent_pk` VALUES (28, 36, '康神', 37, '哥哥的美腿永远比妹妹的腰香', 280, 291, 37, '应战方胜', '2026-11-16 09:44:42');
INSERT INTO `agent_pk` VALUES (29, 36, '康神', 26, '123', 280, 310, 26, '应战方胜', '2026-11-16 09:45:08');
INSERT INTO `agent_pk` VALUES (30, 36, '康神', 33, '小何', 293, 281, 36, '挑战方胜', '2026-11-16 09:45:17');
INSERT INTO `agent_pk` VALUES (31, 36, '康神', 33, '小何', 305, 280, 36, '挑战方胜', '2026-11-16 09:45:20');
INSERT INTO `agent_pk` VALUES (32, 36, '康神', 33, '小何', 323, 297, 36, '挑战方胜', '2026-11-16 09:45:22');
INSERT INTO `agent_pk` VALUES (33, 36, '康神', 9, 'gay', 301, 297, 36, '挑战方胜', '2026-11-16 09:45:25');
INSERT INTO `agent_pk` VALUES (34, 36, '康神', 9, 'gay', 288, 273, 36, '挑战方胜', '2026-11-16 09:45:27');
INSERT INTO `agent_pk` VALUES (35, 36, '康神', 9, 'gay', 274, 277, 9, '应战方胜', '2026-11-16 09:45:29');
INSERT INTO `agent_pk` VALUES (36, 36, '康神', 1, '爱打球的T', 275, 396, 1, '应战方胜', '2026-11-16 09:45:33');
INSERT INTO `agent_pk` VALUES (37, 36, '康神', 28, '星落大帝', 322, 303, 36, '挑战方胜', '2026-11-16 09:45:37');
INSERT INTO `agent_pk` VALUES (38, 36, '康神', 28, '星落大帝', 299, 321, 28, '应战方胜', '2026-11-16 09:45:41');
INSERT INTO `agent_pk` VALUES (39, 36, '康神', 28, '星落大帝', 308, 330, 28, '应战方胜', '2026-11-16 09:45:42');
INSERT INTO `agent_pk` VALUES (40, 36, '康神', 37, '哥哥的美腿永远比妹妹的腰香', 300, 320, 37, '应战方胜', '2026-11-16 09:45:46');
INSERT INTO `agent_pk` VALUES (41, 36, '康神', 37, '哥哥的美腿永远比妹妹的腰香', 327, 271, 36, '挑战方胜', '2026-11-16 09:45:48');
INSERT INTO `agent_pk` VALUES (42, 36, '康神', 26, '123', 302, 271, 36, '挑战方胜', '2026-11-16 09:45:59');
INSERT INTO `agent_pk` VALUES (43, 36, '康神', 26, '123', 307, 305, 36, '挑战方胜', '2026-11-16 09:46:01');

-- ----------------------------
-- Table structure for agent_reset_code
-- ----------------------------
DROP TABLE IF EXISTS `agent_reset_code`;
CREATE TABLE `agent_reset_code`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '接收验证码的邮箱',
  `code` varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '6 位验证码',
  `expires_at` datetime NOT NULL COMMENT '过期时间（10 分钟）',
  `used` tinyint NOT NULL DEFAULT 0 COMMENT '是否已使用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_email_code`(`email` ASC, `code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '找回密码验证码' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of agent_reset_code
-- ----------------------------
INSERT INTO `agent_reset_code` VALUES (1, '1573473522@qq.com', '829840', '2026-11-16 09:08:08', 1, '2026-11-16 08:58:08');
INSERT INTO `agent_reset_code` VALUES (2, '1573473522@qq.com', '806585', '2026-11-26 14:09:46', 1, '2026-11-26 13:59:46');

-- ----------------------------
-- Table structure for agent_session
-- ----------------------------
DROP TABLE IF EXISTS `agent_session`;
CREATE TABLE `agent_session`  (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `token` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '会话令牌',
  `user_id` bigint NOT NULL COMMENT '关联 agent_user.id',
  `expires_at` datetime NOT NULL COMMENT '过期时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_token`(`token` ASC) USING BTREE,
  INDEX `idx_user`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 115 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '登录会话表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of agent_session
-- ----------------------------
INSERT INTO `agent_session` VALUES (109, 'f5cb7a8ce9e34e3db1b4fe6e19f74cd9', 33, '2026-12-03 14:00:04', '2026-11-26 14:00:04');
INSERT INTO `agent_session` VALUES (110, 'e73d98b739a64405950aa3e2909e8b99', 33, '2026-12-03 14:17:42', '2026-11-26 14:17:42');
INSERT INTO `agent_session` VALUES (111, '194a39f3bab245a69e20a3f2b26a3903', 33, '2026-12-04 13:54:48', '2026-11-27 13:54:48');
INSERT INTO `agent_session` VALUES (112, '7eb456a37924496c9faa94ba35854b5d', 33, '2026-12-04 13:57:50', '2026-11-27 13:57:49');
INSERT INTO `agent_session` VALUES (113, 'd1d47679487745a9ba1575eebf9e36e9', 33, '2026-12-04 14:36:11', '2026-11-27 14:36:11');
INSERT INTO `agent_session` VALUES (114, '751214aa29104416a5c1963e7732b7ba', 33, '2026-12-04 14:52:25', '2026-11-27 14:52:24');

-- ----------------------------
-- Table structure for agent_user
-- ----------------------------
DROP TABLE IF EXISTS `agent_user`;
CREATE TABLE `agent_user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '特工代号',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '邮箱',
  `password` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '登录密码（明文，不做加密）',
  `password_hash` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '（已废弃）旧版密码摘要',
  `salt` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '（已废弃）旧版随机盐',
  `agent_index` int NOT NULL DEFAULT 0 COMMENT '注册时选择的特工下标',
  `hero_level` int NOT NULL DEFAULT 1 COMMENT '英雄等级（由 exp 推导，无上限）',
  `credits` int NOT NULL DEFAULT 800 COMMENT '信用点余额（购买武器消耗）',
  `exp` int NOT NULL DEFAULT 0 COMMENT '累计经验值（决定英雄等级，无上限）',
  `equipped_weapon` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'classic' COMMENT '当前主武器 code（影响战力）',
  `equipped_frame` int NOT NULL DEFAULT 0 COMMENT '当前佩戴头像框档位（0=跟随最新解锁）',
  `pk_win` int NOT NULL DEFAULT 0 COMMENT 'PK 胜场',
  `pk_lose` int NOT NULL DEFAULT 0 COMMENT 'PK 负场',
  `last_login_date` date NULL DEFAULT NULL COMMENT '最近一次登录日期（每日登录经验去重）',
  `permission` tinyint NOT NULL DEFAULT 1 COMMENT '权限：1 默认权限，0 管理员权限',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_email`(`email` ASC) USING BTREE,
  UNIQUE INDEX `uk_name`(`name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 38 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '特工账号表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of agent_user
-- ----------------------------
INSERT INTO `agent_user` VALUES (1, '爱打球的T', '264132801@qq.com', NULL, '3cb9bb890b91efdd310c935089eb3935b82ce46640a4b68bb0c5a2b72d28d2b5', '9e1431e9dbdaa424328eda90965d4ea6', 0, 20, 3805, 11300, 'operator', 7, 10, 0, '2026-11-16', 0, '2026-10-28 16:36:07', '2026-11-16 09:45:33');
INSERT INTO `agent_user` VALUES (9, 'gay', '3376460573@qq.com', 'tmz258412', NULL, NULL, 0, 1, 800, 20, 'classic', 0, 1, 6, '2026-11-05', 1, '2026-10-29 15:04:01', '2026-11-16 09:45:29');
INSERT INTO `agent_user` VALUES (26, '123', '2099336743@qq.com', '123456', NULL, NULL, 4, 1, 36, 38, 'classic', 0, 2, 6, '2026-11-05', 1, '2026-11-05 22:55:03', '2026-11-16 09:46:01');
INSERT INTO `agent_user` VALUES (28, '星落大帝', 'czh101481@qq.com', '10140801czh', NULL, NULL, 2, 7, 1668, 1381, 'marshal', 1, 6, 3, '2026-11-06', 0, '2026-11-06 08:59:45', '2026-11-16 09:45:41');
INSERT INTO `agent_user` VALUES (29, 'ww', 'ww@qq.com', '123456', NULL, NULL, 5, 1, 96, 88, 'classic', 1, 0, 4, '2026-11-16', 1, '2026-11-16 08:43:19', '2026-11-16 08:45:54');
INSERT INTO `agent_user` VALUES (30, '罗磊', '3260423989@qq.com', '123456', NULL, NULL, 4, 2, 1232, 135, 'classic', 0, 0, 1, '2026-11-16', 1, '2026-11-16 08:45:53', '2026-11-16 08:56:28');
INSERT INTO `agent_user` VALUES (31, 'ljljll', '2510754590@qq.com', '123456', NULL, NULL, 2, 1, 162, 99, 'classic', 0, 0, 0, '2026-11-16', 1, '2026-11-16 08:47:17', '2026-11-16 08:50:34');
INSERT INTO `agent_user` VALUES (32, 'xx', 'ss@163.com', '123123', NULL, NULL, 0, 1, 800, 0, 'classic', 0, 0, 0, NULL, 1, '2026-11-16 08:54:35', '2026-11-16 08:54:35');
INSERT INTO `agent_user` VALUES (33, '小何', '1573473522@qq.com', '200776', '', '', 0, 1, 800, 60, 'classic', 0, 0, 3, '2026-11-27', 0, '2026-11-16 08:55:10', '2026-11-27 13:54:48');
INSERT INTO `agent_user` VALUES (34, 'xxx', 'xxx@163.com', '123123', NULL, NULL, 0, 1, 60, 40, 'classic', 0, 1, 0, '2026-11-16', 1, '2026-11-16 08:55:18', '2026-11-16 08:56:28');
INSERT INTO `agent_user` VALUES (35, '5456', '1@qq.com', '123456', NULL, NULL, 0, 1, 800, 0, 'classic', 0, 0, 0, NULL, 1, '2026-11-16 09:00:36', '2026-11-16 09:00:36');
INSERT INTO `agent_user` VALUES (36, '康神', '123@qq.com', '123456', NULL, NULL, 0, 6, 527, 1077, 'classic', 0, 9, 7, '2026-11-16', 1, '2026-11-16 09:31:11', '2026-11-16 09:46:39');
INSERT INTO `agent_user` VALUES (37, '哥哥的美腿永远比妹妹的腰香', '123456@qq.com', '123456', NULL, NULL, 5, 3, 1550, 320, 'classic', 0, 2, 1, '2026-11-16', 1, '2026-11-16 09:41:24', '2026-11-16 09:45:48');

-- ----------------------------
-- Table structure for agent_weapon
-- ----------------------------
DROP TABLE IF EXISTS `agent_weapon`;
CREATE TABLE `agent_weapon`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '涓婚敭',
  `user_id` bigint NOT NULL COMMENT '鍏宠仈 agent_user.id',
  `user_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '特工代号（冗余，便于直查）',
  `weapon_code` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '姝﹀櫒浠ｅ彿锛歝lassic/sheriff/marshal/odin/guardian/phantom/vandal/operator',
  `weapon_name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '武器中文名（冗余，便于直查）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '璐?拱鏃堕棿',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_weapon`(`user_id` ASC, `weapon_code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 53 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '鐗瑰伐宸茶喘姝﹀櫒琛' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of agent_weapon
-- ----------------------------
INSERT INTO `agent_weapon` VALUES (4, 1, '爱打球的T', 'classic', '标配', '2026-11-05 18:46:50');
INSERT INTO `agent_weapon` VALUES (5, 1, '爱打球的T', 'operator', '冥狙', '2026-11-05 19:01:52');
INSERT INTO `agent_weapon` VALUES (6, 1, '爱打球的T', 'guardian', '戍卫', '2026-11-05 19:01:53');
INSERT INTO `agent_weapon` VALUES (7, 1, '爱打球的T', 'marshal', '鸟狙', '2026-11-05 19:01:54');
INSERT INTO `agent_weapon` VALUES (8, 1, '爱打球的T', 'odin', '战神', '2026-11-05 19:01:55');
INSERT INTO `agent_weapon` VALUES (9, 1, '爱打球的T', 'vandal', '狂徒', '2026-11-05 19:01:56');
INSERT INTO `agent_weapon` VALUES (10, 1, '爱打球的T', 'sheriff', '正义', '2026-11-05 19:01:57');
INSERT INTO `agent_weapon` VALUES (11, 1, '爱打球的T', 'phantom', '幻影', '2026-11-05 19:01:58');
INSERT INTO `agent_weapon` VALUES (29, 23, 'FRAMETEST', 'classic', '标配', '2026-11-05 21:17:31');
INSERT INTO `agent_weapon` VALUES (30, 24, 'PKA86292', 'classic', '标配', '2026-11-05 21:44:52');
INSERT INTO `agent_weapon` VALUES (31, 25, 'PKB86292', 'classic', '标配', '2026-11-05 21:44:52');
INSERT INTO `agent_weapon` VALUES (32, 26, '123', 'classic', '标配', '2026-11-05 22:55:03');
INSERT INTO `agent_weapon` VALUES (33, 26, '123', 'sheriff', '正义', '2026-11-05 22:56:03');
INSERT INTO `agent_weapon` VALUES (35, 28, '星落大帝', 'classic', '标配', '2026-11-06 08:59:45');
INSERT INTO `agent_weapon` VALUES (36, 28, '星落大帝', 'marshal', '鸟狙', '2026-11-06 09:03:38');
INSERT INTO `agent_weapon` VALUES (37, 28, '星落大帝', 'odin', '战神', '2026-11-06 09:29:08');
INSERT INTO `agent_weapon` VALUES (38, 29, 'ww', 'classic', '标配', '2026-11-16 08:43:19');
INSERT INTO `agent_weapon` VALUES (39, 29, 'ww', 'sheriff', '正义', '2026-11-16 08:44:33');
INSERT INTO `agent_weapon` VALUES (40, 30, '罗磊', 'classic', '标配', '2026-11-16 08:45:53');
INSERT INTO `agent_weapon` VALUES (41, 31, 'ljljll', 'classic', '标配', '2026-11-16 08:47:18');
INSERT INTO `agent_weapon` VALUES (42, 31, 'ljljll', 'sheriff', '正义', '2026-11-16 08:48:04');
INSERT INTO `agent_weapon` VALUES (43, 32, 'xx', 'classic', '标配', '2026-11-16 08:54:35');
INSERT INTO `agent_weapon` VALUES (44, 33, '小何', 'classic', '标配', '2026-11-16 08:55:10');
INSERT INTO `agent_weapon` VALUES (45, 34, 'xxx', 'classic', '标配', '2026-11-16 08:55:18');
INSERT INTO `agent_weapon` VALUES (46, 34, 'xxx', 'sheriff', '正义', '2026-11-16 08:56:05');
INSERT INTO `agent_weapon` VALUES (47, 35, '5456', 'classic', '标配', '2026-11-16 09:00:36');
INSERT INTO `agent_weapon` VALUES (48, 36, '康神', 'classic', '标配', '2026-11-16 09:31:11');
INSERT INTO `agent_weapon` VALUES (49, 36, '康神', 'sheriff', '正义', '2026-11-16 09:34:58');
INSERT INTO `agent_weapon` VALUES (50, 36, '康神', 'marshal', '鸟狙', '2026-11-16 09:35:21');
INSERT INTO `agent_weapon` VALUES (51, 37, '哥哥的美腿永远比妹妹的腰香', 'classic', '标配', '2026-11-16 09:41:24');
INSERT INTO `agent_weapon` VALUES (52, 36, '康神', 'guardian', '戍卫', '2026-11-16 09:46:39');

-- ----------------------------
-- Table structure for archive_category
-- ----------------------------
DROP TABLE IF EXISTS `archive_category`;
CREATE TABLE `archive_category`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `parent_id` bigint NOT NULL DEFAULT 0 COMMENT '父分类 id，0 表示一级分类',
  `code` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '分类编码，如 AGENT / ASSAULT',
  `name` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '分类中文名，如 特工档案',
  `name_en` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '分类英文名，如 AGENT ARCHIVE',
  `level` tinyint NOT NULL DEFAULT 1 COMMENT '层级：1 一级分类，2 二级分类',
  `sort` int NOT NULL DEFAULT 0 COMMENT '排序，越小越靠前',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1 启用，0 停用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_code`(`code` ASC) USING BTREE,
  INDEX `idx_parent`(`parent_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 34 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '档案分级分类目录' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of archive_category
-- ----------------------------
INSERT INTO `archive_category` VALUES (1, 0, 'AGENT', '特工档案', 'AGENT ARCHIVE', 1, 10, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (2, 0, 'GEAR', '装备库', 'ARSENAL', 1, 20, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (3, 0, 'MISSION', '作战任务', 'OPERATIONS', 1, 30, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (11, 1, 'ASSAULT', '突击', 'ASSAULT', 2, 11, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (12, 1, 'CONTROL', '控场', 'CONTROL', 2, 12, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (13, 1, 'RECON', '侦察', 'RECON', 2, 13, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (14, 1, 'SENTINEL', '守护', 'SENTINEL', 2, 14, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (21, 2, 'RIFLE', '步枪', 'RIFLE', 2, 21, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (22, 2, 'SMG', '冲锋枪', 'SMG', 2, 22, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (23, 2, 'SNIPER', '狙击枪', 'SNIPER', 2, 23, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (24, 2, 'SIDEARM', '手枪', 'SIDEARM', 2, 24, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (25, 2, 'SHOTGUN', '霰弹枪', 'SHOTGUN', 2, 25, 1, '2026-11-27 14:02:30');
INSERT INTO `archive_category` VALUES (26, 2, 'MACHINE', '机枪', 'MACHINE GUN', 2, 26, 1, '2026-11-27 14:02:30');
INSERT INTO `archive_category` VALUES (27, 2, 'MELEE', '近战', 'MELEE', 2, 27, 1, '2026-11-27 14:02:30');
INSERT INTO `archive_category` VALUES (31, 3, 'TRAINING', '训练场', 'TRAINING', 2, 31, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (32, 3, 'RANKED', '竞技模式', 'RANKED', 2, 32, 1, '2026-10-28 16:35:52');
INSERT INTO `archive_category` VALUES (33, 3, 'EVENT', '限时行动', 'EVENT', 2, 33, 1, '2026-10-28 16:35:52');

-- ----------------------------
-- Table structure for feed_mark
-- ----------------------------
DROP TABLE IF EXISTS `feed_mark`;
CREATE TABLE `feed_mark`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '关联 agent_user.id',
  `feed_id` bigint NOT NULL COMMENT '关联 home_feed.id',
  `is_read` tinyint NOT NULL DEFAULT 0 COMMENT '是否已读',
  `starred` tinyint NOT NULL DEFAULT 0 COMMENT '是否收藏',
  `liked` tinyint NOT NULL DEFAULT 0 COMMENT '是否点赞',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_feed`(`user_id` ASC, `feed_id` ASC) USING BTREE,
  INDEX `idx_user`(`user_id` ASC) USING BTREE,
  INDEX `idx_feed`(`feed_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 22 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '特工情报交互（已读/收藏/点赞）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of feed_mark
-- ----------------------------
INSERT INTO `feed_mark` VALUES (1, 1, 1, 1, 0, 0, '2026-11-02 08:45:07');
INSERT INTO `feed_mark` VALUES (2, 1, 2, 1, 0, 0, '2026-11-02 08:45:15');
INSERT INTO `feed_mark` VALUES (3, 1, 3, 1, 0, 1, '2026-11-02 08:56:41');
INSERT INTO `feed_mark` VALUES (4, 1, 7, 1, 0, 0, '2026-11-05 15:06:38');
INSERT INTO `feed_mark` VALUES (5, 1, 4, 1, 0, 1, '2026-11-05 21:57:07');
INSERT INTO `feed_mark` VALUES (6, 1, 5, 1, 1, 1, '2026-11-05 21:57:19');
INSERT INTO `feed_mark` VALUES (7, 28, 1, 1, 0, 1, '2026-11-06 09:02:35');
INSERT INTO `feed_mark` VALUES (8, 28, 2, 1, 0, 0, '2026-11-06 09:02:46');
INSERT INTO `feed_mark` VALUES (9, 28, 3, 1, 0, 0, '2026-11-06 09:02:48');
INSERT INTO `feed_mark` VALUES (10, 28, 4, 1, 0, 0, '2026-11-06 09:02:49');
INSERT INTO `feed_mark` VALUES (11, 28, 5, 1, 0, 0, '2026-11-06 09:02:51');
INSERT INTO `feed_mark` VALUES (12, 28, 6, 1, 0, 0, '2026-11-06 09:02:52');
INSERT INTO `feed_mark` VALUES (13, 1, 6, 1, 0, 0, '2026-11-16 08:46:07');
INSERT INTO `feed_mark` VALUES (14, 36, 1, 1, 0, 0, '2026-11-16 09:37:24');
INSERT INTO `feed_mark` VALUES (15, 36, 2, 1, 0, 0, '2026-11-16 09:37:28');
INSERT INTO `feed_mark` VALUES (16, 36, 3, 1, 0, 0, '2026-11-16 09:37:30');
INSERT INTO `feed_mark` VALUES (17, 36, 4, 1, 0, 0, '2026-11-16 09:37:30');
INSERT INTO `feed_mark` VALUES (18, 36, 5, 1, 0, 0, '2026-11-16 09:37:31');
INSERT INTO `feed_mark` VALUES (19, 36, 6, 1, 0, 0, '2026-11-16 09:37:32');
INSERT INTO `feed_mark` VALUES (20, 36, 7, 1, 0, 0, '2026-11-16 09:37:37');
INSERT INTO `feed_mark` VALUES (21, 36, 8, 1, 0, 0, '2026-11-16 09:37:41');

-- ----------------------------
-- Table structure for game_record
-- ----------------------------
DROP TABLE IF EXISTS `game_record`;
CREATE TABLE `game_record`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '关联 agent_user.id',
  `mode` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '训练模式：TARGET 靶场 / RECOIL 压枪 / REACTION 反应',
  `score` int NOT NULL DEFAULT 0 COMMENT '本局得分',
  `units` int NOT NULL DEFAULT 0 COMMENT '本局有效单位数（命中数 / 完成组数 / 达标次数）',
  `shots` int NOT NULL DEFAULT 0 COMMENT '本局总射击次数',
  `hits` int NOT NULL DEFAULT 0 COMMENT '本局命中次数',
  `avg_ms` int NOT NULL DEFAULT 0 COMMENT '本局平均反应毫秒数',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_user_mode`(`user_id` ASC, `mode` ASC) USING BTREE,
  INDEX `idx_user_time`(`user_id` ASC, `create_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 83 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'RANGE 训练场成绩' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of game_record
-- ----------------------------
INSERT INTO `game_record` VALUES (1, 1, 'TARGET', 293, 25, 29, 25, 0, '2026-11-02 09:12:05');
INSERT INTO `game_record` VALUES (2, 1, 'RECOIL', 8979, 1, 1, 1, 0, '2026-11-02 09:14:33');
INSERT INTO `game_record` VALUES (3, 1, 'RECOIL', 6993, 1, 1, 1, 0, '2026-11-02 09:14:49');
INSERT INTO `game_record` VALUES (4, 1, 'RECOIL', 6862, 1, 1, 1, 0, '2026-11-02 09:15:04');
INSERT INTO `game_record` VALUES (5, 1, 'RECOIL', 7250, 1, 1, 1, 0, '2026-11-02 09:15:18');
INSERT INTO `game_record` VALUES (6, 1, 'RECOIL', 4106, 0, 1, 0, 0, '2026-11-02 09:15:31');
INSERT INTO `game_record` VALUES (7, 1, 'RECOIL', 3435, 1, 1, 1, 0, '2026-11-02 09:15:45');
INSERT INTO `game_record` VALUES (8, 1, 'REACTION', 0, 0, 5, 5, 657, '2026-11-02 09:16:00');
INSERT INTO `game_record` VALUES (9, 1, 'REACTION', 595, 0, 5, 5, 481, '2026-11-02 09:16:16');
INSERT INTO `game_record` VALUES (10, 1, 'REACTION', 845, 0, 5, 5, 431, '2026-11-02 09:16:33');
INSERT INTO `game_record` VALUES (11, 1, 'REACTION', 1015, 1, 5, 5, 397, '2026-11-02 09:16:49');
INSERT INTO `game_record` VALUES (12, 1, 'TARGET', 27, 1, 3, 1, 0, '2026-11-02 09:21:45');
INSERT INTO `game_record` VALUES (13, 1, 'RECOIL', 9663, 1, 1, 1, 0, '2026-11-02 09:34:20');
INSERT INTO `game_record` VALUES (14, 1, 'RECOIL', 8980, 1, 1, 1, 0, '2026-11-02 09:45:03');
INSERT INTO `game_record` VALUES (15, 1, 'RECOIL', 9018, 1, 1, 1, 0, '2026-11-02 09:46:00');
INSERT INTO `game_record` VALUES (16, 1, 'REACTION', 890, 0, 5, 5, 422, '2026-11-05 14:00:17');
INSERT INTO `game_record` VALUES (17, 1, 'REACTION', 1105, 1, 5, 5, 379, '2026-11-05 14:00:37');
INSERT INTO `game_record` VALUES (18, 1, 'REACTION', 920, 0, 5, 5, 416, '2026-11-05 14:01:20');
INSERT INTO `game_record` VALUES (19, 1, 'RECOIL', 9668, 1, 1, 1, 0, '2026-11-05 14:01:39');
INSERT INTO `game_record` VALUES (20, 1, 'RECOIL', 10248, 1, 1, 1, 0, '2026-11-05 14:01:55');
INSERT INTO `game_record` VALUES (21, 1, 'TARGET', 362, 32, 38, 32, 0, '2026-11-05 14:02:32');
INSERT INTO `game_record` VALUES (22, 1, 'TARGET', 359, 31, 32, 31, 0, '2026-11-05 14:03:07');
INSERT INTO `game_record` VALUES (24, 1, 'REACTION', 975, 0, 5, 5, 405, '2026-11-05 18:47:42');
INSERT INTO `game_record` VALUES (25, 1, 'RECOIL', 10184, 1, 1, 1, 0, '2026-11-05 18:48:03');
INSERT INTO `game_record` VALUES (26, 1, 'TARGET', 390, 34, 34, 34, 0, '2026-11-05 18:48:48');
INSERT INTO `game_record` VALUES (27, 1, 'RECOIL', 10653, 1, 1, 1, 0, '2026-11-05 18:49:10');
INSERT INTO `game_record` VALUES (28, 1, 'RECOIL', 8932, 1, 1, 1, 0, '2026-11-05 18:49:26');
INSERT INTO `game_record` VALUES (29, 1, 'REACTION', 1115, 1, 5, 5, 377, '2026-11-05 18:49:44');
INSERT INTO `game_record` VALUES (30, 10, 'TARGET', 2000, 20, 22, 20, 400, '2026-11-05 19:28:23');
INSERT INTO `game_record` VALUES (36, 1, 'REACTION', 1115, 1, 5, 5, 377, '2026-11-05 21:54:52');
INSERT INTO `game_record` VALUES (37, 1, 'REACTION', 1115, 1, 5, 5, 377, '2026-11-05 21:55:09');
INSERT INTO `game_record` VALUES (38, 1, 'REACTION', 1105, 1, 5, 5, 379, '2026-11-05 21:55:25');
INSERT INTO `game_record` VALUES (39, 1, 'REACTION', 1050, 1, 5, 5, 390, '2026-11-05 21:55:48');
INSERT INTO `game_record` VALUES (40, 1, 'RECOIL', 10708, 1, 1, 1, 0, '2026-11-05 21:56:04');
INSERT INTO `game_record` VALUES (41, 1, 'RECOIL', 10182, 1, 1, 1, 0, '2026-11-05 21:56:22');
INSERT INTO `game_record` VALUES (42, 1, 'TARGET', 399, 35, 36, 35, 0, '2026-11-05 21:56:59');
INSERT INTO `game_record` VALUES (43, 26, 'TARGET', 366, 32, 35, 32, 0, '2026-11-05 22:56:43');
INSERT INTO `game_record` VALUES (44, 28, 'TARGET', 333, 29, 34, 29, 0, '2026-11-06 09:01:13');
INSERT INTO `game_record` VALUES (45, 28, 'REACTION', 0, 0, 5, 5, 645, '2026-11-06 09:01:35');
INSERT INTO `game_record` VALUES (46, 28, 'REACTION', 680, 0, 5, 5, 464, '2026-11-06 09:01:51');
INSERT INTO `game_record` VALUES (47, 28, 'RECOIL', 4734, 1, 1, 1, 0, '2026-11-06 09:02:07');
INSERT INTO `game_record` VALUES (48, 28, 'RECOIL', 5300, 0, 1, 0, 0, '2026-11-06 09:02:22');
INSERT INTO `game_record` VALUES (49, 28, 'RECOIL', 2047, 0, 1, 0, 0, '2026-11-06 09:07:14');
INSERT INTO `game_record` VALUES (50, 28, 'RECOIL', 8181, 1, 1, 1, 0, '2026-11-06 09:07:28');
INSERT INTO `game_record` VALUES (51, 1, 'RECOIL', 10249, 1, 1, 1, 0, '2026-11-06 09:07:44');
INSERT INTO `game_record` VALUES (52, 28, 'RECOIL', 715, 0, 1, 0, 0, '2026-11-06 09:07:59');
INSERT INTO `game_record` VALUES (53, 28, 'RECOIL', 7817, 1, 1, 1, 0, '2026-11-06 09:08:15');
INSERT INTO `game_record` VALUES (54, 28, 'RECOIL', 6218, 1, 1, 1, 0, '2026-11-06 09:08:28');
INSERT INTO `game_record` VALUES (55, 28, 'RECOIL', 549, 0, 1, 0, 0, '2026-11-06 09:08:41');
INSERT INTO `game_record` VALUES (56, 28, 'RECOIL', 10100, 1, 1, 1, 0, '2026-11-06 09:08:57');
INSERT INTO `game_record` VALUES (57, 28, 'RECOIL', 533, 0, 1, 0, 0, '2026-11-06 09:09:12');
INSERT INTO `game_record` VALUES (58, 28, 'REACTION', 810, 0, 5, 5, 438, '2026-11-06 09:09:35');
INSERT INTO `game_record` VALUES (59, 1, 'REACTION', 960, 0, 5, 5, 408, '2026-11-06 09:09:38');
INSERT INTO `game_record` VALUES (60, 28, 'REACTION', 870, 0, 5, 5, 426, '2026-11-06 09:09:52');
INSERT INTO `game_record` VALUES (61, 28, 'RECOIL', 2119, 0, 1, 0, 0, '2026-11-06 09:28:03');
INSERT INTO `game_record` VALUES (62, 28, 'RECOIL', 4347, 0, 1, 0, 0, '2026-11-06 09:28:29');
INSERT INTO `game_record` VALUES (63, 29, 'TARGET', 169, 15, 39, 15, 0, '2026-11-16 08:45:09');
INSERT INTO `game_record` VALUES (64, 1, 'TARGET', 334, 29, 33, 29, 0, '2026-11-16 08:46:56');
INSERT INTO `game_record` VALUES (65, 31, 'TARGET', 210, 18, 30, 18, 0, '2026-11-16 08:48:49');
INSERT INTO `game_record` VALUES (66, 31, 'TARGET', 235, 20, 29, 20, 0, '2026-11-16 08:49:27');
INSERT INTO `game_record` VALUES (67, 30, 'REACTION', 0, 0, 5, 5, 1126, '2026-11-16 08:49:55');
INSERT INTO `game_record` VALUES (68, 31, 'REACTION', 145, 0, 5, 5, 571, '2026-11-16 08:49:57');
INSERT INTO `game_record` VALUES (69, 31, 'REACTION', 775, 0, 5, 5, 445, '2026-11-16 08:50:15');
INSERT INTO `game_record` VALUES (70, 30, 'REACTION', 0, 0, 5, 5, 2276, '2026-11-16 08:50:24');
INSERT INTO `game_record` VALUES (71, 31, 'REACTION', 270, 0, 5, 5, 546, '2026-11-16 08:50:35');
INSERT INTO `game_record` VALUES (72, 30, 'RECOIL', 2420, 0, 1, 0, 0, '2026-11-16 08:50:44');
INSERT INTO `game_record` VALUES (73, 30, 'TARGET', 305, 26, 29, 26, 0, '2026-11-16 08:51:18');
INSERT INTO `game_record` VALUES (74, 36, 'TARGET', 259, 23, 40, 23, 0, '2026-11-16 09:33:39');
INSERT INTO `game_record` VALUES (75, 36, 'REACTION', 65, 0, 5, 5, 587, '2026-11-16 09:33:55');
INSERT INTO `game_record` VALUES (76, 36, 'RECOIL', 3912, 1, 1, 1, 0, '2026-11-16 09:34:12');
INSERT INTO `game_record` VALUES (77, 36, 'REACTION', 910, 0, 5, 5, 418, '2026-11-16 09:34:28');
INSERT INTO `game_record` VALUES (78, 36, 'REACTION', 1005, 1, 5, 5, 399, '2026-11-16 09:35:50');
INSERT INTO `game_record` VALUES (79, 36, 'RECOIL', 3301, 0, 1, 0, 0, '2026-11-16 09:36:06');
INSERT INTO `game_record` VALUES (80, 36, 'TARGET', 377, 34, 46, 34, 0, '2026-11-16 09:36:40');
INSERT INTO `game_record` VALUES (81, 36, 'REACTION', 880, 0, 5, 5, 424, '2026-11-16 09:36:57');
INSERT INTO `game_record` VALUES (82, 36, 'RECOIL', 2522, 0, 1, 0, 0, '2026-11-16 09:37:14');

-- ----------------------------
-- Table structure for home_feed
-- ----------------------------
DROP TABLE IF EXISTS `home_feed`;
CREATE TABLE `home_feed`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `kind` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'NEWS' COMMENT '类型：NEWS 情报 / PATCH 版本 / MISSION 任务',
  `title` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '标题',
  `summary` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '摘要',
  `body` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL COMMENT '正文（换行分段）',
  `category_code` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '关联一级分类，可为空',
  `tag` varchar(24) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '角标文案',
  `source` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '情报来源',
  `published_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
  `heat` int NOT NULL DEFAULT 0 COMMENT '热度，越大越靠前',
  `importance` tinyint NOT NULL DEFAULT 1 COMMENT '1 常规 / 2 重要 / 3 紧急',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1 启用，0 下线',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_kind`(`kind` ASC) USING BTREE,
  INDEX `idx_pub`(`published_at` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '首页动态流' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of home_feed
-- ----------------------------
INSERT INTO `home_feed` VALUES (1, 'PATCH', 'v8.11 平衡性调整', '步枪后坐曲线回调，控场类技能冷却小幅上调，竞技环境重新洗牌。', '步枪后坐曲线整体回调，中距离连发的散布收敛 12%，VANDAL 与 PHANTOM 的强势区间重新拉开差距。\n控场类技能冷却上调 3~5 秒，烟雾与致盲的覆盖时长不变，但二次布控的节奏明显变慢，控场位需要更谨慎地选择出手时机。\n竞技模式的分段权重同步调整，连胜加成从第三场开始生效。', 'GEAR', 'HOT', 'VALORANT 平衡性团队', '2026-10-14 09:00:00', 100, 3, 1, '2026-10-28 16:35:52');
INSERT INTO `home_feed` VALUES (2, 'MISSION', '限时行动 · NIGHTFALL', '夜幕据点争夺开放至本月末，完成 5 场可解锁专属喷漆。', '夜幕据点争夺限时开放至本月末，地图视野受限，投掷物收益翻倍。\n完成 5 场行动即可解锁专属喷漆，完成全部阶段性目标追加一枚动态徽章。\n建议与侦察位双排，夜视受限环境下信息收集的价值远高于正面枪法。', 'MISSION', 'NEW', '行动指挥中心', '2026-10-13 18:30:00', 96, 2, 1, '2026-10-28 16:35:52');
INSERT INTO `home_feed` VALUES (3, 'NEWS', '竞技赛季结算提醒', '本赛季将于 10 月 31 日 23:59 结算，请确认你的段位奖励领取状态。', '本赛季将于 10 月 31 日 23:59 结算，段位奖励按结算瞬间的段位发放。\n请确认你的段位奖励领取状态，逾期未领取的奖励不做补发。\n结算后进入 72 小时休赛期，期间不计入任何排位数据。', 'MISSION', 'NOTICE', '竞技系统', '2026-10-12 12:00:00', 88, 2, 1, '2026-10-28 16:35:52');
INSERT INTO `home_feed` VALUES (4, 'NEWS', '档案库完成数字化', '全部特工、装备与任务档案已入库，现支持分级分类检索。', '全部特工、装备与任务档案已完成数字化入库，支持分级分类检索与关键词模糊匹配。\n每条档案附带战术定位、四维评分与背景故事，档案分级 S / A / B 对应实战出场率。\n后续会开放档案收藏与对比功能。', 'AGENT', 'SYSTEM', '档案管理局', '2026-10-11 10:15:00', 84, 1, 1, '2026-10-28 16:35:52');
INSERT INTO `home_feed` VALUES (5, 'PATCH', '反作弊模块升级', '新增行为特征检测，异常对局的判定速度与准确率均有提升。', '新增基于行为特征的检测模型，异常对局的判定速度提升至原来的 2.3 倍。\n误判率下降约 40%，被误判的对局会在 24 小时内自动撤销并补偿。\n举报通道同步升级，处理结果会以情报形式推送到本中心。', '', 'SYSTEM', '安全运营中心', '2026-10-10 15:40:00', 76, 2, 1, '2026-10-28 16:35:52');
INSERT INTO `home_feed` VALUES (6, 'MISSION', '训练场靶机刷新', 'RANGE 新增移动靶与跳靶，压枪与急停练习更贴近实战。', 'RANGE 新增移动靶与跳靶两种靶机类型，压枪与急停练习更贴近实战节奏。\n靶机难度分三档，第三档的移动速度接近真实对局中的横向拉枪。\n训练成绩不计入任何战绩统计，可以放心反复练习。', 'MISSION', 'UPDATE', '训练设施', '2026-10-09 11:20:00', 70, 1, 1, '2026-10-28 16:35:52');
INSERT INTO `home_feed` VALUES (7, 'NEWS', '周末双倍经验', '本周五 18:00 至周日 24:00，全部模式经验加成 100%。', '本周五 18:00 至周日 24:00，全部模式经验加成 100%，可与战斗通行证叠加。\n限时行动同样参与加成，是补齐任务进度的好时机。\n加成期间的对局数据正常计入赛季统计。', 'MISSION', 'EVENT', '运营活动', '2026-10-08 09:00:00', 66, 1, 1, '2026-10-28 16:35:52');
INSERT INTO `home_feed` VALUES (8, 'PATCH', '装备库数据校准', '依据近 30 天实战数据重新校准了各枪械的火力与机动评分。', '依据近 30 天实战数据重新校准了各枪械的火力与机动评分，评分口径统一为「每千次交火的收益」。\n狙击枪的机动评分下调，冲锋枪的近距离收益上调，整体的评分分布更贴近真实梯度。\n武器库页面展示的数值即为本次校准后的结果。', 'GEAR', 'UPDATE', '军械数据中心', '2026-10-07 16:00:00', 60, 1, 1, '2026-10-28 16:35:52');

-- ----------------------------
-- Table structure for mission_brief
-- ----------------------------
DROP TABLE IF EXISTS `mission_brief`;
CREATE TABLE `mission_brief`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `mission_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '任务代号，关联 agent_archive.code',
  `briefing` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '任务简报',
  `objectives` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '目标清单（JSON 字符串数组）',
  `reward` int NOT NULL DEFAULT 0 COMMENT '结算积分',
  `duration_min` int NOT NULL DEFAULT 30 COMMENT '任务时限（分钟）',
  `region` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '' COMMENT '作战区域',
  `squad` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '5V5' COMMENT '编队规模',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1 上线 / 0 下线',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_mission_code`(`mission_code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '作战任务简报' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of mission_brief
-- ----------------------------
INSERT INTO `mission_brief` VALUES (1, 'ascent', '双点位地图，中路可开闭的闸门决定了整局的攻防节奏。情报显示敌方在 B 点布置了交叉火力，建议先控中路再分兵施压。', '[\"占领 A 点区域\",\"控制中路可开闭闸门\",\"完成 3 次有效击杀\",\"安放尖刺并成功引爆\"]', 120, 40, '威尼斯 · VENICE', '5V5', 1, '2026-10-28 16:35:53', '2026-10-28 16:35:53');
INSERT INTO `mission_brief` VALUES (2, 'bind', '无中路的双点图，两处单向传送门让绕后变得随心所欲。切断传送门视野是拿下本局的关键。', '[\"封锁 A 点传送门视野\",\"占领并守住 B 点\",\"完成 2 次绕后击杀\",\"安放尖刺并成功引爆\"]', 180, 45, '摩洛哥 · MOROCCO', '5V5', 1, '2026-10-28 16:35:53', '2026-10-28 16:35:53');
INSERT INTO `mission_brief` VALUES (3, 'haven', '罕见的三点位地图，战线被拉长，信息收集比枪法更重要。任何一处失守都会让轮转陷入被动。', '[\"完成开局信息侦察\",\"守住被指定的点位\",\"完成 4 次有效击杀\",\"拿下本局胜利\"]', 150, 50, '不丹 · BHUTAN', '5V5', 1, '2026-10-28 16:35:53', '2026-10-28 16:35:53');
INSERT INTO `mission_brief` VALUES (4, 'range', '训练场，靶机与 bots 全开放，压枪与急停的日常修行地。所有训练项目均不计入战绩。', '[\"靶机命中 30 次\",\"完成压枪练习 3 组\",\"急停射击达标 2 次\"]', 40, 20, '训练设施 · RANGE', '单人', 1, '2026-10-28 16:35:53', '2026-10-28 16:35:53');
INSERT INTO `mission_brief` VALUES (5, 'nightfall', '限时行动：夜幕下的据点争夺，视野受限，投掷物价值翻倍。行动窗口仅在三十分钟内有效。', '[\"在夜视受限状态下进入据点\",\"用投掷物完成 2 次击杀\",\"坚持到行动结束\"]', 220, 30, '夜幕据点 · NIGHTFALL', '5V5', 1, '2026-10-28 16:35:53', '2026-10-28 16:35:53');
INSERT INTO `mission_brief` VALUES (6, 'breakout', '限时行动：护送与突围交替，节奏快到没有喘息窗口。护送目标一旦停滞，敌方增援会在 20 秒内抵达。', '[\"完成一轮护送\",\"完成一次突围\",\"队伍存活至撤离点\"]', 90, 25, '突围通道 · BREAKOUT', '5V5', 1, '2026-10-28 16:35:53', '2026-10-28 16:35:53');

-- ----------------------------
-- Table structure for mission_progress
-- ----------------------------
DROP TABLE IF EXISTS `mission_progress`;
CREATE TABLE `mission_progress`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `user_id` bigint NOT NULL COMMENT '关联 agent_user.id',
  `mission_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '任务代号',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '1 进行中 / 2 待结算 / 3 已结算',
  `done_objectives` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '[]' COMMENT '已完成目标下标（JSON 数组）',
  `started_at` datetime NOT NULL COMMENT '接取时间',
  `deadline` datetime NOT NULL COMMENT '限时截止',
  `finished_at` datetime NULL DEFAULT NULL COMMENT '结算时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_user_mission`(`user_id` ASC, `mission_code` ASC) USING BTREE,
  INDEX `idx_user`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 20 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '特工任务进度' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of mission_progress
-- ----------------------------
INSERT INTO `mission_progress` VALUES (1, 1, 'ascent', 3, '[0,1,2,3]', '2026-11-02 08:56:55', '2026-11-02 09:36:55', '2026-11-02 08:57:08', '2026-11-02 08:56:55');
INSERT INTO `mission_progress` VALUES (2, 26, 'ascent', 1, '[2,3]', '2026-11-05 22:55:27', '2026-11-05 23:35:27', NULL, '2026-11-05 22:55:26');
INSERT INTO `mission_progress` VALUES (3, 28, 'bind', 3, '[0,1,2,3]', '2026-11-06 09:03:02', '2026-11-06 09:48:02', '2026-11-06 09:03:09', '2026-11-06 09:03:01');
INSERT INTO `mission_progress` VALUES (4, 28, 'ascent', 3, '[0,1,2,3]', '2026-11-06 09:03:15', '2026-11-06 09:43:15', '2026-11-06 09:03:18', '2026-11-06 09:03:14');
INSERT INTO `mission_progress` VALUES (5, 28, 'nightfall', 3, '[0,1,2]', '2026-11-06 09:28:48', '2026-11-06 09:58:48', '2026-11-06 09:28:54', '2026-11-06 09:28:48');
INSERT INTO `mission_progress` VALUES (6, 1, 'bind', 3, '[0,1,2,3]', '2026-11-16 08:45:55', '2026-11-16 09:30:55', '2026-11-16 08:45:59', '2026-11-16 08:45:54');
INSERT INTO `mission_progress` VALUES (7, 30, 'bind', 1, '[]', '2026-11-16 08:49:20', '2026-11-16 09:34:20', NULL, '2026-11-16 08:49:20');
INSERT INTO `mission_progress` VALUES (8, 36, 'ascent', 3, '[0,1,2,3]', '2026-11-16 09:32:15', '2026-11-16 10:12:15', '2026-11-16 09:32:20', '2026-11-16 09:32:15');
INSERT INTO `mission_progress` VALUES (9, 36, 'bind', 3, '[0,1,2,3]', '2026-11-16 09:32:24', '2026-11-16 10:17:24', '2026-11-16 09:32:27', '2026-11-16 09:32:23');
INSERT INTO `mission_progress` VALUES (10, 36, 'haven', 3, '[0,1,2,3]', '2026-11-16 09:32:29', '2026-11-16 10:22:29', '2026-11-16 09:32:32', '2026-11-16 09:32:29');
INSERT INTO `mission_progress` VALUES (11, 36, 'range', 3, '[0,1,2]', '2026-11-16 09:32:35', '2026-11-16 09:52:35', '2026-11-16 09:32:38', '2026-11-16 09:32:35');
INSERT INTO `mission_progress` VALUES (12, 36, 'nightfall', 3, '[0,1,2]', '2026-11-16 09:32:43', '2026-11-16 10:02:43', '2026-11-16 09:32:49', '2026-11-16 09:32:43');
INSERT INTO `mission_progress` VALUES (13, 36, 'breakout', 3, '[0,1,2]', '2026-11-16 09:32:51', '2026-11-16 09:57:51', '2026-11-16 09:32:54', '2026-11-16 09:32:51');
INSERT INTO `mission_progress` VALUES (14, 37, 'ascent', 3, '[0,1,2,3]', '2026-11-16 09:42:40', '2026-11-16 10:22:40', '2026-11-16 09:42:43', '2026-11-16 09:42:40');
INSERT INTO `mission_progress` VALUES (15, 37, 'bind', 3, '[0,1,2,3]', '2026-11-16 09:42:46', '2026-11-16 10:27:46', '2026-11-16 09:42:49', '2026-11-16 09:42:45');
INSERT INTO `mission_progress` VALUES (16, 37, 'haven', 3, '[0,1,2,3]', '2026-11-16 09:42:56', '2026-11-16 10:32:56', '2026-11-16 09:43:00', '2026-11-16 09:42:55');
INSERT INTO `mission_progress` VALUES (17, 37, 'breakout', 3, '[0,1,2]', '2026-11-16 09:43:07', '2026-11-16 10:08:07', '2026-11-16 09:43:09', '2026-11-16 09:43:07');
INSERT INTO `mission_progress` VALUES (18, 37, 'nightfall', 3, '[0,1,2]', '2026-11-16 09:43:12', '2026-11-16 10:13:12', '2026-11-16 09:43:15', '2026-11-16 09:43:11');
INSERT INTO `mission_progress` VALUES (19, 37, 'range', 3, '[0,1,2]', '2026-11-16 09:43:19', '2026-11-16 10:03:19', '2026-11-16 09:43:21', '2026-11-16 09:43:19');

-- ----------------------------
-- Table structure for weapon_catalog
-- ----------------------------
DROP TABLE IF EXISTS `weapon_catalog`;
CREATE TABLE `weapon_catalog`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `code` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '武器代号：classic/sheriff/marshal/guardian/phantom/vandal/odin/operator',
  `name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '武器中文名',
  `category` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT '步枪' COMMENT '类别：手枪/步枪/狙击枪/机枪',
  `price` int NOT NULL DEFAULT 0 COMMENT '售价（信用点，0 = 免费）',
  `req_level` int NOT NULL DEFAULT 1 COMMENT '购买所需英雄等级',
  `power` int NOT NULL DEFAULT 0 COMMENT '装备后战力加成',
  `sort` int NOT NULL DEFAULT 0 COMMENT '商店展示顺序（小的在前）',
  `on_sale` tinyint NOT NULL DEFAULT 1 COMMENT '1 上架 / 0 下架（下架后不可购买）',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_code`(`code` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '军械商店武器目录（后台可编辑价格与等级门槛）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of weapon_catalog
-- ----------------------------
INSERT INTO `weapon_catalog` VALUES (1, 'classic', '标配', '手枪', 0, 1, 5, 1, 1, '2026-11-09 09:48:39');
INSERT INTO `weapon_catalog` VALUES (2, 'sheriff', '正义', '手枪', 800, 1, 15, 2, 1, '2026-11-09 09:48:39');
INSERT INTO `weapon_catalog` VALUES (3, 'marshal', '鸟狙', '狙击枪', 950, 2, 25, 3, 1, '2026-11-09 09:48:39');
INSERT INTO `weapon_catalog` VALUES (4, 'guardian', '戍卫', '步枪', 2250, 3, 35, 4, 1, '2026-11-09 09:48:39');
INSERT INTO `weapon_catalog` VALUES (5, 'phantom', '幻影', '步枪', 2900, 4, 45, 5, 1, '2026-11-09 09:48:39');
INSERT INTO `weapon_catalog` VALUES (6, 'vandal', '狂徒', '步枪', 2900, 4, 45, 6, 1, '2026-11-09 09:48:39');
INSERT INTO `weapon_catalog` VALUES (7, 'odin', '战神', '机枪', 3200, 6, 50, 7, 1, '2026-11-09 09:48:39');
INSERT INTO `weapon_catalog` VALUES (8, 'operator', '冥狙', '狙击枪', 4700, 8, 60, 8, 1, '2026-11-09 09:48:39');

SET FOREIGN_KEY_CHECKS = 1;
