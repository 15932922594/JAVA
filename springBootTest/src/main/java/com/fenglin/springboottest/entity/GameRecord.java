package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/**
 * RANGE 训练场成绩（game_record）
 * 每次训练一局一条记录；累计 units 用于自动完成作战任务目标。
 * mode: TARGET 靶场点击 / RECOIL 压枪练习 / REACTION 反应测试
 */
@TableName("game_record")
public class GameRecord {

    public static final String TARGET = "TARGET";
    public static final String RECOIL = "RECOIL";
    public static final String REACTION = "REACTION";

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private String mode;

    /** 本局得分 */
    private Integer score;

    /** 本局有效单位数（命中数 / 完成组数 / 达标次数） */
    private Integer units;

    /** 本局总射击次数 */
    private Integer shots;

    /** 本局命中次数 */
    private Integer hits;

    /** 本局平均反应毫秒数 */
    private Integer avgMs;

    private LocalDateTime createTime;

    public GameRecord() {
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getMode() { return mode; }
    public void setMode(String mode) { this.mode = mode; }

    public Integer getScore() { return score; }
    public void setScore(Integer score) { this.score = score; }

    public Integer getUnits() { return units; }
    public void setUnits(Integer units) { this.units = units; }

    public Integer getShots() { return shots; }
    public void setShots(Integer shots) { this.shots = shots; }

    public Integer getHits() { return hits; }
    public void setHits(Integer hits) { this.hits = hits; }

    public Integer getAvgMs() { return avgMs; }
    public void setAvgMs(Integer avgMs) { this.avgMs = avgMs; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }
}
