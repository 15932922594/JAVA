package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.WeaponCatalogItem;
import org.apache.ibatis.annotations.Mapper;

/** 武器目录 mapper（weapon_catalog） */
@Mapper
public interface WeaponCatalogMapper extends BaseMapper<WeaponCatalogItem> {
}
