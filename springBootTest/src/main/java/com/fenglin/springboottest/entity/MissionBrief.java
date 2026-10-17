package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/**
 * 作战任务简报（mission_brief）
 * 任务本体（名称 / 分类 / 分级 / 背景故事）存在 agent_archive，
 * 这里只补充「可交互」需要的字段：简报、目标清单、奖励、时限、区域。
 * missionCode 与 agent_archive.code 一一对应。
 */
@TableName("mission_brief")
public class MissionBrief {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 任务代号，关联 agent_archive.code */
    private String missionCode;

    /** 任务简报 */
    private String briefing;

    /** 目标清单，JSON 字符串数组，如 ["占领 A 点","完成 3 次击杀"] */
    private String objectives;

    /** 结算积分 */
    private Integer reward;

    /** 任务时限（分钟） */
    private Integer durationMin;

    /** 作战区域 */
    private String region;

    /** 编队规模 */
    private String squad;

    /** 1 上线 / 0 下线 */
    private Integer status;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    public MissionBrief() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getMissionCode() {
        return missionCode;
    }

    public void setMissionCode(String missionCode) {
        this.missionCode = missionCode;
    }

    public String getBriefing() {
        return briefing;
    }

    public void setBriefing(String briefing) {
        this.briefing = briefing;
    }

    public String getObjectives() {
        return objectives;
    }

    public void setObjectives(String objectives) {
        this.objectives = objectives;
    }

    public Integer getReward() {
        return reward;
    }

    public void setReward(Integer reward) {
        this.reward = reward;
    }

    public Integer getDurationMin() {
        return durationMin;
    }

    public void setDurationMin(Integer durationMin) {
        this.durationMin = durationMin;
    }

    public String getRegion() {
        return region;
    }

    public void setRegion(String region) {
        this.region = region;
    }

    public String getSquad() {
        return squad;
    }

    public void setSquad(String squad) {
        this.squad = squad;
    }

    public Integer getStatus() {
        return status;
    }

    public void setStatus(Integer status) {
        this.status = status;
    }

    public LocalDateTime getCreateTime() {
        return createTime;
    }

    public void setCreateTime(LocalDateTime createTime) {
        this.createTime = createTime;
    }

    public LocalDateTime getUpdateTime() {
        return updateTime;
    }

    public void setUpdateTime(LocalDateTime updateTime) {
        this.updateTime = updateTime;
    }
}
