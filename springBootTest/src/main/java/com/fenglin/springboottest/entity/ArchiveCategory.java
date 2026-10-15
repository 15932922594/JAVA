package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import java.time.LocalDateTime;

/**
 * 档案分级分类目录实体（archive_category）
 * level=1 一级分类（特工档案 / 装备库 / 作战任务）
 * level=2 二级分类（突击 / 控场 … 步枪 / 冲锋枪 … 训练场 …）
 */
@TableName("archive_category")
public class ArchiveCategory {

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 父分类 id，0 表示一级分类 */
    private Long parentId;

    /** 分类编码，如 AGENT / ASSAULT */
    private String code;

    /** 分类中文名 */
    private String name;

    /** 分类英文名 */
    private String nameEn;

    /** 层级：1 一级，2 二级 */
    private Integer level;

    private Integer sort;

    private Integer status;

    private LocalDateTime createTime;

    public ArchiveCategory() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getParentId() {
        return parentId;
    }

    public void setParentId(Long parentId) {
        this.parentId = parentId;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getNameEn() {
        return nameEn;
    }

    public void setNameEn(String nameEn) {
        this.nameEn = nameEn;
    }

    public Integer getLevel() {
        return level;
    }

    public void setLevel(Integer level) {
        this.level = level;
    }

    public Integer getSort() {
        return sort;
    }

    public void setSort(Integer sort) {
        this.sort = sort;
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
}
