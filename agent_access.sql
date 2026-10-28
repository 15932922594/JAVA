/*
 Navicat Premium Dump SQL

 Source Server         : localhost_3306
 Source Server Type    : MySQL
 Source Server Version : 80046 (8.0.46)
 Source Host           : localhost:3306
 Source Schema         : agent_access

 Target Server Type    : MySQL
 Target Server Version : 80046 (8.0.46)
 File Encoding         : 65001

 Date: 28/10/2026 16:57:32
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
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '后台操作日志' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of admin_log
-- ----------------------------
INSERT INTO `admin_log` VALUES (1, 1, 'admin', 'admin', 'LOGIN', '管理员登录', '2026-10-28 16:38:19');

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
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '后台管理员' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of admin_user
-- ----------------------------
INSERT INTO `admin_user` VALUES (1, 'admin', '超级管理员', 'b0b168d92e122cca122586f50d2e1d05af219d8eed3d79945d51cabef6de5bd3', '5f8a9b3c1d2e4f60718293a4b5c6d7e8', '782b411bdd174ce1898f887e613fb428', '2026-10-30 16:38:20', 1, '2026-10-28 16:35:51', '2026-10-28 16:35:51');

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
) ENGINE = InnoDB AUTO_INCREMENT = 21 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '首页档案主表（特工/装备/任务）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of agent_archive
-- ----------------------------
INSERT INTO `agent_archive` VALUES (1, 'AGENT', 'ASSAULT', 'S', 'vector', 'VECTOR', '捷风', 'V', '#FF4655', '以极高机动性撕裂防线的突进型特工，擅长在瞬间改写交火态势。', '档案解密等级：Ω。\n\n VECTOR 原是环城竞速联盟最年轻的冠军车手，一场针对护送车队的伏击改变了她的轨迹——她以 217km/h 的极速连穿三道封锁线，把十二名伤员从火线上完整带回。战后审查官问她凭什么敢那样开，她只回了一句：「速度就是我的掩体。」\n\n 入队三年，她的突入记录无人打破：从破墙到占点，平均用时 1.7 秒。教官在评语栏里写：她不是在冲锋，是在瞬移。', '[\n    {\"slot\":\"Q\",\"name\":\"相位突进\",\"desc\":\"向准星方向瞬间位移一小段，用来抢点、拉枪线或脱离交叉火力。\"},\n    {\"slot\":\"E\",\"name\":\"破障射线\",\"desc\":\"放出一道穿透射线，短暂削弱命中敌人的护甲，正面硬刚更占便宜。\"},\n    {\"slot\":\"X\",\"name\":\"矢量过载\",\"desc\":\"短时疾行且移动射击精度不下降，适合一口气撕开一道防线。\"}\n  ]', '/agents/vector.png', 92, 76, 44, 38, 98, 1, 10, 1, '2026-10-28 16:35:52', '2026-10-28 16:50:13');
INSERT INTO `agent_archive` VALUES (2, 'AGENT', 'RECON', 'A', 'arclight', 'ARCLIGHT', '蝰蛇', 'A', '#00E0C6', '用电弧脉冲扫描战场，为队伍点亮迷雾中的每一个目标。', '档案解密等级：Ω。\n\n ARCLIGHT 曾是深空监听站的值守员，在长达四年的孤站生活里，他练就了从宇宙噪声中分辨一句耳语的耐心。一次例行检修中，他从一段被判定为背景辐射的信号里，还原出敌方跳频通讯的完整频率表，整个战区的预警时间因此提前了十一分钟。\n\n 如今他把监听天线换成了电弧脉冲，战场在他眼中是一张不断刷新的点云图。队友的说法更直接：「他开枪之前，地图早就打完了。」', '[\n    {\"slot\":\"Q\",\"name\":\"电弧脉冲\",\"desc\":\"向身前扇区释放脉冲，被命中的敌人轮廓会被标记，隔着墙也能看见。\"},\n    {\"slot\":\"E\",\"name\":\"全域扫描\",\"desc\":\"一次性点亮附近区域的敌人位置，持续时间短，进点前摸站位最好用。\"},\n    {\"slot\":\"X\",\"name\":\"电网陷阱\",\"desc\":\"布下电网，敌人经过会被减速并暴露位置，兼顾封锁与预警。\"}\n  ]', '/agents/arclight.png', 58, 86, 72, 46, 91, 1, 11, 1, '2026-10-28 16:35:52', '2026-10-28 16:50:19');
INSERT INTO `agent_archive` VALUES (3, 'AGENT', 'CONTROL', 'S', 'phantom', 'PHANTOM', '幽影', 'P', '#A66CFF', '制造幻象与烟幕，掌控每一次交火的节奏与视野。', '档案解密等级：Ω。\n\n 关于 PHANTOM 的入职档案只有一页，且一半被涂黑。已知信息：他曾在敌后情报部门服役九年，执行过十七次任务，无一次留下影像记录；他的上一任搭档坚称自己从未见过他的正脸。\n\n 他从不解释能力原理，只留下一句被全体队员记住的话：「你们看到的，是我想让你们看到的。」第一次和他在训练场对枪的人，最后都在朝空气开火。', '[\n    {\"slot\":\"Q\",\"name\":\"幻影分身\",\"desc\":\"生成一个向前走的分身诱饵，用来骗第一枪、确认敌人架在哪。\"},\n    {\"slot\":\"E\",\"name\":\"遮断烟幕\",\"desc\":\"在指定位置落下烟幕切断视野，进点、拆包、撤退都靠它。\"},\n    {\"slot\":\"X\",\"name\":\"错觉领域\",\"desc\":\"大范围幻象区，敌人视野受阻且分不清真假身，能强行改写交火节奏。\"}\n  ]', '/agents/phantom.png', 52, 74, 93, 50, 95, 1, 12, 1, '2026-10-28 16:35:52', '2026-10-28 16:49:25');
INSERT INTO `agent_archive` VALUES (4, 'AGENT', 'SENTINEL', 'A', 'onyx', 'ONYX', '壹决', 'O', '#FFB443', '以坚固壁垒庇护队友，是阵地攻防中不可撼动的支点。', '档案解密等级：Ω。\n\n ONYX 是全队唯一拒绝佩枪的特工。他曾是一支山地救援队的队长，在一次雪崩中用身体撑住坍塌的冰缝整整四十分钟，让七名被困者全部脱险——他的左肩里至今留着三枚钢钉，阴雨天会替他记住那天的气温。\n\n 入队后，他把「守住」变成了战术：他站的防线没有后退这个词。指挥部对他的评估只有一行字：把任何交火地点，变成我方主场。', '[\n    {\"slot\":\"Q\",\"name\":\"岩壁屏障\",\"desc\":\"竖起一道可再生的墙体，封住通路或专门挡对面狙击的枪线。\"},\n    {\"slot\":\"E\",\"name\":\"哨位陷阱\",\"desc\":\"布置自动预警装置，敌人靠近就减速并暴露位置。\"},\n    {\"slot\":\"X\",\"name\":\"壁垒成型\",\"desc\":\"短时间展开加固防线，站在后面的队友受到的伤害明显减少。\"}\n  ]', '/agents/onyx.png', 46, 52, 64, 96, 88, 1, 13, 1, '2026-10-28 16:35:52', '2026-10-28 16:51:13');
INSERT INTO `agent_archive` VALUES (5, 'AGENT', 'CONTROL', 'A', 'tempest', 'TEMPEST', '海神', 'T', '#4DA6FF', '召唤风暴封锁通路，让敌人在自己的领地寸步难行。', '档案解密等级：Ω。\n\n TEMPEST 出生在气旋观测船「信风号」上，整个童年在风暴眼里度过。十六岁那年，她用自己的气象模型提前六小时预报了一场被官方判定「不可能生成」的台风，救下了一整座港口。\n\n 现在她召唤的风暴只封锁一件东西：敌人的退路。被她控住过通道的对手给出了一致评价：宁可绕路三公里。', '[\n    {\"slot\":\"Q\",\"name\":\"强风幕墙\",\"desc\":\"生成一堵风墙，敌人穿行时视野受损、移速下降。\"},\n    {\"slot\":\"E\",\"name\":\"乱流推挤\",\"desc\":\"用气流把敌人推向一侧，强行打乱他站位，为队友拉出击杀窗口。\"},\n    {\"slot\":\"X\",\"name\":\"风暴中心\",\"desc\":\"在一片区域降下持续风暴，长时间封锁通路，拖延或守点时极强。\"}\n  ]', '/agents/tempest.png', 54, 70, 90, 62, 84, 0, 14, 1, '2026-10-28 16:35:52', '2026-10-28 16:51:31');
INSERT INTO `agent_archive` VALUES (6, 'AGENT', 'ASSAULT', 'B', 'ember', 'EMBER', '尚博乐', 'E', '#FF6B4A', '以烈焰灼烧前线的爆发型特工，高风险，也高回报。', '档案解密等级：Ω。\n\n EMBER 的档案从一个失败开始：爆破课程三次不及格，理由都是「当量超出教学大纲上限」。教官最后在评语里写：这不是学不会，是不甘心只炸那么大。\n\n 他是全队公认的疯子，也是公认的幸运儿——七次被判定「阵亡」的战报，七次都活着回来了。他的战前动员只有一句话：「烧完这把，就赢了。」', '[\n    {\"slot\":\"Q\",\"name\":\"燃焰喷发\",\"desc\":\"近距离喷射火焰，专门清理两个人就得挤过去的窄通道。\"},\n    {\"slot\":\"E\",\"name\":\"火墙封路\",\"desc\":\"在地面拉出一段火墙，穿过的敌人持续掉血，逼他们改路线。\"},\n    {\"slot\":\"X\",\"name\":\"燃尽冲刺\",\"desc\":\"自身短暂燃烧，移速和换弹大幅加快，代价是血量持续下降。\"}\n  ]', '/agents/ember.png', 90, 64, 52, 54, 79, 0, 15, 1, '2026-10-28 16:35:52', '2026-10-28 16:52:49');
INSERT INTO `agent_archive` VALUES (7, 'GEAR', 'RIFLE', 'S', 'vandal', 'VANDAL', '姝蕊', 'V', '#FF4655', '高伤害全自动步枪，远距离头部一枪致命，正面交火的标杆。', '流水线上的第一支 VANDAL 编号 V-0001，至今仍在一线服役，其命中率常年霸榜军械库。', '[\n    {\"slot\":\"优势\",\"name\":\"任意距离一枪爆头\",\"desc\":\"不管多远，打中头就是秒杀，远距离对枪的标杆。\"},\n    {\"slot\":\"优势\",\"name\":\"伤害不衰减\",\"desc\":\"远距离伤害没有距离惩罚，架点可以完全不考虑站位深度。\"},\n    {\"slot\":\"代价\",\"name\":\"后坐大\",\"desc\":\"连射很飘，要点射、要压枪，不适合闭着眼泼。\"}\n  ]', '/agents/vandal.png', 88, 52, 40, 30, 96, 1, 20, 1, '2026-10-28 16:35:52', '2026-10-28 16:55:36');
INSERT INTO `agent_archive` VALUES (8, 'GEAR', 'RIFLE', 'A', 'phantom-w', 'PHANTOM-W', '狂徒', 'P', '#A66CFF', '消音步枪，后坐可控，适合中距离压制与隐蔽推进。', '消音组件让它被称作「听不见的死神」，每一支出厂前都要在静音舱里过最后一道检测。', '[\n    {\"slot\":\"优势\",\"name\":\"消音\",\"desc\":\"开枪不会暴露自己的位置提示，隔着烟打人对方很难反查。\"},\n    {\"slot\":\"优势\",\"name\":\"后坐可控\",\"desc\":\"连发比劫掠者柔和得多，中距离压枪一串很稳。\"},\n    {\"slot\":\"代价\",\"name\":\"远距离衰减\",\"desc\":\"超过中远距离伤害明显下降，远点不如劫掠者。\"}\n  ]', '/agents/phantom-w.png', 76, 66, 52, 34, 90, 0, 21, 1, '2026-10-28 16:35:52', '2026-10-28 16:56:23');
INSERT INTO `agent_archive` VALUES (9, 'GEAR', 'SMG', 'A', 'spectre', 'SPECTRE', '幻影', 'S', '#00E0C6', '高射速冲锋枪，近距离泼洒压制，经济局的性价比之选。', '经济局之王。老队员的说法：手头紧的时候，SPECTRE 比勇气可靠。', '[\n    {\"slot\":\"优势\",\"name\":\"高射速泼洒\",\"desc\":\"近距离短时间叠出成吨伤害，贴上脸几乎必胜。\"},\n    {\"slot\":\"优势\",\"name\":\"跑打稳定\",\"desc\":\"移动射击散布小，边走边输出也不至于全飘。\"},\n    {\"slot\":\"代价\",\"name\":\"距离衰减\",\"desc\":\"稍微远一点伤害就掉，中远距离基本打不动。\"}\n  ]', '/agents/spectre.png', 70, 74, 44, 28, 82, 0, 22, 1, '2026-10-28 16:35:52', '2026-10-28 16:53:17');
INSERT INTO `agent_archive` VALUES (10, 'GEAR', 'SNIPER', 'S', 'operator', 'OPERATOR', '冥狙', 'O', '#FFB443', '一击必杀的重型狙击枪，架点封锁整条通路的终极答案。', '每一支 OPERATOR 的镜桥都由匠人手工校准，编号刻在枪托内侧，遗失即全员追责。', '[\n    {\"slot\":\"优势\",\"name\":\"一枪必杀\",\"desc\":\"打中躯干直接终结，哪怕打腿也是重伤。\"},\n    {\"slot\":\"优势\",\"name\":\"封锁通路\",\"desc\":\"一个人架枪就能封死整条主路，对面必须花道具强行开。\"},\n    {\"slot\":\"代价\",\"name\":\"贵且笨重\",\"desc\":\"价格高、移速慢、开镜慢，一旦掉枪代价巨大。\"}\n  ]', '/agents/operator.png', 99, 30, 36, 44, 93, 1, 23, 1, '2026-10-28 16:35:52', '2026-10-28 16:54:40');
INSERT INTO `agent_archive` VALUES (11, 'GEAR', 'SNIPER', 'B', 'marshal', 'MARSHAL', '鸟狙', 'M', '#4DA6FF', '轻型狙击枪，机动性更好，命中躯干即可终结交火。', '西部时代的精神续作。MARSHAL 的准星上没有多余的花纹，因为它只服务一件事。', '[\n    {\"slot\":\"优势\",\"name\":\"轻便好上手\",\"desc\":\"比战神便宜也轻得多，转移和补点灵活得多。\"},\n    {\"slot\":\"优势\",\"name\":\"躯干终结\",\"desc\":\"胸腹以上一枪致命，中距离一枪一个。\"},\n    {\"slot\":\"代价\",\"name\":\"容错低\",\"desc\":\"打腿杀不掉，开镜后不能连发，节奏慢。\"}\n  ]', '/agents/marshal.png', 82, 58, 40, 36, 71, 0, 24, 1, '2026-10-28 16:35:52', '2026-10-28 16:53:26');
INSERT INTO `agent_archive` VALUES (12, 'GEAR', 'SIDEARM', 'B', 'classic', 'CLASSIC', '标配', 'C', '#FF6B4A', '开局标配手枪，右键三连发在贴脸距离拥有惊喜爆发。', '所有人拿到的第一支枪。训练营墙上的标语：CLASSIC 用得好，你缺的从来不是枪。', '[\n    {\"slot\":\"优势\",\"name\":\"开局自带\",\"desc\":\"每回合白给，经济落后时最稳的兜底武器。\"},\n    {\"slot\":\"优势\",\"name\":\"右键三连\",\"desc\":\"贴脸三连发爆发很高，近距离容错极低。\"},\n    {\"slot\":\"代价\",\"name\":\"远距离无力\",\"desc\":\"超过中距离伤害骤降，别指望用它架远点。\"}\n  ]', '/agents/classic.png', 54, 60, 32, 26, 68, 0, 25, 1, '2026-10-28 16:35:52', '2026-10-28 16:53:41');
INSERT INTO `agent_archive` VALUES (13, 'GEAR', 'SIDEARM', 'A', 'sheriff', 'SHERIFF', '正义', 'H', '#FF4655', '高伤害左轮，一发入魂，是翻盘局最廉价的希望。', '赌徒的选择。一发命中叫翻盘，一发落空叫下班。', '[\n    {\"slot\":\"优势\",\"name\":\"躯干一枪\",\"desc\":\"打身子也是一枪致命，不用非得爆头。\"},\n    {\"slot\":\"优势\",\"name\":\"便宜高回报\",\"desc\":\"价格低但威力接近步枪，翻盘局最常见的选择。\"},\n    {\"slot\":\"代价\",\"name\":\"弹少且慢\",\"desc\":\"弹匣小、开火间隔长，空一枪就是致命失误。\"}\n  ]', '/agents/sheriff.png', 86, 50, 34, 30, 87, 0, 26, 1, '2026-10-28 16:35:52', '2026-10-28 16:53:51');
INSERT INTO `agent_archive` VALUES (14, 'GEAR', 'RIFLE', 'A', 'odin', 'ODIN', '战神', 'D', '#00E0C6', '弹链供弹的重机枪，穿墙压制能力冠绝全场。', '代号来自北欧主神。士兵们说，它开火的时候，整条走廊都在替对面祈祷。', '[\n    {\"slot\":\"优势\",\"name\":\"弹链压制\",\"desc\":\"超大弹容持续输出，一个人就能压死一条通道。\"},\n    {\"slot\":\"优势\",\"name\":\"穿墙射击\",\"desc\":\"子弹能打穿墙体，可以直接透过掩体验证甚至击杀。\"},\n    {\"slot\":\"代价\",\"name\":\"又重又慢\",\"desc\":\"移速慢、开镜慢，架点无敌但被人绕后基本没救。\"}\n  ]', '/agents/odin.png', 94, 24, 58, 48, 80, 0, 27, 1, '2026-10-28 16:35:52', '2026-10-28 16:54:02');
INSERT INTO `agent_archive` VALUES (15, 'MISSION', 'RANKED', 'A', 'ascent', 'ASCENT', '幽邃地窟', 'A', '#4DA6FF', '双点位地图，中路可开闭的闸门决定了整局的攻防节奏。', '高空平台 ASCENT 由旧轨道电梯中转站改建，中央闸门的开合至今沿用战前的机械逻辑。', NULL, '/missions/ascent.png', 62, 70, 66, 58, 92, 1, 30, 1, '2026-10-28 16:35:52', '2026-10-28 16:47:09');
INSERT INTO `agent_archive` VALUES (16, 'MISSION', 'RANKED', 'S', 'bind', 'BIND', '天枢云阙', 'B', '#A66CFF', '无中路的双点图，两处单向传送门让绕后变得随心所欲。', 'BIND 的单向传送门是战前物流网络的遗产，如今搬运的只有子弹与坏消息。', NULL, '/missions/bind.png', 66, 78, 70, 54, 90, 0, 31, 1, '2026-10-28 16:35:52', '2026-10-28 16:48:03');
INSERT INTO `agent_archive` VALUES (17, 'MISSION', 'RANKED', 'A', 'haven', 'HAVEN', '莲花古城', 'H', '#FFB443', '罕见的三点位地图，战线被拉长，信息收集比枪法更重要。', 'HAVEN 原是边境疗养院，三点位的布局让它成为侦察兵最爱的战场。', NULL, '/missions/haven.png', 60, 64, 74, 62, 86, 0, 32, 1, '2026-10-28 16:35:52', '2026-10-28 16:48:16');
INSERT INTO `agent_archive` VALUES (18, 'MISSION', 'TRAINING', 'B', 'range', 'RANGE', '靶场', 'R', '#3DDC97', '训练场，靶机与 bots 全开放，压枪与急停的日常修行地。', 'RANGE 的靶机每天被击倒两万次，然后被维修技师救活两万次。', NULL, '/missions/range.png', 30, 40, 20, 20, 74, 0, 33, 1, '2026-10-28 16:35:52', '2026-10-28 16:48:32');
INSERT INTO `agent_archive` VALUES (19, 'MISSION', 'EVENT', 'S', 'nightfall', 'NIGHTFALL', '', 'N', '#FF4655', '限时行动：夜幕下的据点争夺，视野受限，投掷物价值翻倍。', 'NIGHTFALL 行动只在停电的街区展开，目击报告里提到最多的东西是红色探照灯。', NULL, '/missions/nightfall.png', 78, 72, 80, 60, 89, 1, 34, 1, '2026-10-28 16:35:52', '2026-10-28 16:35:52');
INSERT INTO `agent_archive` VALUES (20, 'MISSION', 'EVENT', 'B', 'breakout', 'BREAKOUT', '', 'K', '#FF6B4A', '限时行动：护送与突围交替，节奏快到没有喘息窗口。', 'BREAKOUT 的原型是一次真实的监狱护送行动，代号沿用至今。', NULL, '/missions/breakout.png', 74, 80, 56, 46, 70, 0, 35, 1, '2026-10-28 16:35:52', '2026-10-28 16:35:52');

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
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '第三方账号绑定与授权票据' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of agent_oauth
-- ----------------------------

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
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '找回密码验证码' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of agent_reset_code
-- ----------------------------

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
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '登录会话表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of agent_session
-- ----------------------------
INSERT INTO `agent_session` VALUES (1, 'e010db86453a4b2ba49698c8aa41eb21', 1, '2026-11-04 16:36:16', '2026-10-28 16:36:15');

-- ----------------------------
-- Table structure for agent_user
-- ----------------------------
DROP TABLE IF EXISTS `agent_user`;
CREATE TABLE `agent_user`  (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '特工代号',
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '邮箱',
  `password_hash` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '密码摘要 SHA-256(salt::password)',
  `salt` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL COMMENT '随机盐',
  `agent_index` int NOT NULL DEFAULT 0 COMMENT '注册时选择的特工下标',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_email`(`email` ASC) USING BTREE,
  UNIQUE INDEX `uk_name`(`name` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '特工账号表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of agent_user
-- ----------------------------
INSERT INTO `agent_user` VALUES (1, '爱打球的T', '264132801@qq.com', '3cb9bb890b91efdd310c935089eb3935b82ce46640a4b68bb0c5a2b72d28d2b5', '9e1431e9dbdaa424328eda90965d4ea6', 0, '2026-10-28 16:36:07', '2026-10-28 16:36:07');

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
) ENGINE = InnoDB AUTO_INCREMENT = 34 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '档案分级分类目录' ROW_FORMAT = Dynamic;

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
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '特工情报交互（已读/收藏/点赞）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of feed_mark
-- ----------------------------

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
) ENGINE = InnoDB AUTO_INCREMENT = 9 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '首页动态流' ROW_FORMAT = Dynamic;

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
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '作战任务简报' ROW_FORMAT = Dynamic;

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
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '特工任务进度' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of mission_progress
-- ----------------------------

SET FOREIGN_KEY_CHECKS = 1;
