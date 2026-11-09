package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.common.WeaponCatalog;
import com.fenglin.springboottest.entity.WeaponCatalogItem;
import com.fenglin.springboottest.mapper.WeaponCatalogMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 武器目录服务（weapon_catalog 表的唯一读写入口）。
 *
 * 设计要点：
 *   1. 运行时以数据库为准：后台改售价 / 需求等级 / 战力 / 排序 / 上下架，前台立即生效；
 *   2. 库不可用（没建表、库没连上、表为空）时，自动退回
 *      {@code WeaponCatalog} 的代码内置目录，保证商店页永远不会 500；
 *   3. 首次访问时自动建表 + 灌入内置目录（CREATE TABLE IF NOT EXISTS + 仅空表时 seed），
 *      新环境不用手动跑 sql；也可以手动执行 sql/weapon_catalog.sql；
 *   4. 目录是只读快照，后台保存后调用 {@link #reload()} 失效缓存，下次访问重新读库。
 */
@Service
public class WeaponCatalogService {

    private static final Logger log = LoggerFactory.getLogger(WeaponCatalogService.class);

    /**
     * 表结构：新环境首次访问时自动创建，字段与库里已有表 / sql/weapon_catalog.sql 保持一致。
     * 下架标记列名是 on_sale（历史表结构就叫这个），接口对外仍然输出成 status。
     */
    private static final String DDL = """
            CREATE TABLE IF NOT EXISTS `weapon_catalog` (
              `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
              `code` varchar(32) NOT NULL COMMENT '武器代号：classic/sheriff/marshal/guardian/phantom/vandal/odin/operator',
              `name` varchar(32) NOT NULL DEFAULT '' COMMENT '武器中文名',
              `category` varchar(32) NOT NULL DEFAULT '步枪' COMMENT '类别：手枪/步枪/狙击枪/机枪',
              `price` int NOT NULL DEFAULT 0 COMMENT '售价（信用点，0 = 免费）',
              `req_level` int NOT NULL DEFAULT 1 COMMENT '购买所需英雄等级',
              `power` int NOT NULL DEFAULT 0 COMMENT '装备后战力加成',
              `sort` int NOT NULL DEFAULT 0 COMMENT '商店展示顺序（小的在前）',
              `on_sale` tinyint NOT NULL DEFAULT 1 COMMENT '1 上架 / 0 下架（下架后不可购买）',
              `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
              PRIMARY KEY (`id`) USING BTREE,
              UNIQUE KEY `uk_code` (`code`) USING BTREE
            ) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '军械商店武器目录（后台可编辑价格与等级门槛）'
            """;

    /** 灌内置目录：code 已存在则跳过，重复执行安全 */
    private static final String SEED = "INSERT IGNORE INTO `weapon_catalog` "
            + "(`code`, `name`, `category`, `price`, `req_level`, `power`, `sort`, `on_sale`) "
            + "VALUES (?, ?, ?, ?, ?, ?, ?, 1)";

    private final WeaponCatalogMapper mapper;
    private final JdbcTemplate jdbc;

    /** 目录快照（库优先，库不可用时为代码内置目录）；null 表示尚未加载 */
    private volatile List<Entry> snapshot;

    public WeaponCatalogService(WeaponCatalogMapper mapper, JdbcTemplate jdbc) {
        this.mapper = mapper;
        this.jdbc = jdbc;
    }

    /* ==========================================================
       查询
       ========================================================== */

    /** 完整目录（按商店排序），给后台统计 / 战力结算用 */
    public List<WeaponCatalog.Weapon> all() {
        List<Entry> rows = load();
        List<WeaponCatalog.Weapon> out = new ArrayList<>(rows.size());
        for (Entry e : rows) {
            out.add(e.weapon());
        }
        return out;
    }

    /** 按 code 查武器；不存在（含空值）返回 null */
    public WeaponCatalog.Weapon find(String code) {
        if (code == null || code.isBlank()) {
            return null;
        }
        String c = code.trim().toLowerCase();
        for (Entry e : load()) {
            if (e.weapon().code.equals(c)) {
                return e.weapon();
            }
        }
        return null;
    }

    /**
     * 前台「军械商店」的武器列表。
     *
     * 字段名与 ArmoryPage.vue 对齐：code / name / category / price / reqLevel / power / status。
     * 返回的是可变 Map，调用方（ArmoryService）会往里补 owned / equipped 标记。
     */
    public List<Map<String, Object>> shopList() {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Entry e : load()) {
            WeaponCatalog.Weapon w = e.weapon();
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("code", w.code);
            m.put("name", w.name);
            m.put("category", w.category);
            m.put("price", w.price);
            m.put("reqLevel", w.level);
            m.put("power", w.power);
            m.put("status", w.status);
            out.add(m);
        }
        return out;
    }

    /**
     * 后台「军械」页的目录明细（含 id / sort，编辑弹窗回填用）。
     *
     * 字段名与 AdminDashboard.vue 对齐：id / code / name / category / price / req_level / power / sort / status。
     */
    public List<Map<String, Object>> listAll() {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Entry e : load()) {
            WeaponCatalog.Weapon w = e.weapon();
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", e.id());
            m.put("code", w.code);
            m.put("name", w.name);
            m.put("category", w.category);
            m.put("price", w.price);
            m.put("req_level", w.level);
            m.put("power", w.power);
            m.put("sort", e.sort());
            m.put("status", w.status);
            out.add(m);
        }
        return out;
    }

    /* ==========================================================
       后台修改
       ========================================================== */

    /**
     * 保存武器配置（id 有值按 id 改，否则按 code 改/新增；null 字段表示不修改）。
     *
     * @return "ok"，或错误码 notfound / invalid-code / invalid-price / invalid-level / db-error
     */
    public String save(Long id, String code, String name, String category,
                       Integer price, Integer reqLevel, Integer power, Integer sort, Integer status) {
        if (price != null && price < 0) {
            return "invalid-price";
        }
        if (reqLevel != null && reqLevel < 1) {
            return "invalid-level";
        }

        String weaponCode = code == null ? "" : code.trim().toLowerCase();
        if (weaponCode.isEmpty()) {
            return "invalid-code";
        }

        try {
            WeaponCatalogItem row = null;
            if (id != null) {
                row = mapper.selectById(id);
            }
            if (row == null) {
                row = mapper.selectOne(new QueryWrapper<WeaponCatalogItem>().eq("code", weaponCode));
            }

            // 目录里没有这把枪 → 新增（code 必须合法：小写字母/数字/连字符，最长 32）
            if (row == null) {
                if (!VALID_CODE.matcher(weaponCode).matches()) {
                    return "invalid-code";
                }
                WeaponCatalogItem created = new WeaponCatalogItem(
                        weaponCode,
                        blankTo(name, weaponCode),
                        blankTo(category, "步枪"),
                        price == null ? 0 : price,
                        reqLevel == null ? 1 : reqLevel,
                        power == null ? 0 : power,
                        sort == null ? nextSort() : sort,
                        status == null ? 1 : (status == 0 ? 0 : 1));
                mapper.insert(created);
                reload();
                return "ok";
            }

            if (!weaponCode.equals(row.getCode())) {
                // code 是唯一键，改名会打断已购记录/前端外观匹配，这里只允许同值提交
                return "invalid-code";
            }
            if (name != null && !name.isBlank()) {
                row.setName(name.trim());
            }
            if (category != null && !category.isBlank()) {
                row.setCategory(category.trim());
            }
            if (price != null) {
                row.setPrice(price);
            }
            if (reqLevel != null) {
                row.setReqLevel(reqLevel);
            }
            if (power != null) {
                row.setPower(power);
            }
            if (sort != null) {
                row.setSort(sort);
            }
            if (status != null) {
                row.setOnSale(status == 0 ? 0 : 1);
            }
            mapper.updateById(row);
            reload();
            return "ok";
        } catch (Exception e) {
            log.warn("武器目录保存失败：{}", e.getMessage());
            return "db-error";
        }
    }

    /** 使当前快照失效，下次访问重新读库（后台保存后自动调用） */
    public void reload() {
        snapshot = null;
    }

    /* ==========================================================
       内部：加载 / 兜底
       ========================================================== */

    /** 目录一行：id 来自数据库（内置兜底时为 null），sort 用于商店排序 */
    private record Entry(Long id, WeaponCatalog.Weapon weapon, int sort) {
    }

    private static final java.util.regex.Pattern VALID_CODE =
            java.util.regex.Pattern.compile("^[a-z0-9][a-z0-9_-]{0,31}$");

    private List<Entry> load() {
        List<Entry> rows = snapshot;
        if (rows != null) {
            return rows;
        }
        synchronized (this) {
            if (snapshot == null) {
                snapshot = read();
            }
            return snapshot;
        }
    }

    private List<Entry> read() {
        try {
            ensureTable();
            List<WeaponCatalogItem> rows = mapper.selectList(new QueryWrapper<WeaponCatalogItem>()
                    .orderByAsc("sort").orderByAsc("price").orderByAsc("id"));
            List<Entry> out = new ArrayList<>();
            if (rows != null) {
                for (WeaponCatalogItem r : rows) {
                    if (r.getCode() == null || r.getCode().isBlank()) {
                        continue;
                    }
                    out.add(toEntry(r));
                }
            }
            if (!out.isEmpty()) {
                return out;
            }
            log.warn("weapon_catalog 表为空，暂时使用代码内置目录");
        } catch (Exception e) {
            log.warn("weapon_catalog 读取失败（{}），暂时使用代码内置目录", e.getMessage());
        }
        return fallback();
    }

    private static Entry toEntry(WeaponCatalogItem r) {
        WeaponCatalog.Weapon w = new WeaponCatalog.Weapon(
                r.getCode().trim().toLowerCase(),
                r.getName() == null || r.getName().isBlank() ? r.getCode() : r.getName(),
                r.getCategory() == null ? "" : r.getCategory(),
                r.getPrice() == null ? 0 : r.getPrice(),
                r.getReqLevel() == null ? 1 : r.getReqLevel(),
                r.getPower() == null ? 0 : r.getPower(),
                r.getOnSale() == null ? 1 : r.getOnSale());
        return new Entry(r.getId(), w, r.getSort() == null ? 0 : r.getSort());
    }

    /** 代码内置目录（WeaponCatalog.ALL）→ Entry 列表，顺序即展示顺序 */
    private static List<Entry> fallback() {
        List<WeaponCatalog.Weapon> def = WeaponCatalog.all();
        List<Entry> out = new ArrayList<>(def.size());
        for (int i = 0; i < def.size(); i++) {
            out.add(new Entry(null, def.get(i), (i + 1) * 10));
        }
        return out;
    }

    /**
     * 保证表存在且不为空：
     *   - 建表失败（没权限 / 库没起）只记日志，不影响商店页走内置目录；
     *   - 表为空才灌内置目录，已有数据绝不覆盖。
     */
    private void ensureTable() {
        try {
            jdbc.execute(DDL);
            Integer n = jdbc.queryForObject("SELECT COUNT(*) FROM `weapon_catalog`", Integer.class);
            if (n == null || n == 0) {
                List<WeaponCatalog.Weapon> def = WeaponCatalog.all();
                for (int i = 0; i < def.size(); i++) {
                    WeaponCatalog.Weapon w = def.get(i);
                    jdbc.update(SEED, w.code, w.name, w.category, w.price, w.level, w.power, (i + 1) * 10);
                }
                log.info("weapon_catalog 已初始化 {} 把武器（来自代码内置目录）", def.size());
            }
        } catch (Exception e) {
            log.warn("初始化 weapon_catalog 失败（{}），本次使用代码内置目录", e.getMessage());
        }
    }

    /** 新增武器时没给排序：排在现有最大值之后 */
    private int nextSort() {
        int max = 0;
        for (Entry e : load()) {
            max = Math.max(max, e.sort());
        }
        return max + 10;
    }

    private static String blankTo(String s, String def) {
        return s == null || s.isBlank() ? def : s.trim();
    }
}
