package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.HomeFeed;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface HomeFeedMapper extends BaseMapper<HomeFeed> {
}
