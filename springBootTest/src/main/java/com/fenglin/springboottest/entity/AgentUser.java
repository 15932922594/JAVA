package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/**
 * 特工账号表 agent_user 对应实体
 */
@TableName("agent_user")
public class AgentUser {

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 特工代号（唯一） */
    private String name;

    /** 邮箱（唯一） */
    private String email;

    /** 密码摘要：SHA-256(salt::password)，绝不存明文 */
    private String passwordHash;

    /** 随机盐（16 字节 hex） */
    private String salt;

    /** 注册时选择的特工下标（登录成功后前端据此切回该特工） */
    private Integer agentIndex;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    public AgentUser() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getSalt() {
        return salt;
    }

    public void setSalt(String salt) {
        this.salt = salt;
    }

    public Integer getAgentIndex() {
        return agentIndex;
    }

    public void setAgentIndex(Integer agentIndex) {
        this.agentIndex = agentIndex;
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
