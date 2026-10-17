package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/**
 * 特工任务进度（mission_progress）
 * 一个特工对同一任务只有一条记录（uk_user_mission）。
 * status: 1 进行中 / 2 目标全部完成待结算 / 3 已结算
 */
@TableName("mission_progress")
public class MissionProgress {

    /** 进行中 */
    public static final int ACTIVE = 1;
    /** 目标全部完成，待结算 */
    public static final int READY = 2;
    /** 已结算 */
    public static final int CLAIMED = 3;

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long userId;

    private String missionCode;

    private Integer status;

    /** 已完成目标下标，JSON 数组，如 [0,2] */
    private String doneObjectives;

    private LocalDateTime startedAt;

    private LocalDateTime deadline;

    private LocalDateTime finishedAt;

    private LocalDateTime updateTime;

    public MissionProgress() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getMissionCode() {
        return missionCode;
    }

    public void setMissionCode(String missionCode) {
        this.missionCode = missionCode;
    }

    public Integer getStatus() {
        return status;
    }

    public void setStatus(Integer status) {
        this.status = status;
    }

    public String getDoneObjectives() {
        return doneObjectives;
    }

    public void setDoneObjectives(String doneObjectives) {
        this.doneObjectives = doneObjectives;
    }

    public LocalDateTime getStartedAt() {
        return startedAt;
    }

    public void setStartedAt(LocalDateTime startedAt) {
        this.startedAt = startedAt;
    }

    public LocalDateTime getDeadline() {
        return deadline;
    }

    public void setDeadline(LocalDateTime deadline) {
        this.deadline = deadline;
    }

    public LocalDateTime getFinishedAt() {
        return finishedAt;
    }

    public void setFinishedAt(LocalDateTime finishedAt) {
        this.finishedAt = finishedAt;
    }

    public LocalDateTime getUpdateTime() {
        return updateTime;
    }

    public void setUpdateTime(LocalDateTime updateTime) {
        this.updateTime = updateTime;
    }
}
