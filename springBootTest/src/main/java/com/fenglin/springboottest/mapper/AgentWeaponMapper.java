package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.AgentWeapon;
import org.apache.ibatis.annotations.Mapper;

/** 特工已购武器 mapper */
@Mapper
public interface AgentWeaponMapper extends BaseMapper<AgentWeapon> {
}
