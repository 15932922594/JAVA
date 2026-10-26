package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/**
 * 后台操作日志实体（admin_log）
 * 记录管理员的关键操作：登录 / 改密 / 档案、分类、动态、任务的增删改。
 */
@TableName("admin_log")
public class AdminLog {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 操作人 id */
    private Long adminId;

    /** 操作人账号（冗余，便于展示） */
    private String adminName;

    /** 对象：archive / category / feed / mission / admin */
    private String target;

    /** 动作：CREATE / UPDATE / DELETE / LOGIN / PASSWORD */
    private String action;

    /** 摘要说明 */
    private String detail;

    private LocalDateTime createTime;

    public AdminLog() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getAdminId() {
        return adminId;
    }

    public void setAdminId(Long adminId) {
        this.adminId = adminId;
    }

    public String getAdminName() {
        return adminName;
    }

    public void setAdminName(String adminName) {
        this.adminName = adminName;
    }

    public String getTarget() {
        return target;
    }

    public void setTarget(String target) {
        this.target = target;
    }

    public String getAction() {
        return action;
    }

    public void setAction(String action) {
        this.action = action;
    }

    public String getDetail() {
        return detail;
    }

    public void setDetail(String detail) {
        this.detail = detail;
    }

    public LocalDateTime getCreateTime() {
        return createTime;
    }

    public void setCreateTime(LocalDateTime createTime) {
        this.createTime = createTime;
    }
}
