-- ============================================================
-- AGENT ACCESS 情报中心模块建表脚本
-- 执行方式: mysql -uroot -p123456 --default-character-set=utf8mb4 < sql/intel.sql
-- 说明: 可重复执行（列存在性判断 + UPDATE 灌数据）
--   1. 给 home_feed 补充「来源 / 正文 / 重要度」三个字段（已有字段不动）
--   2. 新建 feed_mark 记录每个特工对每条情报的「已读 / 收藏 / 点赞」
-- ============================================================
CREATE DATABASE IF NOT EXISTS agent_access DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE agent_access;

-- ---------- 1. 给 home_feed 加列（列不存在时才加，可重复执行） ----------
SET @db = 'agent_access';
SET @tb = 'home_feed';

SET @sqlsrc := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = @db AND TABLE_NAME = @tb AND COLUMN_NAME = 'source') = 0,
  'ALTER TABLE home_feed ADD COLUMN source VARCHAR(64) NOT NULL DEFAULT '''' COMMENT ''情报来源'' AFTER tag',
  'SELECT ''skip source''');
PREPARE st FROM @sqlsrc; EXECUTE st; DEALLOCATE PREPARE st;

SET @sqlbody := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = @db AND TABLE_NAME = @tb AND COLUMN_NAME = 'body') = 0,
  'ALTER TABLE home_feed ADD COLUMN body TEXT COMMENT ''正文（换行分段）'' AFTER summary',
  'SELECT ''skip body''');
PREPARE st FROM @sqlbody; EXECUTE st; DEALLOCATE PREPARE st;

SET @sqlimp := IF(
  (SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = @db AND TABLE_NAME = @tb AND COLUMN_NAME = 'importance') = 0,
  'ALTER TABLE home_feed ADD COLUMN importance TINYINT NOT NULL DEFAULT 1 COMMENT ''1 常规 / 2 重要 / 3 紧急'' AFTER heat',
  'SELECT ''skip importance''');
PREPARE st FROM @sqlimp; EXECUTE st; DEALLOCATE PREPARE st;

-- ---------- 2. 情报交互记录 ----------
CREATE TABLE IF NOT EXISTS feed_mark (
  id          BIGINT   NOT NULL AUTO_INCREMENT COMMENT '主键',
  user_id     BIGINT   NOT NULL COMMENT '关联 agent_user.id',
  feed_id     BIGINT   NOT NULL COMMENT '关联 home_feed.id',
  is_read     TINYINT  NOT NULL DEFAULT 0 COMMENT '是否已读',
  starred     TINYINT  NOT NULL DEFAULT 0 COMMENT '是否收藏',
  liked       TINYINT  NOT NULL DEFAULT 0 COMMENT '是否点赞',
  update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_feed (user_id, feed_id),
  KEY idx_user (user_id),
  KEY idx_feed (feed_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='特工情报交互（已读/收藏/点赞）';

-- ---------- 3. 正文与来源数据 ----------
UPDATE home_feed SET
  source = 'VALORANT 平衡性团队',
  importance = 3,
  body = '步枪后坐曲线整体回调，中距离连发的散布收敛 12%，VANDAL 与 PHANTOM 的强势区间重新拉开差距。\n控场类技能冷却上调 3~5 秒，烟雾与致盲的覆盖时长不变，但二次布控的节奏明显变慢，控场位需要更谨慎地选择出手时机。\n竞技模式的分段权重同步调整，连胜加成从第三场开始生效。'
WHERE id = 1;

UPDATE home_feed SET
  source = '行动指挥中心',
  importance = 2,
  body = '夜幕据点争夺限时开放至本月末，地图视野受限，投掷物收益翻倍。\n完成 5 场行动即可解锁专属喷漆，完成全部阶段性目标追加一枚动态徽章。\n建议与侦察位双排，夜视受限环境下信息收集的价值远高于正面枪法。'
WHERE id = 2;

UPDATE home_feed SET
  source = '竞技系统',
  importance = 2,
  body = '本赛季将于 10 月 31 日 23:59 结算，段位奖励按结算瞬间的段位发放。\n请确认你的段位奖励领取状态，逾期未领取的奖励不做补发。\n结算后进入 72 小时休赛期，期间不计入任何排位数据。'
WHERE id = 3;

UPDATE home_feed SET
  source = '档案管理局',
  importance = 1,
  body = '全部特工、装备与任务档案已完成数字化入库，支持分级分类检索与关键词模糊匹配。\n每条档案附带战术定位、四维评分与背景故事，档案分级 S / A / B 对应实战出场率。\n后续会开放档案收藏与对比功能。'
WHERE id = 4;

UPDATE home_feed SET
  source = '安全运营中心',
  importance = 2,
  body = '新增基于行为特征的检测模型，异常对局的判定速度提升至原来的 2.3 倍。\n误判率下降约 40%，被误判的对局会在 24 小时内自动撤销并补偿。\n举报通道同步升级，处理结果会以情报形式推送到本中心。'
WHERE id = 5;

UPDATE home_feed SET
  source = '训练设施',
  importance = 1,
  body = 'RANGE 新增移动靶与跳靶两种靶机类型，压枪与急停练习更贴近实战节奏。\n靶机难度分三档，第三档的移动速度接近真实对局中的横向拉枪。\n训练成绩不计入任何战绩统计，可以放心反复练习。'
WHERE id = 6;

UPDATE home_feed SET
  source = '运营活动',
  importance = 1,
  body = '本周五 18:00 至周日 24:00，全部模式经验加成 100%，可与战斗通行证叠加。\n限时行动同样参与加成，是补齐任务进度的好时机。\n加成期间的对局数据正常计入赛季统计。'
WHERE id = 7;

UPDATE home_feed SET
  source = '军械数据中心',
  importance = 1,
  body = '依据近 30 天实战数据重新校准了各枪械的火力与机动评分，评分口径统一为「每千次交火的收益」。\n狙击枪的机动评分下调，冲锋枪的近距离收益上调，整体的评分分布更贴近真实梯度。\n武器库页面展示的数值即为本次校准后的结果。'
WHERE id = 8;
