package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.AgentArchive;
import com.fenglin.springboottest.entity.ArchiveCategory;
import com.fenglin.springboottest.entity.HomeFeed;
import com.fenglin.springboottest.mapper.AgentArchiveMapper;
import com.fenglin.springboottest.mapper.ArchiveCategoryMapper;
import com.fenglin.springboottest.mapper.HomeFeedMapper;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 首页业务：分级分类目录 / 档案检索 / 首页概览 / 动态流
 * 数据来自 agent_archive、archive_category、home_feed 三张表。
 */
@Service
public class HomeService extends ServiceImpl<AgentArchiveMapper, AgentArchive> {

    /** 时间统一格式化，避免前端收到数组或时间戳 */
    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /** 分级档位，前端筛选器与统计都按这个顺序 */
    private static final String[] TIERS = {"S", "A", "B"};

    private final ArchiveCategoryMapper categoryMapper;
    private final HomeFeedMapper feedMapper;

    /** 分类编码 → 中文名的内存缓存（分类数据极少且基本不变，避免每条档案都回表） */
    private volatile Map<String, String> nameCache;

    public HomeService(ArchiveCategoryMapper categoryMapper, HomeFeedMapper feedMapper) {
        this.categoryMapper = categoryMapper;
        this.feedMapper = feedMapper;
    }

    /* ==========================================================
       1. 分级分类目录（两级树 + 每类档案数）
       ========================================================== */

    public List<Map<String, Object>> categories() {
        List<ArchiveCategory> all = categoryMapper.selectList(
                new QueryWrapper<ArchiveCategory>().eq("status", 1).orderByAsc("sort", "id"));

        // 统计每个二级分类下的档案数
        List<AgentArchive> archives = list(new QueryWrapper<AgentArchive>().eq("status", 1));
        Map<String, Long> subCount = archives.stream()
                .collect(Collectors.groupingBy(AgentArchive::getSubCode, Collectors.counting()));

        List<Map<String, Object>> roots = new ArrayList<>();
        for (ArchiveCategory c : all) {
            if (c.getLevel() != null && c.getLevel() == 2) {
                continue;
            }
            Map<String, Object> node = categoryNode(c);
            List<Map<String, Object>> children = new ArrayList<>();
            long total = 0;
            for (ArchiveCategory sub : all) {
                if (sub.getParentId() != null && sub.getParentId().equals(c.getId())) {
                    Map<String, Object> child = categoryNode(sub);
                    child.put("count", subCount.getOrDefault(sub.getCode(), 0L).intValue());
                    total += subCount.getOrDefault(sub.getCode(), 0L);
                    children.add(child);
                }
            }
            node.put("count", (int) total);
            node.put("children", children);
            roots.add(node);
        }
        return roots;
    }

    private Map<String, Object> categoryNode(ArchiveCategory c) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", c.getCode());
        m.put("name", c.getName());
        m.put("nameEn", c.getNameEn());
        m.put("level", c.getLevel());
        return m;
    }

    /* ==========================================================
       2. 分级分类检索
       关键词 + 一级分类 + 二级分类 + 分级(S/A/B) + 分页
       ========================================================== */

    public Map<String, Object> search(String q, String category, String sub, String tier,
                                      long page, long size) {
        long pageNo = Math.max(1, page);
        long pageSize = Math.min(Math.max(1, size), 60);

        QueryWrapper<AgentArchive> w = new QueryWrapper<AgentArchive>().eq("status", 1);

        String keyword = q == null ? "" : q.trim();
        if (!keyword.isEmpty()) {
            // 中文分类名也要能被搜到：先把命中的分类编码查出来
            List<String> hitCodes = categoryMapper.selectList(
                            new QueryWrapper<ArchiveCategory>()
                                    .like("name", keyword)
                                    .or().like("name_en", keyword)
                                    .or().like("code", keyword))
                    .stream().map(ArchiveCategory::getCode).distinct().collect(Collectors.toList());

            // 关键词整体必须包在一个 and(...) 里：
            // 否则 OR 分支会把后面的分类/分级条件短路（SQL 中 AND 优先级高于 OR）
            w.and(x -> {
                x.like("name", keyword)
                        .or().like("code", keyword)
                        .or().like("mono", keyword)
                        .or().like("bio", keyword);
                if (!hitCodes.isEmpty()) {
                    x.or().in("category_code", hitCodes)
                            .or().in("sub_code", hitCodes);
                }
            });
        }

        if (has(category)) {
            w.eq("category_code", category.trim());
        }
        if (has(sub)) {
            w.eq("sub_code", sub.trim());
        }
        if (has(tier)) {
            w.eq("tier", tier.trim().toUpperCase());
        }

        // 有关键词时按热度优先，否则按后台配置的排序
        if (!keyword.isEmpty()) {
            w.orderByDesc("heat").orderByAsc("sort");
        } else {
            w.orderByAsc("sort").orderByDesc("heat");
        }

        IPage<AgentArchive> p = page(new Page<>(pageNo, pageSize), w);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("total", p.getTotal());
        res.put("page", pageNo);
        res.put("size", pageSize);
        res.put("pages", p.getPages());
        res.put("keyword", keyword);
        res.put("category", category);
        res.put("subCategory", sub);
        res.put("tier", tier);
        List<Map<String, Object>> list = new ArrayList<>();
        for (AgentArchive a : p.getRecords()) {
            list.add(toArchiveMap(a));
        }
        res.put("list", list);
        return res;
    }

    /* ==========================================================
       2.5 档案详情（点击卡片展开：介绍 + 人物故事）
       ========================================================== */

    /**
     * 按档案代号取详情。
     * 相比检索列表多返回 story（人物故事，可能较长，检索列表不携带）。
     *
     * @param code 档案代号，如 vector
     * @return 详情结构；查不到返回 null
     */
    public Map<String, Object> detail(String code) {
        if (!has(code)) {
            return null;
        }
        AgentArchive a = getOne(new QueryWrapper<AgentArchive>()
                .eq("code", code.trim()).eq("status", 1), false);
        if (a == null) {
            return null;
        }
        Map<String, Object> m = toArchiveMap(a);
        m.put("story", a.getStory() == null ? "" : a.getStory());
        return m;
    }

    /* ==========================================================
       3. 首页概览
       ========================================================== */

    public Map<String, Object> overview() {
        List<AgentArchive> all = list(new QueryWrapper<AgentArchive>().eq("status", 1));
        Map<String, Long> tierCount = new LinkedHashMap<>();
        for (String t : TIERS) {
            tierCount.put(t, all.stream().filter(a -> t.equalsIgnoreCase(a.getTier())).count());
        }

        List<AgentArchive> featured = list(new QueryWrapper<AgentArchive>()
                .eq("status", 1).eq("featured", 1)
                .orderByAsc("sort").last("LIMIT 4"));

        List<HomeFeed> newest = feedMapper.selectList(new QueryWrapper<HomeFeed>()
                .eq("status", 1).orderByDesc("published_at").last("LIMIT 3"));

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("archiveTotal", all.size());
        res.put("categoryTotal", categoryMapper.selectCount(
                new QueryWrapper<ArchiveCategory>().eq("status", 1).eq("level", 1)));
        res.put("featuredTotal", all.stream().filter(a -> Integer.valueOf(1).equals(a.getFeatured())).count());
        res.put("feedTotal", feedMapper.selectCount(new QueryWrapper<HomeFeed>().eq("status", 1)));
        res.put("tierCount", tierCount);
        List<Map<String, Object>> fl = new ArrayList<>();
        for (AgentArchive a : featured) {
            fl.add(toArchiveMap(a));
        }
        res.put("featured", fl);
        List<Map<String, Object>> nl = new ArrayList<>();
        for (HomeFeed f : newest) {
            nl.add(toFeedMap(f));
        }
        res.put("newest", nl);
        return res;
    }

    /* ==========================================================
       4. 首页动态流（分页）
       ========================================================== */

    public Map<String, Object> feed(String kind, long page, long size) {
        long pageNo = Math.max(1, page);
        long pageSize = Math.min(Math.max(1, size), 50);

        QueryWrapper<HomeFeed> w = new QueryWrapper<HomeFeed>().eq("status", 1);
        if (has(kind)) {
            w.eq("kind", kind.trim().toUpperCase());
        }
        w.orderByDesc("published_at").orderByDesc("heat");

        IPage<HomeFeed> p = feedMapper.selectPage(new Page<>(pageNo, pageSize), w);

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("total", p.getTotal());
        res.put("page", pageNo);
        res.put("size", pageSize);
        res.put("pages", p.getPages());
        List<Map<String, Object>> list = new ArrayList<>();
        for (HomeFeed f : p.getRecords()) {
            list.add(toFeedMap(f));
        }
        res.put("list", list);
        return res;
    }

    /* ==========================================================
       数据转换（实体 → 前端结构）
       ========================================================== */

    /** 档案 → 前端卡片结构，role 保持 "中文 · ENGLISH" 以兼容前端 roleShort() */
    private Map<String, Object> toArchiveMap(AgentArchive a) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", a.getId());
        m.put("code", a.getCode());
        m.put("name", a.getName());
        m.put("mono", a.getMono());
        m.put("role", roleText(a));
        m.put("roleEn", a.getSubCode());
        m.put("category", a.getCategoryCode());
        m.put("categoryName", categoryName(a.getCategoryCode()));
        m.put("subCode", a.getSubCode());
        m.put("tier", a.getTier());
        m.put("color", a.getColor());
        m.put("bio", a.getBio());
        m.put("img", a.getImg());
        List<Integer> stats = new ArrayList<>();
        stats.add(nz(a.getFirepower()));
        stats.add(nz(a.getMobility()));
        stats.add(nz(a.getControl()));
        stats.add(nz(a.getDefense()));
        m.put("stats", stats);
        m.put("heat", nz(a.getHeat()));
        m.put("featured", nz(a.getFeatured()) == 1);
        return m;
    }

    private Map<String, Object> toFeedMap(HomeFeed f) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", f.getId());
        m.put("kind", f.getKind());
        m.put("title", f.getTitle());
        m.put("summary", f.getSummary());
        m.put("category", f.getCategoryCode());
        m.put("tag", f.getTag());
        m.put("heat", nz(f.getHeat()));
        m.put("publishedAt", f.getPublishedAt() == null ? "" : f.getPublishedAt().format(FMT));
        return m;
    }

    /** "突击 · ASSAULT"；查不到中文名则退回编码 */
    private String roleText(AgentArchive a) {
        String cn = categoryName(a.getSubCode());
        return cn + " · " + a.getSubCode();
    }

    /** 分类编码 → 中文名（查不到返回编码本身，前端不用再兜底） */
    private String categoryName(String code) {
        if (code == null || code.isEmpty()) {
            return "";
        }
        if (nameCache == null) {
            synchronized (this) {
                if (nameCache == null) {
                    nameCache = categoryMapper.selectList(new QueryWrapper<ArchiveCategory>())
                            .stream()
                            .collect(Collectors.toMap(ArchiveCategory::getCode, ArchiveCategory::getName, (a, b) -> a));
                }
            }
        }
        return nameCache.getOrDefault(code, code);
    }

    private static boolean has(String s) {
        return s != null && !s.trim().isEmpty();
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }
}
