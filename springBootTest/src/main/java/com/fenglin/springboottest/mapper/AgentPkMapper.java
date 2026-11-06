package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.AgentPk;
import org.apache.ibatis.annotations.Mapper;

/** PK 战绩 mapper */
@Mapper
public interface AgentPkMapper extends BaseMapper<AgentPk> {
}
