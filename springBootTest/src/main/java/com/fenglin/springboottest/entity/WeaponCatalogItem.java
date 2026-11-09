package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/**
 * 军械商店武器目录（weapon_catalog）
 *
 * 一行一个武器：售价 / 需求等级 / 战力加成 / 排序 / 上下架都可在后台改，
 * 前台「军械商店」与战力结算都读这张表；表为空时代码会用
 * {@link com.fenglin.springboottest.common.WeaponCatalog} 的内置目录自动灌入。
 *
 * 注意：库里下架字段叫 on_sale（不是 status），接口对外仍以 status 输出，避免前端改动。
 */
@TableName("weapon_catalog")
public class WeaponCatalogItem {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 武器代号（唯一），如 classic / vandal */
    private String code;

    /** 中文名，如 狂徒 */
    private String name;

    /** 枪种：手枪 / 步枪 / 狙击枪 / 机枪 */
    private String category;

    /** 售价（信用点，0 = 免费） */
    private Integer price;

    /** 购买所需英雄等级 */
    private Integer reqLevel;

    /** 装备后的战力加成 */
    private Integer power;

    /** 商店排序（小的在前） */
    private Integer sort;

    /** 1 上架 / 0 下架（下架后不可购买，但外观与战力数据保留）；对应列 on_sale */
    private Integer onSale;

    /** 最后修改时间 */
    private LocalDateTime updateTime;

    public WeaponCatalogItem() {
    }

    public WeaponCatalogItem(String code, String name, String category,
                             Integer price, Integer reqLevel, Integer power, Integer sort, Integer onSale) {
        this.code = code;
        this.name = name;
        this.category = category;
        this.price = price;
        this.reqLevel = reqLevel;
        this.power = power;
        this.sort = sort;
        this.onSale = onSale;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public Integer getPrice() { return price; }
    public void setPrice(Integer price) { this.price = price; }

    public Integer getReqLevel() { return reqLevel; }
    public void setReqLevel(Integer reqLevel) { this.reqLevel = reqLevel; }

    public Integer getPower() { return power; }
    public void setPower(Integer power) { this.power = power; }

    public Integer getSort() { return sort; }
    public void setSort(Integer sort) { this.sort = sort; }

    public Integer getOnSale() { return onSale; }
    public void setOnSale(Integer onSale) { this.onSale = onSale; }

    public LocalDateTime getUpdateTime() { return updateTime; }
    public void setUpdateTime(LocalDateTime updateTime) { this.updateTime = updateTime; }
}
