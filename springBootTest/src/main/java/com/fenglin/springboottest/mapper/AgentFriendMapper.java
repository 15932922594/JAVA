package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.AgentFriend;
import org.apache.ibatis.annotations.Mapper;

/** 好友关系 mapper */
@Mapper
public interface AgentFriendMapper extends BaseMapper<AgentFriend> {
}
