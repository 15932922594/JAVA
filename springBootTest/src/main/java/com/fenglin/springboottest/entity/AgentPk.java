package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/** PK 战绩（agent_pk）：一条记录 = 一次自动结算的对战 */
@TableName("agent_pk")
public class AgentPk {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long challengerId;
    private String challengerName;

    private Long defenderId;
    private String defenderName;

    /** 结算战力（含随机浮动后的实际值） */
    private Integer challengerPower;
    private Integer defenderPower;

    /** 胜者 id（理论上不会为空） */
    private Long winnerId;

    /** 结算描述 */
    private String detail;

    private LocalDateTime createTime;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getChallengerId() { return challengerId; }
    public void setChallengerId(Long challengerId) { this.challengerId = challengerId; }

    public String getChallengerName() { return challengerName; }
    public void setChallengerName(String challengerName) { this.challengerName = challengerName; }

    public Long getDefenderId() { return defenderId; }
    public void setDefenderId(Long defenderId) { this.defenderId = defenderId; }

    public String getDefenderName() { return defenderName; }
    public void setDefenderName(String defenderName) { this.defenderName = defenderName; }

    public Integer getChallengerPower() { return challengerPower; }
    public void setChallengerPower(Integer challengerPower) { this.challengerPower = challengerPower; }

    public Integer getDefenderPower() { return defenderPower; }
    public void setDefenderPower(Integer defenderPower) { this.defenderPower = defenderPower; }

    public Long getWinnerId() { return winnerId; }
    public void setWinnerId(Long winnerId) { this.winnerId = winnerId; }

    public String getDetail() { return detail; }
    public void setDetail(String detail) { this.detail = detail; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }
}
