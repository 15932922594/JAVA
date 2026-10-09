package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.AgentUser;
import org.apache.ibatis.annotations.Mapper;

/**
 * MyBatis-Plus BaseMapper 已内置 insert / selectOne / selectList 等方法，
 * 简单 CRUD 无需写 XML。
 */
@Mapper
public interface AgentUserMapper extends BaseMapper<AgentUser> {
}
