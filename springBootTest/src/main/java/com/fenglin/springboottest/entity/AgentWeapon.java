package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/**
 * 特工已购武器（agent_weapon）
 * 一人一武器一条记录；标配（classic）免费，注册即拥有。
 */
@TableName("agent_weapon")
public class AgentWeapon {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 关联 agent_user.id */
    private Long userId;

    /** 特工代号（冗余存一份，便于直查表） */
    private String userName;

    /** 武器代号，见 WeaponCatalog */
    private String weaponCode;

    /** 武器中文名（冗余存一份，便于直查表） */
    private String weaponName;

    /** 购买时间 */
    private LocalDateTime createTime;

    public AgentWeapon() {
    }

    public AgentWeapon(Long userId, String userName, String weaponCode, String weaponName) {
        this.userId = userId;
        this.userName = userName;
        this.weaponCode = weaponCode;
        this.weaponName = weaponName;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getWeaponCode() { return weaponCode; }
    public void setWeaponCode(String weaponCode) { this.weaponCode = weaponCode; }

    public String getWeaponName() { return weaponName; }
    public void setWeaponName(String weaponName) { this.weaponName = weaponName; }

    public LocalDateTime getCreateTime() { return createTime; }
    public void setCreateTime(LocalDateTime createTime) { this.createTime = createTime; }
}
