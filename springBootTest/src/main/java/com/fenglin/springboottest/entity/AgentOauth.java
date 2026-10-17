package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/**
 * 第三方账号绑定 / 授权票据（agent_oauth）
 * ticket 有值、user_id 为空 → 已授权未绑定；
 * user_id 有值 → 已绑定，可直接登录。
 */
@TableName("agent_oauth")
public class AgentOauth {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String provider;

    private String providerUid;

    private String riotId;

    private Long userId;

    private String ticket;

    private LocalDateTime ticketExpiresAt;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    public AgentOauth() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getProvider() {
        return provider;
    }

    public void setProvider(String provider) {
        this.provider = provider;
    }

    public String getProviderUid() {
        return providerUid;
    }

    public void setProviderUid(String providerUid) {
        this.providerUid = providerUid;
    }

    public String getRiotId() {
        return riotId;
    }

    public void setRiotId(String riotId) {
        this.riotId = riotId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getTicket() {
        return ticket;
    }

    public void setTicket(String ticket) {
        this.ticket = ticket;
    }

    public LocalDateTime getTicketExpiresAt() {
        return ticketExpiresAt;
    }

    public void setTicketExpiresAt(LocalDateTime ticketExpiresAt) {
        this.ticketExpiresAt = ticketExpiresAt;
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
