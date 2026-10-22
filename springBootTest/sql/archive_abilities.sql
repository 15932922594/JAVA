-- ===========================================================
-- 档案可读化升级：中文名 + 能力/特性说明
-- 执行方式:
--   mysql -uroot -p123456 --default-character-set=utf8mb4 -D agent_access < sql/archive_abilities.sql
--
-- 说明：
--   name_cn   中文名，卡与详情里和英文代号并列展示，便于一眼看懂
--   abilities JSON 数组，每项 { slot, name, desc }
--               slot 是标签（Q/E/X 或 特性），desc 用大白话讲「这招干嘛用」
-- ===========================================================

ALTER TABLE agent_archive
  ADD COLUMN name_cn VARCHAR(64) NOT NULL DEFAULT '' COMMENT '中文名' AFTER name;

ALTER TABLE agent_archive
  ADD COLUMN abilities TEXT NULL COMMENT '能力/特性 JSON 数组 [{slot,name,desc}]' AFTER story;

-- ===========================================================
-- 特工档案
-- ===========================================================

UPDATE agent_archive SET
  name_cn = '矢量',
  abilities = '[
    {"slot":"Q","name":"相位突进","desc":"向准星方向瞬间位移一小段，用来抢点、拉枪线或脱离交叉火力。"},
    {"slot":"E","name":"破障射线","desc":"放出一道穿透射线，短暂削弱命中敌人的护甲，正面硬刚更占便宜。"},
    {"slot":"X","name":"矢量过载","desc":"短时疾行且移动射击精度不下降，适合一口气撕开一道防线。"}
  ]'
WHERE code = 'vector';

UPDATE agent_archive SET
  name_cn = '弧光',
  abilities = '[
    {"slot":"Q","name":"电弧脉冲","desc":"向身前扇区释放脉冲，被命中的敌人轮廓会被标记，隔着墙也能看见。"},
    {"slot":"E","name":"全域扫描","desc":"一次性点亮附近区域的敌人位置，持续时间短，进点前摸站位最好用。"},
    {"slot":"X","name":"电网陷阱","desc":"布下电网，敌人经过会被减速并暴露位置，兼顾封锁与预警。"}
  ]'
WHERE code = 'arclight';

UPDATE agent_archive SET
  name_cn = '幻影',
  abilities = '[
    {"slot":"Q","name":"幻影分身","desc":"生成一个向前走的分身诱饵，用来骗第一枪、确认敌人架在哪。"},
    {"slot":"E","name":"遮断烟幕","desc":"在指定位置落下烟幕切断视野，进点、拆包、撤退都靠它。"},
    {"slot":"X","name":"错觉领域","desc":"大范围幻象区，敌人视野受阻且分不清真假身，能强行改写交火节奏。"}
  ]'
WHERE code = 'phantom';

UPDATE agent_archive SET
  name_cn = '玄岩',
  abilities = '[
    {"slot":"Q","name":"岩壁屏障","desc":"竖起一道可再生的墙体，封住通路或专门挡对面狙击的枪线。"},
    {"slot":"E","name":"哨位陷阱","desc":"布置自动预警装置，敌人靠近就减速并暴露位置。"},
    {"slot":"X","name":"壁垒成型","desc":"短时间展开加固防线，站在后面的队友受到的伤害明显减少。"}
  ]'
WHERE code = 'onyx';

UPDATE agent_archive SET
  name_cn = '风暴',
  abilities = '[
    {"slot":"Q","name":"强风幕墙","desc":"生成一堵风墙，敌人穿行时视野受损、移速下降。"},
    {"slot":"E","name":"乱流推挤","desc":"用气流把敌人推向一侧，强行打乱他站位，为队友拉出击杀窗口。"},
    {"slot":"X","name":"风暴中心","desc":"在一片区域降下持续风暴，长时间封锁通路，拖延或守点时极强。"}
  ]'
WHERE code = 'tempest';

UPDATE agent_archive SET
  name_cn = '余烬',
  abilities = '[
    {"slot":"Q","name":"燃焰喷发","desc":"近距离喷射火焰，专门清理两个人就得挤过去的窄通道。"},
    {"slot":"E","name":"火墙封路","desc":"在地面拉出一段火墙，穿过的敌人持续掉血，逼他们改路线。"},
    {"slot":"X","name":"燃尽冲刺","desc":"自身短暂燃烧，移速和换弹大幅加快，代价是血量持续下降。"}
  ]'
WHERE code = 'ember';

-- ===========================================================
-- 装备库 · 枪械
-- 特性统一用「优势 / 优势 / 代价」三段式，方便横向对比
-- ===========================================================

UPDATE agent_archive SET
  name_cn = '劫掠者',
  abilities = '[
    {"slot":"优势","name":"任意距离一枪爆头","desc":"不管多远，打中头就是秒杀，远距离对枪的标杆。"},
    {"slot":"优势","name":"伤害不衰减","desc":"远距离伤害没有距离惩罚，架点可以完全不考虑站位深度。"},
    {"slot":"代价","name":"后坐大","desc":"连射很飘，要点射、要压枪，不适合闭着眼泼。"}
  ]'
WHERE code = 'vandal';

UPDATE agent_archive SET
  name_cn = '幽影-W',
  abilities = '[
    {"slot":"优势","name":"消音","desc":"开枪不会暴露自己的位置提示，隔着烟打人对方很难反查。"},
    {"slot":"优势","name":"后坐可控","desc":"连发比劫掠者柔和得多，中距离压枪一串很稳。"},
    {"slot":"代价","name":"远距离衰减","desc":"超过中远距离伤害明显下降，远点不如劫掠者。"}
  ]'
WHERE code = 'phantom-w';

UPDATE agent_archive SET
  name_cn = '奥丁',
  abilities = '[
    {"slot":"优势","name":"弹链压制","desc":"超大弹容持续输出，一个人就能压死一条通道。"},
    {"slot":"优势","name":"穿墙射击","desc":"子弹能打穿墙体，可以直接透过掩体验证甚至击杀。"},
    {"slot":"代价","name":"又重又慢","desc":"移速慢、开镜慢，架点无敌但被人绕后基本没救。"}
  ]'
WHERE code = 'odin';

UPDATE agent_archive SET
  name_cn = '制式手枪',
  abilities = '[
    {"slot":"优势","name":"开局自带","desc":"每回合白给，经济落后时最稳的兜底武器。"},
    {"slot":"优势","name":"右键三连","desc":"贴脸三连发爆发很高，近距离容错极低。"},
    {"slot":"代价","name":"远距离无力","desc":"超过中距离伤害骤降，别指望用它架远点。"}
  ]'
WHERE code = 'classic';

UPDATE agent_archive SET
  name_cn = '治安官',
  abilities = '[
    {"slot":"优势","name":"躯干一枪","desc":"打身子也是一枪致命，不用非得爆头。"},
    {"slot":"优势","name":"便宜高回报","desc":"价格低但威力接近步枪，翻盘局最常见的选择。"},
    {"slot":"代价","name":"弹少且慢","desc":"弹匣小、开火间隔长，空一枪就是致命失误。"}
  ]'
WHERE code = 'sheriff';

UPDATE agent_archive SET
  name_cn = '恶灵',
  abilities = '[
    {"slot":"优势","name":"高射速泼洒","desc":"近距离短时间叠出成吨伤害，贴上脸几乎必胜。"},
    {"slot":"优势","name":"跑打稳定","desc":"移动射击散布小，边走边输出也不至于全飘。"},
    {"slot":"代价","name":"距离衰减","desc":"稍微远一点伤害就掉，中远距离基本打不动。"}
  ]'
WHERE code = 'spectre';

UPDATE agent_archive SET
  name_cn = '战神',
  abilities = '[
    {"slot":"优势","name":"一枪必杀","desc":"打中躯干直接终结，哪怕打腿也是重伤。"},
    {"slot":"优势","name":"封锁通路","desc":"一个人架枪就能封死整条主路，对面必须花道具强行开。"},
    {"slot":"代价","name":"贵且笨重","desc":"价格高、移速慢、开镜慢，一旦掉枪代价巨大。"}
  ]'
WHERE code = 'operator';

UPDATE agent_archive SET
  name_cn = '元帅',
  abilities = '[
    {"slot":"优势","name":"轻便好上手","desc":"比战神便宜也轻得多，转移和补点灵活得多。"},
    {"slot":"优势","name":"躯干终结","desc":"胸腹以上一枪致命，中距离一枪一个。"},
    {"slot":"代价","name":"容错低","desc":"打腿杀不掉，开镜后不能连发，节奏慢。"}
  ]'
WHERE code = 'marshal';
