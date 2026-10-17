package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.ArchiveCategory;
import com.fenglin.springboottest.entity.FeedMark;
import com.fenglin.springboottest.entity.HomeFeed;
import com.fenglin.springboottest.mapper.ArchiveCategoryMapper;
import com.fenglin.springboottest.mapper.FeedMarkMapper;
import com.fenglin.springboottest.mapper.HomeFeedMapper;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 情报中心业务：列表 / 详情 / 已读 / 收藏 / 点赞 / 全部已读 / 统计
 *
 * 数据组成：
 *   home_feed（情报本体：标题、摘要、正文、来源、重要度、时间、热度）
 * + feed_mark（该特工的已读 / 收藏 / 点赞状态，一人一条情报一条记录）
 *
 * 已读语义：列表里没有 mark 记录即为未读；打开详情会自动标记已读。
 */
@Service
public class IntelService extends ServiceImpl<FeedMarkMapper, FeedMark> {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /** kind 编码 → 中文名 */
    private static final Map<String, String> KIND_NAMES = Map.of(
            "NEWS", "情报",
            "PATCH", "版本",
            "MISSION", "任务");

    /** 重要度 → 中文名 */
    private static final Map<Integer, String> IMPORTANCE_NAMES = Map.of(
            1, "常规",
            2, "重要",
            3, "紧急");

    private final HomeFeedMapper feedMapper;
    private final ArchiveCategoryMapper categoryMapper;

    public IntelService(HomeFeedMapper feedMapper, ArchiveCategoryMapper categoryMapper) {
        this.feedMapper = feedMapper;
        this.categoryMapper = categoryMapper;
    }

    /* ==========================================================
       1. 列表（分页 + 类型 / 状态 / 关键词 + 排序）
       ========================================================== */

    public Map<String, Object> list(Long userId, String kind, String status, String q,
                                    String sort, long page, long size) {
        long pageNo = Math.max(1, page);
        long pageSize = Math.min(Math.max(1, size), 30);

        QueryWrapper<HomeFeed> w = new QueryWrapper<HomeFeed>().eq("status", 1);
        String kindCode = kind == null ? "" : kind.trim().toUpperCase();
        if (!kindCode.isEmpty()) {
            w.eq("kind", kindCode);
        }

        String keyword = q == null ? "" : q.trim();
        if (!keyword.isEmpty()) {
            w.and(x -> x.like("title", keyword)
                    .or().like("summary", keyword)
                    .or().like("body", keyword)
                    .or().like("source", keyword)
                    .or().like("tag", keyword));
        }

        if ("heat".equalsIgnoreCase(sort)) {
            w.orderByDesc("heat").orderByDesc("published_at");
        } else {
            w.orderByDesc("published_at").orderByDesc("heat");
        }

        Map<Long, FeedMark> marks = marksMap(userId);
        Map<Long, Long> likeCounts = likeCounts();
        Map<String, String> catNames = categoryNames();

        String st = status == null ? "" : status.trim().toUpperCase();
        boolean needMarkFilter = "UNREAD".equals(st) || "READ".equals(st) || "STARRED".equals(st);

        List<HomeFeed> pageFeeds;
        long total;

        if (needMarkFilter) {
            // 已读/收藏状态依赖当前用户的 mark，必须先在全量结果上过滤再手动分页，
            // 否则只会在当前分页内部过滤，总数和条数都会算错。
            List<HomeFeed> kept = new ArrayList<>();
            for (HomeFeed f : feedMapper.selectList(w)) {
                FeedMark m = marks.get(f.getId());
                boolean read = m != null && Integer.valueOf(1).equals(m.getIsRead());
                boolean starred = m != null && Integer.valueOf(1).equals(m.getStarred());
                if ("UNREAD".equals(st) && read) {
                    continue;
                }
                if ("READ".equals(st) && !read) {
                    continue;
                }
                if ("STARRED".equals(st) && !starred) {
                    continue;
                }
                kept.add(f);
            }
            total = kept.size();
            int from = (int) Math.min((pageNo - 1) * pageSize, kept.size());
            int to = (int) Math.min(from + pageSize, kept.size());
            pageFeeds = kept.subList(from, to);
        } else {
            IPage<HomeFeed> p = feedMapper.selectPage(new Page<>(pageNo, pageSize), w);
            pageFeeds = p.getRecords();
            total = p.getTotal();
        }

        List<Map<String, Object>> rows = new ArrayList<>();
        for (HomeFeed f : pageFeeds) {
            rows.add(toRow(f, marks.get(f.getId()), likeCounts, catNames));
        }

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("stats", stats(userId));
        res.put("total", total);
        res.put("page", pageNo);
        res.put("size", pageSize);
        res.put("pages", pageSize == 0 ? 0 : (long) Math.ceil(total * 1.0 / pageSize));
        res.put("list", rows);
        return res;
    }

    /* ==========================================================
       2. 详情（打开即标记已读）
       ========================================================== */

    public Map<String, Object> detail(Long userId, Long id) {
        HomeFeed f = feedById(id);
        if (f == null) {
            return null;
        }
        // 打开详情 = 已读
        saveFlag(userId, id, "is_read", 1, true);
        Map<Long, FeedMark> marks = marksMap(userId);
        Map<String, Object> row = toRow(f, marks.get(id), likeCounts(), categoryNames());
        row.put("body", f.getBody() == null ? "" : f.getBody());
        return row;
    }

    /* ==========================================================
       3. 已读 / 收藏 / 点赞
       ========================================================== */

    /** 设置已读 / 未读 */
    public Map<String, Object> markRead(Long userId, Long id, boolean read) {
        HomeFeed f = feedById(id);
        if (f == null) {
            return null;
        }
        saveFlag(userId, id, "is_read", read ? 1 : 0, false);
        Map<String, Object> row = rowOf(userId, f);
        // 带上最新统计，前端行内操作后可以直接刷新未读数
        row.put("stats", stats(userId));
        return row;
    }

    /** 全部标记已读 */
    public Map<String, Object> markAllRead(Long userId) {
        List<HomeFeed> all = feedMapper.selectList(new QueryWrapper<HomeFeed>().eq("status", 1));
        Map<Long, FeedMark> marks = marksMap(userId);
        int changed = 0;
        for (HomeFeed f : all) {
            FeedMark m = marks.get(f.getId());
            if (m == null) {
                FeedMark nm = new FeedMark();
                nm.setUserId(userId);
                nm.setFeedId(f.getId());
                nm.setIsRead(1);
                nm.setStarred(0);
                nm.setLiked(0);
                save(nm);
                changed++;
            } else if (!Integer.valueOf(1).equals(m.getIsRead())) {
                m.setIsRead(1);
                updateById(m);
                changed++;
            }
        }
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("changed", changed);
        res.put("stats", stats(userId));
        return res;
    }

    /** 收藏 / 取消收藏 */
    public Map<String, Object> toggleStar(Long userId, Long id) {
        HomeFeed f = feedById(id);
        if (f == null) {
            return null;
        }
        FeedMark m = mark(userId, id);
        int next = Integer.valueOf(1).equals(m.getStarred()) ? 0 : 1;
        m.setStarred(next);
        if (Integer.valueOf(1).equals(next)) {
            m.setIsRead(1); // 收藏顺手标为已读
        }
        saveOrUpdate(userId, id, m);
        Map<String, Object> row = rowOf(userId, f);
        row.put("starred", next == 1);
        row.put("stats", stats(userId));
        return row;
    }

    /** 点赞 / 取消点赞：返回最新点赞总数 */
    public Map<String, Object> toggleLike(Long userId, Long id) {
        HomeFeed f = feedById(id);
        if (f == null) {
            return null;
        }
        FeedMark m = mark(userId, id);
        int next = Integer.valueOf(1).equals(m.getLiked()) ? 0 : 1;
        m.setLiked(next);
        saveOrUpdate(userId, id, m);
        long likes = likeCounts().getOrDefault(id, 0L);

        Map<String, Object> row = rowOf(userId, f);
        row.put("liked", next == 1);
        row.put("likes", likes);
        return row;
    }

    /* ==========================================================
       4. 统计
       ========================================================== */

    public Map<String, Object> stats(Long userId) {
        List<HomeFeed> all = feedMapper.selectList(new QueryWrapper<HomeFeed>().eq("status", 1));
        Map<Long, FeedMark> marks = marksMap(userId);

        int unread = 0;
        int read = 0;
        int starred = 0;
        int liked = 0;
        Map<String, Integer> byKind = new LinkedHashMap<>();
        for (String k : new String[]{"NEWS", "PATCH", "MISSION"}) {
            byKind.put(k, 0);
        }
        for (HomeFeed f : all) {
            FeedMark m = marks.get(f.getId());
            boolean r = m != null && Integer.valueOf(1).equals(m.getIsRead());
            if (r) {
                read++;
            } else {
                unread++;
            }
            if (m != null && Integer.valueOf(1).equals(m.getStarred())) {
                starred++;
            }
            if (m != null && Integer.valueOf(1).equals(m.getLiked())) {
                liked++;
            }
            byKind.merge(f.getKind(), 1, Integer::sum);
        }

        Map<String, Object> s = new LinkedHashMap<>();
        s.put("total", all.size());
        s.put("unread", unread);
        s.put("read", read);
        s.put("starred", starred);
        s.put("liked", liked);
        s.put("byKind", byKind);
        s.put("rate", all.isEmpty() ? 0 : Math.round(read * 100f / all.size()));
        return s;
    }

    /* ==========================================================
       内部工具
       ========================================================== */

    private Map<String, Object> rowOf(Long userId, HomeFeed f) {
        Map<Long, FeedMark> marks = marksMap(userId);
        return toRow(f, marks.get(f.getId()), likeCounts(), categoryNames());
    }

    private HomeFeed feedById(Long id) {
        if (id == null) {
            return null;
        }
        return feedMapper.selectOne(new QueryWrapper<HomeFeed>().eq("id", id).eq("status", 1));
    }

    private Map<Long, FeedMark> marksMap(Long userId) {
        if (userId == null) {
            return Collections.emptyMap();
        }
        return list(new QueryWrapper<FeedMark>().eq("user_id", userId)).stream()
                .collect(Collectors.toMap(FeedMark::getFeedId, Function.identity(), (x, y) -> x));
    }

    /** 每条情报的点赞总数（所有特工合计） */
    private Map<Long, Long> likeCounts() {
        return list(new QueryWrapper<FeedMark>().eq("liked", 1)).stream()
                .collect(Collectors.groupingBy(FeedMark::getFeedId, Collectors.counting()));
    }

    private Map<String, String> categoryNames() {
        return categoryMapper.selectList(new QueryWrapper<ArchiveCategory>().eq("status", 1)).stream()
                .collect(Collectors.toMap(ArchiveCategory::getCode, ArchiveCategory::getName, (x, y) -> x));
    }

    /** 取（或新建）一条 mark 记录；新建的记录尚未落库，由 saveOrUpdate 决定 */
    private FeedMark mark(Long userId, Long id) {
        Map<Long, FeedMark> marks = marksMap(userId);
        FeedMark m = marks.get(id);
        if (m != null) {
            return m;
        }
        FeedMark nm = new FeedMark();
        nm.setUserId(userId);
        nm.setFeedId(id);
        nm.setIsRead(0);
        nm.setStarred(0);
        nm.setLiked(0);
        return nm;
    }

    private void saveOrUpdate(Long userId, Long id, FeedMark m) {
        if (m.getId() == null) {
            m.setUserId(userId);
            m.setFeedId(id);
            save(m);
        } else {
            updateById(m);
        }
    }

    /**
     * 写入单个开关位。
     * @param keepZero true 时即便写入 0 也新建记录（用于保证「已读」有据可查）
     */
    private void saveFlag(Long userId, Long id, String flag, int value, boolean keepZero) {
        FeedMark m = mark(userId, id);
        boolean fresh = m.getId() == null;
        if ("is_read".equals(flag)) {
            m.setIsRead(value);
        } else if ("starred".equals(flag)) {
            m.setStarred(value);
        } else if ("liked".equals(flag)) {
            m.setLiked(value);
        }
        if (fresh && !keepZero && value == 0) {
            return; // 未读就是没有记录，不必落库
        }
        saveOrUpdate(userId, id, m);
    }

    /** 组装前端情报行 */
    private Map<String, Object> toRow(HomeFeed f, FeedMark m, Map<Long, Long> likeCounts,
                                      Map<String, String> catNames) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", f.getId());
        row.put("kind", f.getKind());
        row.put("kindName", KIND_NAMES.getOrDefault(f.getKind(), f.getKind()));
        row.put("title", f.getTitle());
        row.put("summary", f.getSummary());
        row.put("tag", f.getTag());
        row.put("source", f.getSource() == null ? "" : f.getSource());
        row.put("categoryCode", f.getCategoryCode() == null ? "" : f.getCategoryCode());
        row.put("categoryName", catNames.getOrDefault(f.getCategoryCode(), ""));
        row.put("importance", f.getImportance() == null ? 1 : f.getImportance());
        row.put("importanceName", IMPORTANCE_NAMES.getOrDefault(f.getImportance(), "常规"));
        row.put("heat", f.getHeat() == null ? 0 : f.getHeat());
        row.put("publishedAt", f.getPublishedAt() == null ? "" : f.getPublishedAt().format(FMT));
        row.put("read", m != null && Integer.valueOf(1).equals(m.getIsRead()));
        row.put("starred", m != null && Integer.valueOf(1).equals(m.getStarred()));
        row.put("liked", m != null && Integer.valueOf(1).equals(m.getLiked()));
        row.put("likes", likeCounts.getOrDefault(f.getId(), 0L).intValue());
        return row;
    }
}
