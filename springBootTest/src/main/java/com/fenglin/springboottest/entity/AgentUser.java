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

    /** 登录密码：明文存储（需求要求不加密） */
    private String password;

    /** 旧版密码摘要：SHA-256(salt::password)，仅用于兼容历史账号，新账号不再写入 */
    private String passwordHash;

    /** 旧版随机盐（16 字节 hex），同上 */
    private String salt;

    /**
     * 权限：1 = 默认权限（普通用户，看不到也进不去后台），0 = 管理员权限（可进后台）
     * 注册用户一律为 1，只有管理员权限（0）才允许登录后台管理系统。
     */
    private Integer permission;

    /** 注册时选择的特工下标（登录成功后前端据此切回该特工） */
    private Integer agentIndex;

    /** 英雄等级：注册后一律从 1 级开始 */
    private Integer heroLevel;

    /** 信用点余额：军械商店购买武器消耗，训练场对战赚取 */
    private Integer credits;

    /** 累计经验值：决定英雄等级（见 HeroLevel） */
    private Integer exp;

    /** 当前主武器 code（影响战力，必须已拥有且等级达标） */
    private String equippedWeapon;

    /**
     * 当前佩戴的头像框档位（边框图鉴里自选）。
     * 0 = 跟随最新解锁（默认，等级升到哪档就戴哪档）；
     * N = 手动佩戴第 N 档（必须 ≤ 当前等级可解锁的最高档）。
     */
    private Integer equippedFrame;

    /** PK 胜场 */
    private Integer pkWin;

    /** PK 负场 */
    private Integer pkLose;

    /** 最近一次登录日期：每日首次登录发经验用 */
    private java.time.LocalDate lastLoginDate;

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

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
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

    public Integer getPermission() {
        return permission;
    }

    public void setPermission(Integer permission) {
        this.permission = permission;
    }

    public Integer getAgentIndex() {
        return agentIndex;
    }

    public void setAgentIndex(Integer agentIndex) {
        this.agentIndex = agentIndex;
    }

    public Integer getHeroLevel() {
        return heroLevel;
    }

    public void setHeroLevel(Integer heroLevel) {
        this.heroLevel = heroLevel;
    }

    public Integer getCredits() {
        return credits;
    }

    public void setCredits(Integer credits) {
        this.credits = credits;
    }

    public Integer getExp() {
        return exp;
    }

    public void setExp(Integer exp) {
        this.exp = exp;
    }

    public String getEquippedWeapon() {
        return equippedWeapon;
    }

    public void setEquippedWeapon(String equippedWeapon) {
        this.equippedWeapon = equippedWeapon;
    }

    public Integer getEquippedFrame() {
        return equippedFrame;
    }

    public void setEquippedFrame(Integer equippedFrame) {
        this.equippedFrame = equippedFrame;
    }

    public Integer getPkWin() {
        return pkWin;
    }

    public void setPkWin(Integer pkWin) {
        this.pkWin = pkWin;
    }

    public Integer getPkLose() {
        return pkLose;
    }

    public void setPkLose(Integer pkLose) {
        this.pkLose = pkLose;
    }

    public java.time.LocalDate getLastLoginDate() {
        return lastLoginDate;
    }

    public void setLastLoginDate(java.time.LocalDate lastLoginDate) {
        this.lastLoginDate = lastLoginDate;
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
